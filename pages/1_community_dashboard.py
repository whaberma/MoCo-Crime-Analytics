import altair as alt
import pandas as pd
import pydeck as pdk
import requests
import streamlit as st
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_FOLDER = PROJECT_ROOT / "dashboard_data"


ZIP_GEOJSON_URL = (
    "https://raw.githubusercontent.com/OpenDataDE/"
    "State-zip-code-GeoJSON/master/md_maryland_zip_codes_geo.min.json"
)


@st.cache_data
def load_data():
    return {
        "city_summary": pd.read_csv(
            DATA_FOLDER / "community_city_summary.csv"
        ),
        "city_trend": pd.read_csv(
            DATA_FOLDER / "community_city_trend.csv"
        ),
        "crime_mix": pd.read_csv(
            DATA_FOLDER / "community_crime_mix.csv"
        ),
        "time_heatmap": pd.read_csv(
            DATA_FOLDER / "community_time_heatmap.csv"
        ),
        "zip_detail": pd.read_csv(
            DATA_FOLDER / "community_zip_detail.csv",
            dtype={"Zip Code": "string"},
        ),
    }


@st.cache_data(ttl=86400)
def load_zip_geojson() -> dict:
    response = requests.get(ZIP_GEOJSON_URL, timeout=20)
    response.raise_for_status()
    geojson = response.json()

    possible_zip_keys = [
        "ZCTA5CE10",
        "ZCTA5CE20",
        "ZIPCODE",
        "ZIP_CODE",
        "ZIP",
        "zip",
        "zipcode",
        "postalCode",
        "name",
    ]

    cleaned_features = []

    for feature in geojson.get("features", []):
        properties = feature.get("properties", {})
        zip_value = None

        for key in possible_zip_keys:
            if key in properties and properties[key] is not None:
                zip_value = properties[key]
                break

        if zip_value is None:
            continue

        properties["zip_code"] = (
            str(zip_value)
            .replace(".0", "")
            .strip()
            .zfill(5)
        )

        feature["properties"] = properties
        cleaned_features.append(feature)

    geojson["features"] = cleaned_features
    return geojson


try:
    data = load_data()
except Exception as exc:
    st.error("Could not load the exported community dashboard CSV files.")
    st.code(str(exc))
    st.stop()


city_summary = data["city_summary"]
city_trend = data["city_trend"]
crime_mix = data["crime_mix"]
time_heatmap = data["time_heatmap"]
zip_detail = data["zip_detail"]


if "city" in crime_mix.columns:
    crime_mix = crime_mix.rename(
        columns={"city": "City", "state": "State"}
    )

for dataframe in [
    city_summary,
    city_trend,
    crime_mix,
    time_heatmap,
    zip_detail,
]:
    if "City" in dataframe.columns:
        dataframe["City"] = (
            dataframe["City"]
            .astype("string")
            .str.strip()
            .str.upper()
        )

    if "State" in dataframe.columns:
        dataframe["State"] = (
            dataframe["State"]
            .astype("string")
            .str.strip()
            .str.upper()
        )

if "Zip Code" in zip_detail.columns:
    zip_detail["Zip Code"] = (
        zip_detail["Zip Code"]
        .astype("string")
        .str.replace(".0", "", regex=False)
        .str.strip()
        .str.zfill(5)
    )


st.sidebar.title("Community Filters")

city_options = sorted(
    city_summary["City"].dropna().unique().tolist()
)

if not city_options:
    st.error(
        "No cities were returned from community_city_summary. "
        "Check the SQL view and Streamlit cache."
    )
    st.stop()

selected_city = st.sidebar.selectbox(
    "Select a city",
    city_options,
)

top_n = st.sidebar.slider(
    "Top cities to compare",
    min_value=5,
    max_value=25,
    value=10,
)

top_n_secondary = st.sidebar.slider(
    "Top secondary crime categories",
    min_value=5,
    max_value=25,
    value=12,
)

map_scope = st.sidebar.radio(
    "Map scope",
    [
        "All Montgomery County ZIPs",
        "Selected city ZIPs",
    ],
)

if st.sidebar.button("Clear cache"):
    st.cache_data.clear()
    st.cache_resource.clear()
    st.rerun()


st.title("Montgomery County Community Crime Dashboard")
st.markdown(
    "A resident-focused dashboard for comparing ZIP-level crime "
    "concentration, viewing city trends, understanding offense types, "
    "and drilling into areas within a selected city."
)


selected_city_summary = city_summary[
    city_summary["City"] == selected_city
].copy()

if selected_city_summary.empty:
    st.error(f"No summary data was found for {selected_city}.")
    st.stop()

city_rank_df = (
    city_summary
    .sort_values("total_incidents", ascending=False)
    .reset_index(drop=True)
)

city_rank_match = city_rank_df[
    city_rank_df["City"] == selected_city
]

city_rank = (
    int(city_rank_match.index[0]) + 1
    if not city_rank_match.empty
    else None
)

city_incidents = int(
    selected_city_summary["total_incidents"].iloc[0]
)

city_zip_count = int(
    zip_detail.loc[
        zip_detail["City"] == selected_city,
        "Zip Code",
    ].nunique()
)

col1, col2, col3, col4 = st.columns(4)
col1.metric("Selected city", selected_city)
col2.metric("Total incidents", f"{city_incidents:,}")
col3.metric("ZIPs covered", f"{city_zip_count:,}")
col4.metric(
    "Incident rank",
    f"#{city_rank}" if city_rank is not None else "N/A",
)

st.divider()


st.header("1. Where is crime concentrated?")
st.caption(
    "ZIP-code boundaries are shaded by total incident frequency."
)

try:
    zip_geojson = load_zip_geojson()
except Exception as exc:
    st.error("Could not load ZIP-code boundary data.")
    st.code(str(exc))
    zip_geojson = {
        "type": "FeatureCollection",
        "features": [],
    }

map_df = zip_detail.copy()

if map_scope == "Selected city ZIPs":
    map_df = map_df[
        map_df["City"] == selected_city
    ].copy()

zip_metrics = {
    row["Zip Code"]: {
        "City": row["City"],
        "State": row["State"],
        "Zip Code": row["Zip Code"],
        "total_incidents": int(row["total_incidents"]),
        "total_victims": int(row["total_victims"]),
    }
    for _, row in map_df.iterrows()
}

max_incidents = max(
    [
        metrics["total_incidents"]
        for metrics in zip_metrics.values()
    ],
    default=1,
)

choropleth_features = []

for feature in zip_geojson.get("features", []):
    zip_code = (
        feature
        .get("properties", {})
        .get("zip_code")
    )

    if zip_code not in zip_metrics:
        continue

    metrics = zip_metrics[zip_code]
    color_score = (
        int(
            metrics["total_incidents"]
            / max_incidents
            * 255
        )
        if max_incidents
        else 0
    )

    feature["properties"].update(metrics)
    feature["properties"]["color_score"] = color_score
    choropleth_features.append(feature)

choropleth_geojson = {
    "type": "FeatureCollection",
    "features": choropleth_features,
}

if not choropleth_features:
    st.warning(
        "No ZIP-code polygons matched the ZIP-level dashboard data."
    )
else:
    map_layer = pdk.Layer(
        "GeoJsonLayer",
        choropleth_geojson,
        pickable=True,
        stroked=True,
        filled=True,
        extruded=False,
        get_fill_color=(
            "[255, 255 - properties.color_score, "
            "255 - properties.color_score, 180]"
        ),
        get_line_color="[40, 40, 40, 220]",
        line_width_min_pixels=1,
    )

    view_state = pdk.ViewState(
        latitude=39.10,
        longitude=-77.15,
        zoom=(
            9.2
            if map_scope == "All Montgomery County ZIPs"
            else 10.4
        ),
        pitch=0,
    )

    tooltip = {
        "html": (
            "<b>{City}</b><br/>"
            "ZIP: {Zip Code}<br/>"
            "Incidents: {total_incidents}<br/>"
            "Victims: {total_victims}"
        ),
        "style": {
            "backgroundColor": "#111827",
            "color": "white",
        },
    }

    st.pydeck_chart(
        pdk.Deck(
            layers=[map_layer],
            initial_view_state=view_state,
            tooltip=tooltip,
            map_style="mapbox://styles/mapbox/light-v9",
        )
    )

with st.expander("View ZIP map data"):
    st.dataframe(
        map_df[
            [
                "City",
                "State",
                "Zip Code",
                "total_incidents",
                "total_victims",
            ]
        ].sort_values(
            "total_incidents",
            ascending=False,
        ),
        width="stretch",
    )

st.divider()


st.header("2. How does this city compare?")
st.caption(
    "Top Montgomery County cities by total incidents."
)

city_top = (
    city_summary
    .sort_values("total_incidents", ascending=False)
    .head(top_n)
)

city_bar = (
    alt.Chart(city_top)
    .mark_bar()
    .encode(
        x=alt.X(
            "total_incidents:Q",
            title="Total incidents",
        ),
        y=alt.Y(
            "City:N",
            sort="-x",
            title="City",
        ),
        tooltip=[
            "City",
            "State",
            "total_incidents",
            "total_victims",
        ],
    )
    .properties(height=420)
)

st.altair_chart(city_bar, use_container_width=True)

with st.expander("View city summary data"):
    st.dataframe(
        city_summary.sort_values(
            "total_incidents",
            ascending=False,
        ),
        width="stretch",
    )

st.divider()


st.header("3. Is crime increasing or decreasing?")
st.caption("Monthly trend for the selected city.")

selected_trend = city_trend[
    city_trend["City"] == selected_city
].copy()

selected_trend = selected_trend.sort_values(
    ["year_number", "month_number"]
)

# Exclude the most recent available month because it may be incomplete.
# This is dynamic and always removes the latest month in the data,
# rather than a hard-coded month such as July 2026.
if not selected_trend.empty:
    selected_trend["month_date"] = pd.to_datetime(
        selected_trend["month_period"],
        format="%Y-%m",
        errors="coerce",
    )

    latest_month = selected_trend["month_date"].max()

    if pd.notna(latest_month):
        selected_trend = selected_trend[
            selected_trend["month_date"] < latest_month
        ].copy()

    selected_trend = selected_trend.drop(
        columns=["month_date"],
        errors="ignore",
    )

if selected_trend.empty:
    st.info("No monthly trend data is available for this city.")
else:
    trend_line = (
        alt.Chart(selected_trend)
        .mark_line(point=True)
        .encode(
            x=alt.X(
                "month_period:N",
                title="Month",
                sort=None,
            ),
            y=alt.Y(
                "total_incidents:Q",
                title="Total incidents",
            ),
            tooltip=[
                "month_period",
                "total_incidents",
                "total_victims",
            ],
        )
        .properties(height=360)
    )

    st.altair_chart(
        trend_line,
        use_container_width=True,
    )

with st.expander("View city trend data"):
    st.dataframe(selected_trend, width="stretch")

st.divider()


st.header("4. What types of crime happen here?")
st.caption(
    "The most common secondary crime categories for the selected city."
)

selected_crime_mix = crime_mix[
    crime_mix["City"] == selected_city
].copy()

# Remove generic catch-all categories so the chart highlights
# specific, actionable crime categories.
selected_crime_mix = selected_crime_mix[
    selected_crime_mix["crime_category_secondary"].notna()
].copy()

selected_crime_mix = selected_crime_mix[
    ~selected_crime_mix["crime_category_secondary"]
    .astype("string")
    .str.strip()
    .str.casefold()
    .eq("all other offenses")
].copy()

if selected_crime_mix.empty:
    st.info("No specific crime-category data is available for this city.")
else:
    secondary_mix = (
        selected_crime_mix
        .groupby(
            "crime_category_secondary",
            as_index=False,
        )
        .agg(
            incident_count=("incident_count", "sum"),
            offense_count=("offense_count", "sum"),
        )
        .sort_values(
            "incident_count",
            ascending=False,
        )
        .head(top_n_secondary)
    )

    secondary_chart = (
        alt.Chart(secondary_mix)
        .mark_bar()
        .encode(
            x=alt.X(
                "incident_count:Q",
                title="Incidents",
            ),
            y=alt.Y(
                "crime_category_secondary:N",
                sort="-x",
                title="Secondary crime category",
            ),
            tooltip=[
                alt.Tooltip(
                    "crime_category_secondary:N",
                    title="Crime category",
                ),
                alt.Tooltip(
                    "incident_count:Q",
                    title="Incidents",
                    format=",",
                ),
                alt.Tooltip(
                    "offense_count:Q",
                    title="Offenses",
                    format=",",
                ),
            ],
        )
        .properties(height=520)
    )

    st.altair_chart(
        secondary_chart,
        use_container_width=True,
    )

with st.expander("View secondary crime-category data"):
    st.dataframe(
        secondary_mix
        if not selected_crime_mix.empty
        else selected_crime_mix,
        width="stretch",
    )

st.divider()


st.header("5. When does crime happen?")
st.caption(
    "Day-of-week and hour-of-day patterns for the selected city."
)

selected_time = time_heatmap[
    time_heatmap["City"] == selected_city
].copy()

if selected_time.empty:
    st.info("No time-pattern data is available for this city.")
else:
    selected_time["hour_label"] = (
        selected_time["hour_of_day"]
        .astype(int)
        .astype(str)
        .str.zfill(2)
        + ":00"
    )

    hour_order = [
        f"{hour:02d}:00"
        for hour in range(24)
    ]

    heatmap = (
        alt.Chart(selected_time)
        .mark_rect()
        .encode(
            x=alt.X(
                "hour_label:O",
                title="Hour of day",
                sort=hour_order,
            ),
            y=alt.Y(
                "day_of_week:N",
                title="Day of week",
                sort=[
                    "Sunday",
                    "Monday",
                    "Tuesday",
                    "Wednesday",
                    "Thursday",
                    "Friday",
                    "Saturday",
                ],
            ),
            color=alt.Color(
                "total_incidents:Q",
                title="Incidents",
            ),
            tooltip=[
                "day_of_week",
                "hour_label",
                "total_incidents",
                "total_victims",
            ],
        )
        .properties(height=360)
    )

    st.altair_chart(heatmap, use_container_width=True)

with st.expander("View time heatmap data"):
    st.dataframe(selected_time, width="stretch")

st.divider()


st.header("6. Where within the selected city?")
st.caption(
    "ZIP-code drill-down for the selected city."
)

selected_zip = zip_detail[
    zip_detail["City"] == selected_city
].copy()

selected_zip = selected_zip.sort_values(
    "total_incidents",
    ascending=False,
)

if selected_zip.empty:
    st.info("No ZIP-level data is available for this city.")
else:
    zip_bar = (
        alt.Chart(selected_zip)
        .mark_bar()
        .encode(
            x=alt.X(
                "total_incidents:Q",
                title="Total incidents",
            ),
            y=alt.Y(
                "Zip Code:N",
                sort="-x",
                title="ZIP code",
            ),
            tooltip=[
                "Zip Code",
                "total_incidents",
                "total_victims",
            ],
        )
        .properties(height=300)
    )

    st.altair_chart(
        zip_bar,
        use_container_width=True,
    )

st.dataframe(
    selected_zip[
        [
            "City",
            "State",
            "Zip Code",
            "total_incidents",
            "total_victims",
        ]
    ],
    width="stretch",
)

st.divider()
st.caption(
    "Views used: community_city_summary, community_city_trend, "
    "community_crime_mix, community_time_heatmap, "
    "community_zip_detail."
)
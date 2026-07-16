import altair as alt
import pandas as pd
import streamlit as st
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_FOLDER = PROJECT_ROOT / "dashboard_data"


@st.cache_data
def load_data():
    return {
        "district_summary": pd.read_csv(
            DATA_FOLDER / "police_district_summary.csv",
            dtype={"district_number": "string"},
        ),
        "district_trend": pd.read_csv(
            DATA_FOLDER / "police_district_trend.csv",
            dtype={"district_number": "string"},
        ),
        "district_crime_mix": pd.read_csv(
            DATA_FOLDER / "police_district_crime_mix.csv",
            dtype={"district_number": "string"},
        ),
        "district_place_hotspots": pd.read_csv(
            DATA_FOLDER / "police_district_place_hotspots.csv",
            dtype={"district_number": "string"},
        ),
    }


try:
    data = load_data()
except Exception as exc:
    st.error("Could not load the exported police dashboard CSV files.")
    st.code(str(exc))
    st.stop()


district_summary = data["district_summary"]
district_trend = data["district_trend"]
district_crime_mix = data["district_crime_mix"]
district_place_hotspots = data["district_place_hotspots"]


for dataframe in [
    district_summary,
    district_trend,
    district_crime_mix,
    district_place_hotspots,
]:
    if "district_number" in dataframe.columns:
        dataframe["district_number"] = (
            dataframe["district_number"]
            .astype("string")
            .str.strip()
        )

    if "district_name" in dataframe.columns:
        dataframe["district_name"] = (
            dataframe["district_name"]
            .astype("string")
            .str.strip()
        )


st.sidebar.title("Police Dashboard Filters")

district_options_df = (
    district_summary[
        ["district_number", "district_name"]
    ]
    .dropna(subset=["district_number"])
    .drop_duplicates()
    .sort_values("district_number")
)

if district_options_df.empty:
    st.error(
        "No police districts were returned from "
        "police_district_summary."
    )
    st.stop()

district_labels = {
    row["district_number"]: (
        f'{row["district_number"]} - {row["district_name"]}'
        if pd.notna(row["district_name"])
        else str(row["district_number"])
    )
    for _, row in district_options_df.iterrows()
}

selected_district = st.sidebar.selectbox(
    "Select a police district",
    options=list(district_labels.keys()),
    format_func=lambda value: district_labels[value],
)

top_n_crimes = st.sidebar.slider(
    "Top secondary crime categories",
    min_value=5,
    max_value=25,
    value=12,
)

top_n_places = st.sidebar.slider(
    "Top place categories",
    min_value=5,
    max_value=25,
    value=10,
)

if st.sidebar.button("Clear cache"):
    st.cache_data.clear()
    st.cache_resource.clear()
    st.rerun()


st.title("Montgomery County Police Operations Dashboard")
st.markdown(
    "A focused district-level dashboard for comparing police districts, "
    "monitoring incident trends, reviewing secondary crime categories, "
    "and identifying the place categories with the most incidents."
)


selected_summary = district_summary[
    district_summary["district_number"] == selected_district
].copy()

if selected_summary.empty:
    st.error(
        f"No summary data was found for district "
        f"{selected_district}."
    )
    st.stop()

district_rank_df = (
    district_summary
    .sort_values("total_incidents", ascending=False)
    .reset_index(drop=True)
)

district_rank_match = district_rank_df[
    district_rank_df["district_number"] == selected_district
]

district_rank = (
    int(district_rank_match.index[0]) + 1
    if not district_rank_match.empty
    else None
)

district_name = selected_summary["district_name"].iloc[0]
total_incidents = int(
    selected_summary["total_incidents"].iloc[0]
)

selected_district_crimes = district_crime_mix[
    district_crime_mix["district_number"] == selected_district
].copy()

selected_district_crimes = selected_district_crimes[
    selected_district_crimes["crime_category_secondary"].notna()
].copy()

selected_district_crimes = selected_district_crimes[
    ~selected_district_crimes["crime_category_secondary"]
    .astype("string")
    .str.strip()
    .str.casefold()
    .eq("all other offenses")
].copy()

if selected_district_crimes.empty:
    top_crime_category = "N/A"
else:
    top_crime_category = (
        selected_district_crimes
        .groupby(
            "crime_category_secondary",
            as_index=False,
        )["incident_count"]
        .sum()
        .sort_values(
            "incident_count",
            ascending=False,
        )
        .iloc[0]["crime_category_secondary"]
    )

col1, col2, col3, col4 = st.columns(4)
col1.metric(
    "Selected district",
    f"{selected_district} - {district_name}",
)
col2.metric("Total incidents", f"{total_incidents:,}")
col3.metric("Top crime category", top_crime_category)
col4.metric(
    "Incident rank",
    f"#{district_rank}" if district_rank is not None else "N/A",
)

st.divider()


st.header("1. How do police districts compare?")
st.caption(
    "Total incident volume across Montgomery County police districts."
)

district_compare = district_summary.sort_values(
    "total_incidents",
    ascending=False,
)

district_bar = (
    alt.Chart(district_compare)
    .mark_bar()
    .encode(
        x=alt.X(
            "total_incidents:Q",
            title="Total incidents",
        ),
        y=alt.Y(
            "district_name:N",
            sort="-x",
            title="Police district",
        ),
        tooltip=[
            alt.Tooltip(
                "district_number:N",
                title="District number",
            ),
            alt.Tooltip(
                "district_name:N",
                title="District",
            ),
            alt.Tooltip(
                "total_incidents:Q",
                title="Incidents",
                format=",",
            ),
            alt.Tooltip(
                "total_victims:Q",
                title="Victims",
                format=",",
            ),
        ],
    )
    .properties(height=360)
)

st.altair_chart(
    district_bar,
    use_container_width=True,
)

with st.expander("View district summary data"):
    st.dataframe(
        district_compare,
        width="stretch",
    )

st.divider()


st.header("2. How is incident volume changing?")
st.caption(
    f"Monthly incident trend for {district_name}."
)

selected_trend = district_trend[
    district_trend["district_number"] == selected_district
].copy()

selected_trend = selected_trend.sort_values(
    ["year_number", "month_number"]
)

# Exclude the most recent available month because it may be incomplete.
# This is dynamic and will always remove the latest month in the data,
# rather than a hard-coded calendar month.
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
    st.info(
        "No monthly trend data is available for this district."
    )
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
                scale=alt.Scale(zero=False),
            ),
            tooltip=[
                alt.Tooltip(
                    "month_period:N",
                    title="Month",
                ),
                alt.Tooltip(
                    "total_incidents:Q",
                    title="Incidents",
                    format=",",
                ),
                alt.Tooltip(
                    "total_victims:Q",
                    title="Victims",
                    format=",",
                ),
            ],
        )
        .properties(height=380)
    )

    st.altair_chart(
        trend_line,
        use_container_width=True,
    )

with st.expander("View district trend data"):
    st.dataframe(
        selected_trend,
        width="stretch",
    )

st.divider()


st.header("3. What types of crime occur in this district?")
st.caption(
    f"Top secondary crime categories reported in {district_name}."
)

selected_crime_mix = district_crime_mix[
    district_crime_mix["district_number"] == selected_district
].copy()

# Remove generic catch-all categories so the KPI and chart
# surface more specific crime types.
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
    st.info(
        "No crime-category data is available for this district."
    )
    secondary_mix = selected_crime_mix
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
            total_victims=("total_victims", "sum"),
        )
        .sort_values(
            "incident_count",
            ascending=False,
        )
        .head(top_n_crimes)
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
                alt.Tooltip(
                    "total_victims:Q",
                    title="Victims",
                    format=",",
                ),
            ],
        )
        .properties(height=500)
    )

    st.altair_chart(
        secondary_chart,
        use_container_width=True,
    )

with st.expander("View secondary crime-category data"):
    st.dataframe(
        secondary_mix,
        width="stretch",
    )

st.divider()


st.header("4. Which place categories have the most incidents?")
st.caption(
    f"Most common incident location categories in {district_name}."
)

selected_places = district_place_hotspots[
    district_place_hotspots["district_number"]
    == selected_district
].copy()

selected_places = (
    selected_places
    .sort_values(
        "total_incidents",
        ascending=False,
    )
    .head(top_n_places)
)

if selected_places.empty:
    st.info(
        "No place-category data is available for this district."
    )
else:
    places_chart = (
        alt.Chart(selected_places)
        .mark_bar()
        .encode(
            x=alt.X(
                "total_incidents:Q",
                title="Total incidents",
            ),
            y=alt.Y(
                "place:N",
                sort="-x",
                title="Place category",
            ),
            tooltip=[
                alt.Tooltip(
                    "place:N",
                    title="Place category",
                ),
                alt.Tooltip(
                    "total_incidents:Q",
                    title="Incidents",
                    format=",",
                ),
                alt.Tooltip(
                    "total_victims:Q",
                    title="Victims",
                    format=",",
                ),
            ],
        )
        .properties(height=440)
    )

    st.altair_chart(
        places_chart,
        use_container_width=True,
    )

with st.expander("View place-category data"):
    st.dataframe(
        selected_places,
        width="stretch",
    )


st.divider()
st.caption(
    "Views used: police_district_summary, police_district_trend, "
    "police_district_crime_mix, and "
    "police_district_place_hotspots."
)
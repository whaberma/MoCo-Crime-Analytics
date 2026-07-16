import streamlit as st

st.set_page_config(
    page_title="MoCo Crime Analytics",
    page_icon="📊",
    layout="wide",
)

st.title("Montgomery County Crime Analytics")

st.markdown(
    '''
    This public dashboard provides two views of Montgomery County crime data.

    ### Community Dashboard
    Explore crime concentration by ZIP code, compare cities, review monthly
    trends, examine secondary crime categories, and analyze time patterns.

    ### Police Operations Dashboard
    Compare police districts, monitor monthly incident trends, review secondary
    crime categories, and identify the place categories with the most incidents.

    The public version uses precomputed CSV files exported from the project's
    normalized MySQL database and SQL views.

    Use the sidebar to open either dashboard.
    '''
)

st.info("Public deployment version • No live database connection required")
# Montgomery County Crime Analytics

An end-to-end data engineering and analytics project that ingests Montgomery County crime data into a normalized MySQL database, validates ZIP codes, builds SQL reporting views, and serves interactive Streamlit dashboards using precomputed datasets for public deployment.

---

## Project Overview

This project analyzes over **500,000 Montgomery County, Maryland crime incidents** through an automated data pipeline and interactive dashboards.

The project demonstrates the complete analytics workflow:

- Data ingestion with Python ETL
- Data validation and cleaning
- Relational database design in MySQL
- SQL reporting views
- Interactive Streamlit dashboards
- Public deployment using precomputed dashboard datasets

Instead of connecting a public application directly to a database, dashboard datasets are exported after each monthly update, allowing the public dashboard to run securely without exposing database credentials.

---

## Features

### Community Dashboard

Designed for residents and community members.

- ZIP-code crime concentration map
- Compare Montgomery County cities
- Monthly crime trends
- Secondary crime category analysis
- ZIP-level drill-down within each city

### Police Operations Dashboard

Designed for district-level operational analysis.

- Compare police districts
- Monthly incident trends
- Secondary crime category analysis
- Place category hotspots
- District rankings and KPIs

---

## Technology Stack

### Languages

- Python
- SQL

### Database

- MySQL

### Data Engineering

- Python ETL
- Data validation
- Incremental loading
- Relational database normalization

### Analytics

- SQL Views
- Aggregations
- Trend analysis

### Dashboard

- Streamlit
- Altair
- Plotly
- Folium

---

## Database Design

The project uses a normalized relational database consisting of:

- incidents
- incident_crimes
- crime_types
- police_districts
- agencies
- places
- valid_moco_zip_codes
- etl_batches

ZIP codes are validated against a whitelist of Montgomery County ZIP codes before being included in dashboard reporting.

---

## Project Architecture

```
Montgomery County Crime Data
            │
            ▼
      Python ETL Pipeline
            │
            ▼
   Normalized MySQL Database
            │
            ▼
      SQL Reporting Views
            │
            ▼
 Export Dashboard CSV Files
            │
            ▼
   Streamlit Public Dashboard
```

---

## Repository Structure

```
.
├── dashboard_data/
│   ├── community_city_summary.csv
│   ├── community_city_trend.csv
│   ├── community_crime_mix.csv
│   ├── community_time_heatmap.csv
│   ├── community_zip_detail.csv
│   ├── police_district_summary.csv
│   ├── police_district_trend.csv
│   ├── police_district_crime_mix.csv
│   └── police_district_place_hotspots.csv
│
├── pages/
│   ├── 1_community_dashboard.py
│   └── 2_police_dashboard.py
│
├── SQL/
│   ├── schema.sql
│   ├── community_views.sql
│   └── police_views.sql
│
├── Home.py
├── requirements.txt
└── README.md
```

---

## Running the Dashboard

Clone the repository

```bash
git clone https://github.com/whaberma/MoCo-Crime-Analytics.git
```

Install dependencies

```bash
pip install -r requirements.txt
```

Launch Streamlit

```bash
streamlit run Home.py
```

---

## Data Source

Montgomery County Open Data Portal

Public Safety Crime Data

https://data.montgomerycountymd.gov/

---

## Monthly Update Process

The dashboard is updated once per month.

1. Download the newest crime records.
2. Run the Python ETL pipeline.
3. Validate ZIP codes.
4. Refresh SQL reporting views.
5. Export dashboard datasets.
6. Replace CSV files inside `dashboard_data`.
7. Commit and push the updated repository.

No database credentials are required for the deployed dashboard.

---

## Future Improvements

- Automated monthly dashboard export
- Cloud-hosted ETL pipeline
- Scheduled dashboard refreshes
- Additional law enforcement analytics
- Crime forecasting and predictive analytics
- Public API integration

---

## Skills Demonstrated

- Data Engineering
- ETL Development
- Relational Database Design
- SQL Analytics
- Data Validation
- Data Visualization
- Python Programming
- Streamlit Development
- Dashboard Design
- Data Modeling

---

## Author

**William Haberman**

Information Science  
University of Maryland, College Park

GitHub: https://github.com/whaberma
LinkedIn: https://linkedin.com/in/william-jack-haberman
USE moco_crime_v2;

-- 1) City summary
CREATE OR REPLACE VIEW community_city_summary AS
SELECT
    v.city AS City,
    v.state AS State,
    COUNT(DISTINCT i.`Incident ID`) AS total_incidents,
    SUM(COALESCE(i.Victims, 0)) AS total_victims
    
FROM incidents AS i
INNER JOIN valid_moco_zip_codes AS v
    ON i.`Zip Code` = v.zip_code
GROUP BY
    v.city,
    v.state;


-- 2) Monthly city trend
CREATE OR REPLACE VIEW community_city_trend AS
SELECT
    v.city AS City,
    v.state AS State,
    YEAR(i.Start_Date_Time) AS year_number,
    MONTH(i.Start_Date_Time) AS month_number,
    DATE_FORMAT(i.Start_Date_Time, '%Y-%m') AS month_period,
    COUNT(DISTINCT i.`Incident ID`) AS total_incidents,
    SUM(COALESCE(i.Victims, 0)) AS total_victims
FROM incidents AS i
INNER JOIN valid_moco_zip_codes AS v
    ON i.`Zip Code` = v.zip_code
WHERE i.Start_Date_Time IS NOT NULL
GROUP BY
    v.city,
    v.state,
    YEAR(i.Start_Date_Time),
    MONTH(i.Start_Date_Time),
    DATE_FORMAT(i.Start_Date_Time, '%Y-%m');


-- 3) Crime mix by city
CREATE OR REPLACE VIEW community_crime_mix AS
SELECT
    v.city AS City,
    v.state AS State,
    ct.`Crime Name1` AS crime_category_primary,
    ct.`Crime Name2` AS crime_category_secondary,
    COUNT(*) AS offense_count,
    COUNT(DISTINCT i.`Incident ID`) AS incident_count
FROM incidents AS i
INNER JOIN incident_crimes AS ic
    ON i.`Incident ID` = ic.`Incident ID`
INNER JOIN crime_types AS ct
    ON ic.`Offence Code` = ct.`Offence Code`
INNER JOIN valid_moco_zip_codes AS v
    ON i.`Zip Code` = v.zip_code
WHERE ct.`Crime Name1` IS NOT NULL
  AND ct.`Crime Name2` IS NOT NULL
GROUP BY
    v.city,
    v.state,
    ct.`Crime Name1`,
    ct.`Crime Name2`;


-- 4) Day/hour heatmap by city
CREATE OR REPLACE VIEW community_time_heatmap AS
SELECT
    v.city AS City,
    v.state AS State,
    DAYOFWEEK(i.Start_Date_Time) AS day_number,
    DAYNAME(i.Start_Date_Time) AS day_of_week,
    HOUR(i.Start_Date_Time) AS hour_of_day,
    COUNT(DISTINCT i.`Incident ID`) AS total_incidents,
    SUM(COALESCE(i.Victims, 0)) AS total_victims
FROM incidents AS i
INNER JOIN valid_moco_zip_codes AS v
    ON i.`Zip Code` = v.zip_code
WHERE i.Start_Date_Time IS NOT NULL
GROUP BY
    v.city,
    v.state,
    DAYOFWEEK(i.Start_Date_Time),
    DAYNAME(i.Start_Date_Time),
    HOUR(i.Start_Date_Time);


-- 5) ZIP drill-down within city
CREATE OR REPLACE VIEW community_zip_detail AS
SELECT
    v.city AS City,
    v.state AS State,
    v.zip_code AS `Zip Code`,
    COUNT(DISTINCT i.`Incident ID`) AS total_incidents,
    SUM(COALESCE(i.Victims, 0)) AS total_victims
FROM incidents AS i
INNER JOIN valid_moco_zip_codes AS v
    ON i.`Zip Code` = v.zip_code
GROUP BY
    v.city,
    v.state,
    v.zip_code;
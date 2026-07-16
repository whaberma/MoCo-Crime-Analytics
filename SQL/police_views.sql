USE moco_crime_v2;

CREATE OR REPLACE VIEW police_district_crime_mix AS
SELECT 
        `pd`.`Police District Number` AS `district_number`,
        `pd`.`Police District` AS `district_name`,
        `ct`.`Crime Name1` AS `crime_category_primary`,
        `ct`.`Crime Name2` AS `crime_category_secondary`,
        COUNT(0) AS `offense_count`,
        COUNT(DISTINCT `i`.`Incident ID`) AS `incident_count`,
        SUM(COALESCE(`i`.`Victims`, 0)) AS `total_victims`
    FROM
        (((`incidents` `i`
        JOIN `police_districts` `pd` ON ((`i`.`Police District Number` = `pd`.`Police District Number`)))
        JOIN `incident_crimes` `ic` ON ((`i`.`Incident ID` = `ic`.`Incident ID`)))
        JOIN `crime_types` `ct` ON ((`ic`.`Offence Code` = `ct`.`Offence Code`)))
    WHERE
        ((`ct`.`Crime Name1` IS NOT NULL)
            AND (`ct`.`Crime Name2` IS NOT NULL))
    GROUP BY `pd`.`Police District Number` , `pd`.`Police District` , `ct`.`Crime Name1` , `ct`.`Crime Name2`;
    
CREATE OR REPLACE VIEW police_district_place_hotspots AS
SELECT 
        `pd`.`Police District Number` AS `district_number`,
        `pd`.`Police District` AS `district_name`,
        `p`.`Place` AS `place`,
        COUNT(DISTINCT `i`.`Incident ID`) AS `total_incidents`,
        SUM(COALESCE(`i`.`Victims`, 0)) AS `total_victims`
    FROM
        ((`incidents` `i`
        JOIN `police_districts` `pd` ON ((`i`.`Police District Number` = `pd`.`Police District Number`)))
        JOIN `places` `p` ON ((`i`.`Place_ID` = `p`.`Place_ID`)))
    WHERE
        ((`p`.`Place` IS NOT NULL)
            AND (TRIM(`p`.`Place`) <> ''))
    GROUP BY `pd`.`Police District Number` , `pd`.`Police District` , `p`.`Place`;
    
CREATE OR REPLACE VIEW police_district_summary AS
SELECT 
        `pd`.`Police District Number` AS `district_number`,
        `pd`.`Police District` AS `district_name`,
        COUNT(DISTINCT `i`.`Incident ID`) AS `total_incidents`,
        SUM(COALESCE(`i`.`Victims`, 0)) AS `total_victims`,
        COUNT(DISTINCT `i`.`Zip Code`) AS `zip_codes_covered`
    FROM
        (`incidents` `i`
        JOIN `police_districts` `pd` ON ((`i`.`Police District Number` = `pd`.`Police District Number`)))
    GROUP BY `pd`.`Police District Number` , `pd`.`Police District`;
    
CREATE OR REPLACE VIEW police_district_trend AS
SELECT 
        `pd`.`Police District Number` AS `district_number`,
        `pd`.`Police District` AS `district_name`,
        YEAR(`i`.`Start_Date_Time`) AS `year_number`,
        MONTH(`i`.`Start_Date_Time`) AS `month_number`,
        DATE_FORMAT(`i`.`Start_Date_Time`, '%Y-%m') AS `month_period`,
        COUNT(DISTINCT `i`.`Incident ID`) AS `total_incidents`,
        SUM(COALESCE(`i`.`Victims`, 0)) AS `total_victims`
    FROM
        (`incidents` `i`
        JOIN `police_districts` `pd` ON ((`i`.`Police District Number` = `pd`.`Police District Number`)))
    WHERE
        (`i`.`Start_Date_Time` IS NOT NULL)
    GROUP BY `pd`.`Police District Number` , `pd`.`Police District` , YEAR(`i`.`Start_Date_Time`) , MONTH(`i`.`Start_Date_Time`) , DATE_FORMAT(`i`.`Start_Date_Time`, '%Y-%m');
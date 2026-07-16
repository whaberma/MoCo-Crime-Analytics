-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema moco_crime_v2
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema moco_crime_v2
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `moco_crime_v2` DEFAULT CHARACTER SET utf8mb3 ;
USE `moco_crime_v2` ;

-- -----------------------------------------------------
-- Table `moco_crime_v2`.`agencies`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`agencies` (
  `Agency_ID` INT NOT NULL AUTO_INCREMENT,
  `Agency` VARCHAR(45) NULL DEFAULT NULL,
  PRIMARY KEY (`Agency_ID`),
  UNIQUE INDEX `Agency_UNIQUE` (`Agency` ASC) VISIBLE)
ENGINE = InnoDB
AUTO_INCREMENT = 244
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `moco_crime_v2`.`crime_types`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`crime_types` (
  `Offence Code` INT NOT NULL,
  `NIBRS Code` CHAR(3) NULL DEFAULT NULL,
  `Crime Name1` VARCHAR(80) NULL DEFAULT NULL,
  `Crime Name2` VARCHAR(80) NULL DEFAULT NULL,
  `Crime Name3` VARCHAR(80) NULL DEFAULT NULL,
  PRIMARY KEY (`Offence Code`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `moco_crime_v2`.`etl_batches`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`etl_batches` (
  `Batch_ID` INT NOT NULL AUTO_INCREMENT,
  `Source_Type` VARCHAR(45) NOT NULL,
  `Source_Name` VARCHAR(255) NOT NULL,
  `Load_Start_Time` DATETIME NOT NULL,
  `Load_End_Time` DATETIME NULL DEFAULT NULL,
  `Records_Processed` INT NOT NULL DEFAULT '0',
  `Records_Inserted` INT NOT NULL DEFAULT '0',
  `Records_Updated` INT NOT NULL DEFAULT '0',
  `Records_Failed` INT NOT NULL DEFAULT '0',
  `Status` VARCHAR(45) NOT NULL,
  `Error_Message` MEDIUMTEXT NULL DEFAULT NULL,
  PRIMARY KEY (`Batch_ID`))
ENGINE = InnoDB
AUTO_INCREMENT = 44
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `moco_crime_v2`.`places`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`places` (
  `Place_ID` INT NOT NULL AUTO_INCREMENT,
  `Place` VARCHAR(45) NULL DEFAULT NULL,
  PRIMARY KEY (`Place_ID`),
  UNIQUE INDEX `Place_UNIQUE` (`Place` ASC) VISIBLE)
ENGINE = InnoDB
AUTO_INCREMENT = 3710
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `moco_crime_v2`.`police_districts`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`police_districts` (
  `Police District Number` VARCHAR(4) NOT NULL,
  `Police District` VARCHAR(45) NULL DEFAULT NULL,
  PRIMARY KEY (`Police District Number`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `moco_crime_v2`.`zip_codes`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`zip_codes` (
  `Zip Code` CHAR(5) NOT NULL,
  `City` VARCHAR(45) NULL DEFAULT NULL,
  `State` VARCHAR(45) NULL DEFAULT NULL,
  PRIMARY KEY (`Zip Code`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `moco_crime_v2`.`incidents`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`incidents` (
  `Incident ID` INT NOT NULL,
  `CR Number` VARCHAR(45) NULL DEFAULT NULL,
  `Dispatch Date / Time` DATETIME NULL DEFAULT NULL,
  `Victims` INT NULL DEFAULT NULL,
  `Start_Date_Time` DATETIME NULL DEFAULT NULL,
  `End_Date_Time` DATETIME NULL DEFAULT NULL,
  `Police District Number` VARCHAR(4) NOT NULL,
  `Zip Code` CHAR(5) NULL DEFAULT NULL,
  `Agency_ID` INT NOT NULL,
  `Place_ID` INT NOT NULL,
  `Batch_ID` INT NULL DEFAULT NULL,
  PRIMARY KEY (`Incident ID`),
  INDEX `idx_Incidents_PoliceDistrictNumber` (`Police District Number` ASC) VISIBLE,
  INDEX `idx_Incidents_ZipCode` (`Zip Code` ASC) VISIBLE,
  INDEX `idx_Incidents_AgencyID` (`Agency_ID` ASC) VISIBLE,
  INDEX `idx_Incidents_PlaceID` (`Place_ID` ASC) VISIBLE,
  INDEX `fk_incidents_etl_batches1_idx` (`Batch_ID` ASC) VISIBLE,
  INDEX `idx_Incidents_DispatchDateTime` (`Dispatch Date / Time` ASC) VISIBLE,
  INDEX `idx_Incidents_BatchID` (`Batch_ID` ASC) VISIBLE,
  CONSTRAINT `fk_Incidents_Agencies`
    FOREIGN KEY (`Agency_ID`)
    REFERENCES `moco_crime_v2`.`agencies` (`Agency_ID`),
  CONSTRAINT `fk_incidents_etl_batches1`
    FOREIGN KEY (`Batch_ID`)
    REFERENCES `moco_crime_v2`.`etl_batches` (`Batch_ID`),
  CONSTRAINT `fk_Incidents_Places`
    FOREIGN KEY (`Place_ID`)
    REFERENCES `moco_crime_v2`.`places` (`Place_ID`),
  CONSTRAINT `fk_Incidents_Police_Districts`
    FOREIGN KEY (`Police District Number`)
    REFERENCES `moco_crime_v2`.`police_districts` (`Police District Number`),
  CONSTRAINT `fk_Incidents_Zip_Codes`
    FOREIGN KEY (`Zip Code`)
    REFERENCES `moco_crime_v2`.`zip_codes` (`Zip Code`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `moco_crime_v2`.`incident_crimes`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`incident_crimes` (
  `Incident ID` INT NOT NULL,
  `Offence Code` INT NOT NULL,
  PRIMARY KEY (`Incident ID`, `Offence Code`),
  INDEX `idx_IncidentCrimes_IncidentID` (`Incident ID` ASC) VISIBLE,
  INDEX `idx_IncidentCrimes_OffenceCode` (`Offence Code` ASC) VISIBLE,
  CONSTRAINT `fk_IncidentCrimes_Crime_Types`
    FOREIGN KEY (`Offence Code`)
    REFERENCES `moco_crime_v2`.`crime_types` (`Offence Code`),
  CONSTRAINT `fk_IncidentCrimes_Incidents`
    FOREIGN KEY (`Incident ID`)
    REFERENCES `moco_crime_v2`.`incidents` (`Incident ID`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `moco_crime_v2`.`valid_moco_zip_codes`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`valid_moco_zip_codes` (
  `zip_code` CHAR(5) NOT NULL,
  `city` VARCHAR(100) NOT NULL,
  `state` CHAR(2) NOT NULL,
  PRIMARY KEY (`zip_code`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;

USE `moco_crime_v2` ;

-- -----------------------------------------------------
-- Placeholder table for view `moco_crime_v2`.`community_city_summary`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`community_city_summary` (`City` INT, `State` INT, `total_incidents` INT, `total_victims` INT);

-- -----------------------------------------------------
-- Placeholder table for view `moco_crime_v2`.`community_city_trend`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`community_city_trend` (`City` INT, `State` INT, `year_number` INT, `month_number` INT, `month_period` INT, `total_incidents` INT, `total_victims` INT);

-- -----------------------------------------------------
-- Placeholder table for view `moco_crime_v2`.`community_crime_mix`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`community_crime_mix` (`City` INT, `State` INT, `crime_category_primary` INT, `crime_category_secondary` INT, `offense_count` INT, `incident_count` INT);

-- -----------------------------------------------------
-- Placeholder table for view `moco_crime_v2`.`community_time_heatmap`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`community_time_heatmap` (`City` INT, `State` INT, `day_number` INT, `day_of_week` INT, `hour_of_day` INT, `total_incidents` INT, `total_victims` INT);

-- -----------------------------------------------------
-- Placeholder table for view `moco_crime_v2`.`community_zip_detail`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`community_zip_detail` (`City` INT, `State` INT, `Zip Code` INT, `total_incidents` INT, `total_victims` INT);

-- -----------------------------------------------------
-- Placeholder table for view `moco_crime_v2`.`police_district_crime_mix`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`police_district_crime_mix` (`district_number` INT, `district_name` INT, `crime_category_primary` INT, `crime_category_secondary` INT, `offense_count` INT, `incident_count` INT, `total_victims` INT);

-- -----------------------------------------------------
-- Placeholder table for view `moco_crime_v2`.`police_district_place_hotspots`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`police_district_place_hotspots` (`district_number` INT, `district_name` INT, `place` INT, `total_incidents` INT, `total_victims` INT);

-- -----------------------------------------------------
-- Placeholder table for view `moco_crime_v2`.`police_district_summary`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`police_district_summary` (`district_number` INT, `district_name` INT, `total_incidents` INT, `total_victims` INT, `zip_codes_covered` INT);

-- -----------------------------------------------------
-- Placeholder table for view `moco_crime_v2`.`police_district_trend`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `moco_crime_v2`.`police_district_trend` (`district_number` INT, `district_name` INT, `year_number` INT, `month_number` INT, `month_period` INT, `total_incidents` INT, `total_victims` INT);

-- -----------------------------------------------------
-- View `moco_crime_v2`.`community_city_summary`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `moco_crime_v2`.`community_city_summary`;
USE `moco_crime_v2`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `moco_crime_v2`.`community_city_summary` AS select `v`.`city` AS `City`,`v`.`state` AS `State`,count(distinct `i`.`Incident ID`) AS `total_incidents`,sum(coalesce(`i`.`Victims`,0)) AS `total_victims` from (`moco_crime_v2`.`incidents` `i` join `moco_crime_v2`.`valid_moco_zip_codes` `v` on((`i`.`Zip Code` = `v`.`zip_code`))) group by `v`.`city`,`v`.`state`;

-- -----------------------------------------------------
-- View `moco_crime_v2`.`community_city_trend`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `moco_crime_v2`.`community_city_trend`;
USE `moco_crime_v2`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `moco_crime_v2`.`community_city_trend` AS select `v`.`city` AS `City`,`v`.`state` AS `State`,year(`i`.`Start_Date_Time`) AS `year_number`,month(`i`.`Start_Date_Time`) AS `month_number`,date_format(`i`.`Start_Date_Time`,'%Y-%m') AS `month_period`,count(distinct `i`.`Incident ID`) AS `total_incidents`,sum(coalesce(`i`.`Victims`,0)) AS `total_victims` from (`moco_crime_v2`.`incidents` `i` join `moco_crime_v2`.`valid_moco_zip_codes` `v` on((`i`.`Zip Code` = `v`.`zip_code`))) where (`i`.`Start_Date_Time` is not null) group by `v`.`city`,`v`.`state`,year(`i`.`Start_Date_Time`),month(`i`.`Start_Date_Time`),date_format(`i`.`Start_Date_Time`,'%Y-%m');

-- -----------------------------------------------------
-- View `moco_crime_v2`.`community_crime_mix`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `moco_crime_v2`.`community_crime_mix`;
USE `moco_crime_v2`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `moco_crime_v2`.`community_crime_mix` AS select `v`.`city` AS `City`,`v`.`state` AS `State`,`ct`.`Crime Name1` AS `crime_category_primary`,`ct`.`Crime Name2` AS `crime_category_secondary`,count(0) AS `offense_count`,count(distinct `i`.`Incident ID`) AS `incident_count` from (((`moco_crime_v2`.`incidents` `i` join `moco_crime_v2`.`incident_crimes` `ic` on((`i`.`Incident ID` = `ic`.`Incident ID`))) join `moco_crime_v2`.`crime_types` `ct` on((`ic`.`Offence Code` = `ct`.`Offence Code`))) join `moco_crime_v2`.`valid_moco_zip_codes` `v` on((`i`.`Zip Code` = `v`.`zip_code`))) where ((`ct`.`Crime Name1` is not null) and (`ct`.`Crime Name2` is not null)) group by `v`.`city`,`v`.`state`,`ct`.`Crime Name1`,`ct`.`Crime Name2`;

-- -----------------------------------------------------
-- View `moco_crime_v2`.`community_time_heatmap`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `moco_crime_v2`.`community_time_heatmap`;
USE `moco_crime_v2`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `moco_crime_v2`.`community_time_heatmap` AS select `v`.`city` AS `City`,`v`.`state` AS `State`,dayofweek(`i`.`Start_Date_Time`) AS `day_number`,dayname(`i`.`Start_Date_Time`) AS `day_of_week`,hour(`i`.`Start_Date_Time`) AS `hour_of_day`,count(distinct `i`.`Incident ID`) AS `total_incidents`,sum(coalesce(`i`.`Victims`,0)) AS `total_victims` from (`moco_crime_v2`.`incidents` `i` join `moco_crime_v2`.`valid_moco_zip_codes` `v` on((`i`.`Zip Code` = `v`.`zip_code`))) where (`i`.`Start_Date_Time` is not null) group by `v`.`city`,`v`.`state`,dayofweek(`i`.`Start_Date_Time`),dayname(`i`.`Start_Date_Time`),hour(`i`.`Start_Date_Time`);

-- -----------------------------------------------------
-- View `moco_crime_v2`.`community_zip_detail`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `moco_crime_v2`.`community_zip_detail`;
USE `moco_crime_v2`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `moco_crime_v2`.`community_zip_detail` AS select `v`.`city` AS `City`,`v`.`state` AS `State`,`v`.`zip_code` AS `Zip Code`,count(distinct `i`.`Incident ID`) AS `total_incidents`,sum(coalesce(`i`.`Victims`,0)) AS `total_victims` from (`moco_crime_v2`.`incidents` `i` join `moco_crime_v2`.`valid_moco_zip_codes` `v` on((`i`.`Zip Code` = `v`.`zip_code`))) group by `v`.`city`,`v`.`state`,`v`.`zip_code`;

-- -----------------------------------------------------
-- View `moco_crime_v2`.`police_district_crime_mix`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `moco_crime_v2`.`police_district_crime_mix`;
USE `moco_crime_v2`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `moco_crime_v2`.`police_district_crime_mix` AS select `pd`.`Police District Number` AS `district_number`,`pd`.`Police District` AS `district_name`,`ct`.`Crime Name1` AS `crime_category_primary`,`ct`.`Crime Name2` AS `crime_category_secondary`,count(0) AS `offense_count`,count(distinct `i`.`Incident ID`) AS `incident_count`,sum(coalesce(`i`.`Victims`,0)) AS `total_victims` from (((`moco_crime_v2`.`incidents` `i` join `moco_crime_v2`.`police_districts` `pd` on((`i`.`Police District Number` = `pd`.`Police District Number`))) join `moco_crime_v2`.`incident_crimes` `ic` on((`i`.`Incident ID` = `ic`.`Incident ID`))) join `moco_crime_v2`.`crime_types` `ct` on((`ic`.`Offence Code` = `ct`.`Offence Code`))) where ((`ct`.`Crime Name1` is not null) and (`ct`.`Crime Name2` is not null)) group by `pd`.`Police District Number`,`pd`.`Police District`,`ct`.`Crime Name1`,`ct`.`Crime Name2`;

-- -----------------------------------------------------
-- View `moco_crime_v2`.`police_district_place_hotspots`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `moco_crime_v2`.`police_district_place_hotspots`;
USE `moco_crime_v2`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `moco_crime_v2`.`police_district_place_hotspots` AS select `pd`.`Police District Number` AS `district_number`,`pd`.`Police District` AS `district_name`,`p`.`Place` AS `place`,count(distinct `i`.`Incident ID`) AS `total_incidents`,sum(coalesce(`i`.`Victims`,0)) AS `total_victims` from ((`moco_crime_v2`.`incidents` `i` join `moco_crime_v2`.`police_districts` `pd` on((`i`.`Police District Number` = `pd`.`Police District Number`))) join `moco_crime_v2`.`places` `p` on((`i`.`Place_ID` = `p`.`Place_ID`))) where ((`p`.`Place` is not null) and (trim(`p`.`Place`) <> '')) group by `pd`.`Police District Number`,`pd`.`Police District`,`p`.`Place`;

-- -----------------------------------------------------
-- View `moco_crime_v2`.`police_district_summary`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `moco_crime_v2`.`police_district_summary`;
USE `moco_crime_v2`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `moco_crime_v2`.`police_district_summary` AS select `pd`.`Police District Number` AS `district_number`,`pd`.`Police District` AS `district_name`,count(distinct `i`.`Incident ID`) AS `total_incidents`,sum(coalesce(`i`.`Victims`,0)) AS `total_victims`,count(distinct `i`.`Zip Code`) AS `zip_codes_covered` from (`moco_crime_v2`.`incidents` `i` join `moco_crime_v2`.`police_districts` `pd` on((`i`.`Police District Number` = `pd`.`Police District Number`))) group by `pd`.`Police District Number`,`pd`.`Police District`;

-- -----------------------------------------------------
-- View `moco_crime_v2`.`police_district_trend`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `moco_crime_v2`.`police_district_trend`;
USE `moco_crime_v2`;
CREATE  OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `moco_crime_v2`.`police_district_trend` AS select `pd`.`Police District Number` AS `district_number`,`pd`.`Police District` AS `district_name`,year(`i`.`Start_Date_Time`) AS `year_number`,month(`i`.`Start_Date_Time`) AS `month_number`,date_format(`i`.`Start_Date_Time`,'%Y-%m') AS `month_period`,count(distinct `i`.`Incident ID`) AS `total_incidents`,sum(coalesce(`i`.`Victims`,0)) AS `total_victims` from (`moco_crime_v2`.`incidents` `i` join `moco_crime_v2`.`police_districts` `pd` on((`i`.`Police District Number` = `pd`.`Police District Number`))) where (`i`.`Start_Date_Time` is not null) group by `pd`.`Police District Number`,`pd`.`Police District`,year(`i`.`Start_Date_Time`),month(`i`.`Start_Date_Time`),date_format(`i`.`Start_Date_Time`,'%Y-%m');

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

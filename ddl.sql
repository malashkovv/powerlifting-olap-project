DROP DATABASE IF EXISTS warehouse;
CREATE DATABASE warehouse;

USE warehouse;

CREATE SCHEMA eds;
CREATE SCHEMA stg;
CREATE SCHEMA adm;

DROP TABLE IF EXISTS stg.powerlifting;
SELECT Name AS full_name,
       Sex AS gender,
       Age AS age,
       BodyweightKg AS weight,
       IIF(Age IS NULL, YEAR(CONVERT(DATE, '1900-01-01')), YEAR(DATEADD(YEAR, -Age, Date))) AS birth_year,
       Date AS meet_date,
       Place AS meet_place,
       Division AS division_name,
       WeightClassKg AS weight_class_name,
       m.MeetID AS meet_id,
       Federation AS federation_name,
       MeetCountry AS country_name,
       MeetState AS state_code,
       MeetTown AS city_name,
       MeetName AS meet_name
  INTO stg.powerlifting
  FROM eds.openpowerlifting opl
  JOIN eds.meets m
    ON opl.MeetID = m.MeetID
;;

DROP TABLE IF EXISTS adm.d_meet;
CREATE TABLE adm.d_meet
(
    meet_pk      INT          NOT NULL IDENTITY,
    meet_id      INT          NOT NULL UNIQUE,
    meet_name    VARCHAR(256) NOT NULL,
    meet_date    DATE         NOT NULL,
    country_name VARCHAR(100)      NOT NULL,
    state_code   VARCHAR(10)     NOT NULL,
    city_name    VARCHAR(100)     NOT NULL
);

MERGE INTO adm.d_meet trgt
USING (
    SELECT DISTINCT pl.meet_id                     AS meet_id,
                    pl.meet_name                   AS meet_name,
                    CONVERT(DATE, pl.meet_date)    AS meet_date,
                    ISNULL(pl.country_name, 'N/A') AS country_name,
                    ISNULL(state_code, 'N/A')      AS state_code,
                    ISNULL(pl.city_name, 'N/A')    AS city_name
    FROM stg.powerlifting pl
) src
ON src.meet_id = trgt.meet_id
WHEN MATCHED THEN
    UPDATE
    SET trgt.city_name    = src.city_name,
        trgt.state_code   = src.state_code,
        trgt.country_name = src.country_name,
        trgt.meet_date    = src.meet_date
WHEN NOT MATCHED THEN
    INSERT
        (meet_id, meet_name, meet_date, country_name, state_code, city_name)
    VALUES (meet_id, meet_name, meet_date, country_name, state_code, city_name)
;


DROP TABLE IF EXISTS adm.d_weight_category;
CREATE TABLE adm.d_weight_category (
    category_pk INT NOT NULL IDENTITY,
    meet_id INT NOT NULL,
    federation_name VARCHAR(30) NOT NULL,
    gender_code CHAR NOT NULL,
    weight_class_name VARCHAR(6) NOT NULL,
    CONSTRAINT genders CHECK (gender_code in ('F','M'))
);

MERGE INTO adm.d_weight_category trgt
USING (
     SELECT DISTINCT pl.gender AS gender,
                     pl.federation_name AS federation,
                     pl.meet_id AS meet_id,
                     pl.weight_class_name AS weight_class_name
      FROM stg.powerlifting pl
     WHERE pl.weight_class_name IS NOT NULL
) src
ON src.weight_class_name = trgt.weight_class_name
AND src.gender = trgt.gender_code
WHEN NOT MATCHED THEN INSERT
    (meet_id, federation_name, gender_code, weight_class_name)
VALUES
    (src.meet_id, src.federation, src.gender, src.weight_class_name)
;

DROP TABLE IF EXISTS adm.d_division;
CREATE TABLE adm.d_division (
    division_pk INT NOT NULL IDENTITY,
    meet_id INT NOT NULL,
    division_name VARCHAR(50) NOT NULL
);

MERGE INTO adm.d_division trgt
USING (
    SELECT DISTINCT
           meet_id AS meet_id,
           division_name AS division_name
      FROM stg.powerlifting pl
     WHERE division_name IS NOT NULL
) src
ON src.meet_id = trgt.meet_id
AND src.division_name = trgt.division_name
WHEN NOT MATCHED THEN INSERT
(meet_id, division_name)
VALUES
(src.meet_id, src.division_name)
;

DROP TABLE IF EXISTS adm.d_power_lifter;
CREATE TABLE adm.d_power_lifter (
    power_lifter_pk INT NOT NULL IDENTITY,
    full_name VARCHAR(60) NOT NULL,
    gender_code CHAR NOT NULL,
    weight DECIMAL(6, 2) NOT NULL,
    birth_year INT NOT NULL
);

MERGE INTO adm.d_power_lifter trgt
USING (
    SELECT DISTINCT
           pl.full_name AS full_name,
           pl.gender AS gender,
           ISNULL(pl.weight, 0) AS weight,
           pl.birth_year AS birth_year
      FROM stg.powerlifting pl
) src
ON src.full_name = trgt.full_name
AND src.birth_year = trgt.birth_year
AND src.gender = trgt.gender_code
WHEN NOT MATCHED THEN INSERT
(full_name, gender_code, weight, birth_year) VALUES
(src.full_name, src.gender, src.weight, src.birth_year)
;

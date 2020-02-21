DROP DATABASE IF EXISTS warehouse;
CREATE DATABASE warehouse;

USE warehouse;

CREATE SCHEMA stg;
CREATE SCHEMA adm;

DROP TABLE IF EXISTS adm.d_meet;
CREATE TABLE adm.d_meet
(
    meet_pk      INT          NOT NULL IDENTITY,
    meet_id      INT          NOT NULL UNIQUE,
    meet_name    VARCHAR(256) NOT NULL,
    meet_date    DATE         NOT NULL,
    country_name VARCHAR(100)      NOT NULL,
    state_name   VARCHAR(10)     NOT NULL,
    city_name    VARCHAR(100)     NOT NULL
);

MERGE INTO adm.d_meet trgt
USING (
    SELECT DISTINCT MeetID                     AS meet_id,
                    MeetName                   AS meet_name,
                    CONVERT(DATE, [Date])      AS meet_date,
                    ISNULL(MeetCountry, 'N/A') AS country_name,
                    ISNULL(MeetState, 'N/A')   AS state_name,
                    ISNULL(MeetTown, 'N/A')    AS city_name
    FROM stg.meets
) src
ON src.meet_id = trgt.meet_id
WHEN MATCHED THEN
    UPDATE
    SET trgt.city_name    = src.city_name,
        trgt.state_name   = src.state_name,
        trgt.country_name = src.country_name,
        trgt.meet_date    = src.meet_date
WHEN NOT MATCHED THEN
    INSERT
        (meet_id, meet_name, meet_date, country_name, state_name, city_name)
    VALUES (meet_id, meet_name, meet_date, country_name, state_name, city_name);


DROP TABLE IF EXISTS adm.d_weight_category;
CREATE TABLE adm.d_weight_category (
    category_pk INT NOT NULL IDENTITY,
    meet_id INT NOT NULL,
    federation VARCHAR(30) NOT NULL,
    gender CHAR NOT NULL,
    weight_class VARCHAR(6) NOT NULL,
    CONSTRAINT genders CHECK (gender in ('F','M'))
);

MERGE INTO adm.d_weight_category trgt
USING (
     SELECT DISTINCT Sex AS gender,
                     Federation AS federation,
                     m.MeetID AS meet_id,
                     WeightClassKg AS weight_class
      FROM stg.openpowerlifting opl
      JOIN stg.meets m
        ON m.MeetID = opl.MeetID
     WHERE WeightClassKg IS NOT NULL
) src
ON src.weight_class = trgt.weight_class
AND src.gender = trgt.gender
WHEN NOT MATCHED THEN INSERT
    (meet_id, federation, gender, weight_class)
VALUES
    (src.meet_id, src.federation, src.gender, src.weight_class)
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
           MeetID AS meet_id,
           Division AS division_name
      FROM stg.openpowerlifting opl
     WHERE Division IS NOT NULL
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
    gender CHAR NOT NULL,
    weight DECIMAL(6, 2) NOT NULL,
    birth_year INT NOT NULL
);

MERGE INTO adm.d_power_lifter trgt
USING (
    SELECT DISTINCT
           Name AS full_name,
           Sex AS gender,
           ISNULL(BodyweightKg, 0) AS weight,
           IIF(Age IS NULL, YEAR(CONVERT(DATE, '1900-01-01')), YEAR(DATEADD(YEAR, -Age, Date))) AS birth_year
      FROM stg.openpowerlifting opl
      JOIN stg.meets m
        ON m.MeetID = opl.MeetID
) src
ON src.full_name = trgt.full_name
AND src.birth_year = trgt.birth_year
AND src.gender = trgt.gender
WHEN NOT MATCHED THEN INSERT
(full_name, gender, weight, birth_year) VALUES
(src.full_name, src.gender, src.weight, src.birth_year)
;

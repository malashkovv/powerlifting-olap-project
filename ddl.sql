DROP DATABASE IF EXISTS warehouse;
CREATE DATABASE warehouse;

USE warehouse;

CREATE SCHEMA stg;
CREATE SCHEMA adm;

-- SELECT * FROM stg.meets;

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

SELECT Name
FROM stg.openpowerlifting
GROUP BY Name
having count(distinct Sex) > 1
order by count(*) desc
;

SELECT Name AS power_lifter_name,
       Sex AS power_lifter_sex,
       MIN(m.Date) AS min_date,
       MAX(m.Date) AS max_date
  FROM stg.openpowerlifting opl
  JOIN stg.meets m
    ON m.MeetID = opl.MeetID
where Name = 'Alex Smith'
GROUP BY Name, Sex
;

SELECT DISTINCT
       Name AS full_name,
       Sex AS gender,
       Date AS effective_date,
       ISNULL(BodyweightKg, 0) AS weight,
--        Age,
       Date,
       IIF(Age IS NULL, YEAR(CONVERT(DATE, '1900-01-01')), YEAR(DATEADD(YEAR, -Age, Date))) AS birth_year
  FROM stg.openpowerlifting opl
  JOIN stg.meets m
    ON m.MeetID = opl.MeetID
where Name = 'Alex Smith'
-- order by Date
;

SELECT Federation, count(*)
  FROM stg.openpowerlifting opl
  JOIN stg.meets m
    ON m.MeetID = opl.MeetID
group by Federation
;

DROP TABLE IF EXISTS adm.d_weight_category;
CREATE TABLE adm.d_weight_category (
    category_pk INT NOT NULL IDENTITY,
--     effective_date DATE NOT NULL,
    category_type VARCHAR(12) NOT NULL,
    gender CHAR NOT NULL,
    weight_class VARCHAR(6) NOT NULL,
    CONSTRAINT category_types CHECK (category_type in ('IPF','STANDARD','NONSTANDARD')),
    CONSTRAINT genders CHECK (gender in ('F','M'))
);

INSERT INTO adm.d_weight_category
(category_type, gender, weight_class)
VALUES ('IPF', 'M', '53'),
       ('IPF', 'M', '59'),
       ('IPF', 'M', '66'),
       ('IPF', 'M', '74'),
       ('IPF', 'M', '83'),
       ('IPF', 'M', '93'),
       ('IPF', 'M', '105'),
       ('IPF', 'M', '120'),
       ('IPF', 'M', '120+'),
       ('IPF', 'F', '43'),
       ('IPF', 'F', '47'),
       ('IPF', 'F', '52'),
       ('IPF', 'F', '57'),
       ('IPF', 'F', '63'),
       ('IPF', 'F', '72'),
       ('IPF', 'F', '84'),
       ('IPF', 'F', '84+'),
       ('STANDARD', 'M', '52'),
       ('STANDARD', 'M', '56'),
       ('STANDARD', 'M', '60'),
       ('STANDARD', 'M', '67.5'),
       ('STANDARD', 'M', '75'),
       ('STANDARD', 'M', '82.5'),
       ('STANDARD', 'M', '90'),
       ('STANDARD', 'M', '100'),
       ('STANDARD', 'M', '110'),
       ('STANDARD', 'M', '125'),
       ('STANDARD', 'M', '140'),
       ('STANDARD', 'M', '140+'),
       ('STANDARD', 'M', 'N/A'),
       ('STANDARD', 'F', '44'),
       ('STANDARD', 'F', '48'),
       ('STANDARD', 'F', '52'),
       ('STANDARD', 'F', '56'),
       ('STANDARD', 'F', '60'),
       ('STANDARD', 'F', '67.5'),
       ('STANDARD', 'F', '75'),
       ('STANDARD', 'F', '82.5'),
       ('STANDARD', 'F', '90'),
       ('STANDARD', 'F', '90+'),
       ('STANDARD', 'F', 'N/A')
;

MERGE INTO adm.d_weight_category trgt
USING (
     SELECT DISTINCT Sex AS gender,
                     ISNULL(WeightClassKg, 'N/A') AS weight_class
      FROM stg.openpowerlifting opl
      JOIN stg.meets m
        ON m.MeetID = opl.MeetID
) src
ON src.weight_class = trgt.weight_class
AND src.gender = trgt.gender
WHEN NOT MATCHED THEN INSERT
    (category_type, gender, weight_class)
VALUES
    ('NONSTANDARD', src.gender, src.weight_class)
;


SELECT * FROM adm.d_weight_category

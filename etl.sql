USE warehouse;

DROP TABLE IF EXISTS stg.powerlifting;
SELECT Name AS full_name,
       Sex AS gender,
       Age AS age,
       BodyweightKg AS weight,
       IIF(
           Age IS NULL,
           YEAR(CONVERT(DATE, '1900-01-01')),
           YEAR(DATEADD(YEAR, -Age, Date))
       ) AS birth_year,
       Date AS meet_date,
       Place AS meet_place,
       Division AS division_name,
       WeightClassKg AS weight_class_name,
       m.MeetID AS meet_id,
       Federation AS federation_name,
       MeetCountry AS country_name,
       MeetState AS state_code,
       MeetTown AS city_name,
       MeetName AS meet_name,
       Equipment AS equipment_name,
       ISNULL(BestSquatKg, 0) AS best_squat_weight,
       ISNULL(BestBenchKg, 0) AS best_bench_weight,
       ISNULL(BestDeadliftKg, 0) AS best_dead_lift_weight,
       ISNULL(TotalKg, 0) AS total_weight
  INTO stg.powerlifting
  FROM eds.openpowerlifting opl
  JOIN eds.meets m
    ON opl.MeetID = m.MeetID
;

MERGE INTO adm.d_equipment trgt
USING (
SELECT DISTINCT equipment_name
  FROM stg.powerlifting src
 WHERE equipment_name IS NOT NULL
) src
ON src.equipment_name = trgt.equipment_name
WHEN NOT MATCHED THEN INSERT
(equipment_name)
VALUES
(src.equipment_name)
;


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
AND src.meet_id = trgt.meet_id
AND src.federation = trgt.federation_name
WHEN NOT MATCHED THEN INSERT
    (meet_id, federation_name, gender_code, weight_class_name)
VALUES
    (src.meet_id, src.federation, src.gender, src.weight_class_name)
;

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
AND src.weight = trgt.weight
WHEN NOT MATCHED THEN INSERT
(full_name, gender_code, weight, birth_year) VALUES
(src.full_name, src.gender, src.weight, src.birth_year)
;

INSERT INTO adm.f_power_lifting_event
SELECT s.meet_date AS event_date,
       dpl.power_lifter_pk,
       dm.meet_pk,
       de.equipment_pk,
       dwc.category_pk,
       dd.division_pk,
       s.best_squat_weight,
       s.best_bench_weight,
       s.best_dead_lift_weight,
       s.total_weight
  FROM stg.powerlifting s
  JOIN adm.d_power_lifter dpl
    ON dpl.full_name = s.full_name
   AND dpl.birth_year = s.birth_year
   AND dpl.gender_code = s.gender
   AND dpl.weight = s.weight
  JOIN adm.d_division dd
    ON dd.division_name = s.division_name
   AND dd.meet_id = s.meet_id
  JOIN adm.d_weight_category dwc
    ON dwc.weight_class_name = s.weight_class_name
   AND dwc.gender_code = s.gender
   AND dwc.federation_name = s.federation_name
   AND dwc.meet_id = s.meet_id
  JOIN adm.d_meet dm
    ON dm.meet_id = s.meet_id
  JOIN adm.d_equipment de
    ON de.equipment_name = s.equipment_name
;
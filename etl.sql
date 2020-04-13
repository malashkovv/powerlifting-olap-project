USE warehouse;

DROP TABLE IF EXISTS stg.powerlifting;
SELECT Name AS full_name,
       Sex AS gender_code,
       Age AS age,
       CONVERT(DECIMAL(6, 2), ISNULL(BodyweightKg, 0)) AS weight,
       IIF(
           Age IS NULL,
           YEAR(CONVERT(DATE, '1900-01-01')),
           YEAR(DATEADD(YEAR, -Age, Date))
       ) AS birth_year,
       CONVERT(DATE, Date) AS meet_date,
       ISNULL(Division, 'N/A') AS division_name,
       CASE
            WHEN ISNULL(Division, 'N/A') LIKE '%Mst%'
                     OR ISNULL(Division, 'N/A') LIKE '%Master%' THEN 'Master'
            WHEN ISNULL(Division, 'N/A') LIKE '%Teen%' THEN 'Teen'
            WHEN ISNULL(Division, 'N/A') LIKE '%Open%' THEN 'Open'
            WHEN ISNULL(Division, 'N/A') LIKE '%Junior%' THEN 'Junior'
            ELSE 'N/A'
       END AS normalised_division_name,
       ISNULL(WeightClassKg, 'N/A') AS weight_class_name,
       m.MeetID AS meet_id,
       Federation AS federation_name,
       ISNULL(MeetCountry, 'N/A') AS country_name,
       ISNULL(MeetState, 'N/A') AS state_code,
       ISNULL(MeetTown, 'N/A') AS city_name,
       MeetName AS meet_name,
       Equipment AS equipment_name,
       IIF(BestSquatKg < 0, 'N', 'Y') AS squat_attempt_success,
       ISNULL(ABS(BestSquatKg), 0) AS best_squat_weight,
       ISNULL(ABS(Squat4Kg), 0) AS squat_4th_attempt_weight,
       IIF(BestBenchKg < 0, 'N', 'Y') AS bench_attempt_success,
       ISNULL(ABS(BestBenchKg), 0) AS best_bench_weight,
       ISNULL(ABS(Bench4Kg), 0) AS bench_4th_attempt_weight,
       IIF(BestDeadliftKg < 0, 'N', 'Y') AS dead_lift_attempt_success,
       ISNULL(ABS(BestDeadliftKg), 0) AS best_dead_lift_weight,
       ISNULL(ABS(Deadlift4Kg), 0) AS dead_lift_4th_attempt_weight,
       ISNULL(TotalKg, 0) AS total_weight,
       ISNULL(Wilks, -1) AS wilks_coefficient,
       ISNULL(Place, 'N/A') AS place
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
                    pl.meet_date                   AS meet_date,
                    pl.country_name                AS country_name,
                    state_code                     AS state_code,
                    pl.city_name                   AS city_name
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
     SELECT DISTINCT pl.gender_code,
                     pl.federation_name,
                     pl.meet_id,
                     pl.meet_date,
                     pl.weight_class_name
      FROM stg.powerlifting pl
) src
ON src.weight_class_name = trgt.weight_class_name
AND src.gender_code = trgt.gender_code
AND src.meet_id = trgt.meet_id
AND src.federation_name = trgt.federation_name
WHEN NOT MATCHED THEN INSERT
    (meet_id, meet_date, federation_name, gender_code, weight_class_name)
VALUES
    (src.meet_id, src.meet_date, src.federation_name, src.gender_code, src.weight_class_name)
;

MERGE INTO adm.d_division trgt
USING (
    SELECT DISTINCT
           meet_id,
           meet_date,
           federation_name,
           division_name,
           normalised_division_name
      FROM stg.powerlifting pl
) src
ON src.meet_id = trgt.meet_id
AND src.division_name = trgt.division_name
WHEN NOT MATCHED THEN INSERT
(meet_id, meet_date, federation_name, division_name, normalised_division_name)
VALUES
(src.meet_id, src.meet_date, src.federation_name, src.division_name, src.normalised_division_name)
;

MERGE INTO adm.d_power_lifter trgt
USING (
    SELECT DISTINCT
           pl.full_name AS full_name,
           pl.gender_code AS gender,
           pl.weight AS weight,
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

INSERT INTO adm.f_power_lifting_result
(
    event_date,
    power_lifter_pk,
    meet_pk,
    equipment_pk,
    category_pk,
    division_pk,
    squat_attempt_success,
    best_squat_weight,
    squat_4th_attempt_weight,
    bench_attempt_success,
    best_bench_weight,
    bench_4th_attempt_weight,
    dead_lift_attempt_success,
    best_dead_lift_weight,
    dead_lift_4th_attempt_weight,
    total_weight,
    wilks_coefficient,
    place
)
SELECT s.meet_date AS event_date,
       dpl.power_lifter_pk,
       dm.meet_pk,
       de.equipment_pk,
       dwc.category_pk,
       dd.division_pk,
       s.squat_attempt_success,
       s.best_squat_weight,
       s.squat_4th_attempt_weight,
       s.bench_attempt_success,
       s.best_bench_weight,
       s.bench_4th_attempt_weight,
       s.dead_lift_attempt_success,
       s.best_dead_lift_weight,
       s.dead_lift_4th_attempt_weight,
       s.total_weight,
       s.wilks_coefficient,
       s.place
  FROM stg.powerlifting s
  JOIN adm.d_power_lifter dpl
    ON dpl.full_name = s.full_name
   AND dpl.birth_year = s.birth_year
   AND dpl.gender_code = s.gender_code
   AND dpl.weight = s.weight
  JOIN adm.d_division dd
    ON dd.division_name = s.division_name
   AND dd.meet_id = s.meet_id
  LEFT JOIN adm.d_weight_category dwc
    ON dwc.weight_class_name = s.weight_class_name
   AND dwc.gender_code = s.gender_code
   AND dwc.federation_name = s.federation_name
   AND dwc.meet_id = s.meet_id
  JOIN adm.d_meet dm
    ON dm.meet_id = s.meet_id
  JOIN adm.d_equipment de
    ON de.equipment_name = s.equipment_name
;

SELECT *
  FROM adm.f_power_lifting_result
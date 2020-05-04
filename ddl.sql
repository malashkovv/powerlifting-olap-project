CREATE DATABASE warehouse;

USE warehouse;

CREATE SCHEMA eds;
CREATE SCHEMA stg;
CREATE SCHEMA adm;

DROP TABLE IF EXISTS adm.d_equipment;
CREATE TABLE adm.d_equipment (
    equipment_pk     INT         NOT NULL IDENTITY,
    equipment_name   VARCHAR(50) NOT NULL,
    CONSTRAINT equipment_pk PRIMARY KEY NONCLUSTERED (equipment_pk)
);

DROP TABLE IF EXISTS adm.d_meet;
CREATE TABLE adm.d_meet
(
    meet_pk      INT          NOT NULL IDENTITY,
    meet_id      INT          NOT NULL UNIQUE,
    meet_name    VARCHAR(256) NOT NULL,
    meet_date    DATE         NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    state_code   VARCHAR(10)  NOT NULL,
    city_name    VARCHAR(100) NOT NULL,
    CONSTRAINT meet_pk PRIMARY KEY NONCLUSTERED (meet_pk)
);

DROP TABLE IF EXISTS adm.d_weight_category;
CREATE TABLE adm.d_weight_category (
    category_pk         INT         NOT NULL IDENTITY,
    meet_id             INT         NOT NULL,
    meet_date           DATE        NOT NULL,
    federation_name     VARCHAR(30) NOT NULL,
    gender_code         CHAR        NOT NULL,
    weight_class_name   VARCHAR(6)  NOT NULL,
    CONSTRAINT genders CHECK (gender_code in ('F','M')),
    CONSTRAINT category_pk PRIMARY KEY NONCLUSTERED (category_pk)
);

DROP TABLE IF EXISTS adm.d_division;
CREATE TABLE adm.d_division (
    division_pk              INT         NOT NULL IDENTITY,
    meet_id                  INT         NOT NULL,
    meet_date                DATE        NOT NULL,
    federation_name          VARCHAR(30) NOT NULL,
    division_name            VARCHAR(50) NOT NULL,
    normalised_division_name VARCHAR(6)  NOT NULL,
    CONSTRAINT chk_division_name CHECK (normalised_division_name in ('Master','Open','Teen', 'Junior', 'N/A')),
    CONSTRAINT division_pk PRIMARY KEY NONCLUSTERED (division_pk)
);

DROP TABLE IF EXISTS adm.d_power_lifter;
CREATE TABLE adm.d_power_lifter (
    power_lifter_pk INT           NOT NULL IDENTITY,
    full_name       VARCHAR(60)   NOT NULL,
    gender_code     CHAR          NOT NULL,
    weight          DECIMAL(6, 2) NOT NULL,
    birth_year      INT           NOT NULL,
    CONSTRAINT power_lifter_pk PRIMARY KEY NONCLUSTERED (power_lifter_pk),
);

DROP TABLE IF EXISTS adm.d_date;
CREATE TABLE adm.d_date (
    date_pk INT   NOT NULL IDENTITY,
    date    DATE  NOT NULL,
    month   INT   NOT NUll,
    year    INT   NOT NULL,
    day     INT   NOT NULL,
    CONSTRAINT date_pk PRIMARY KEY NONCLUSTERED (date_pk),
)

DROP TABLE IF EXISTS adm.f_power_lifting_result;
CREATE TABLE adm.f_power_lifting_result (
    date_pk                      INT           NOT NULL,
    power_lifter_pk              INT           NOT NULL,
    meet_pk                      INT           NOT NULL,
    equipment_pk                 INT           NOT NULL,
    category_pk                  INT           NOT NULL,
    division_pk                  INT           NOT NULL,
    squat_attempt_success        CHAR          NOT NULL,
    best_squat_weight            DECIMAL(6, 2) NOT NULL,
    squat_4th_attempt_weight     DECIMAL(6, 2) NOT NULL,
    bench_attempt_success        CHAR          NOT NULL,
    best_bench_weight            DECIMAL(6, 2) NOT NULL,
    bench_4th_attempt_weight     DECIMAL(6, 2) NOT NULL,
    dead_lift_attempt_success    CHAR          NOT NULL,
    best_dead_lift_weight        DECIMAL(6, 2) NOT NULL,
    dead_lift_4th_attempt_weight DECIMAL(6, 2) NOT NULL,
    total_weight                 DECIMAL(6, 2) NOT NULL,
    wilks_coefficient            FLOAT         NOT NULL,
    place                        VARCHAR(3)    NOT NULL,
    CONSTRAINT squat_attempt_success_values CHECK (squat_attempt_success in ('Y','N')),
    CONSTRAINT bench_attempt_success_values CHECK (bench_attempt_success in ('Y','N')),
    CONSTRAINT dead_lift_attempt_success_values CHECK (dead_lift_attempt_success in ('Y','N')),
    CONSTRAINT date_fk_const FOREIGN KEY (date_pk)
        REFERENCES adm.d_date (date_pk),
    CONSTRAINT power_lifter_fk_const FOREIGN KEY (power_lifter_pk)
        REFERENCES adm.d_power_lifter (power_lifter_pk),
    CONSTRAINT meet_pk_const FOREIGN KEY (meet_pk)
        REFERENCES adm.d_meet (meet_pk),
    CONSTRAINT equipment_pk_const FOREIGN KEY (equipment_pk)
        REFERENCES adm.d_equipment (equipment_pk),
    CONSTRAINT category_pk_const FOREIGN KEY (category_pk)
        REFERENCES adm.d_weight_category (category_pk),
    CONSTRAINT division_pk_const FOREIGN KEY (division_pk)
        REFERENCES adm.d_division (division_pk)
);

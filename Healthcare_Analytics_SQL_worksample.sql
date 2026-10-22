/* 
PROJECT: HEALTHCARE PATIENT & ENCOUNTER ANALYTICS
DATA SOURCE: Synthea - Synthetic Healthcare Data
TOOLS: MySQL, Excel, Power BI
OBJECTIVE:
Analyze synthetic patient and encounter data to
evaluate healthcare utilization, data quality,
claim costs, and operational trends.

DATASET:
108 Patients
5,571 Healthcare Encounters
*/

# SECTION 1: DATABASE AND TABLE CREATION
CREATE DATABASE Healthcare_analytics;
USE healthcare_analytics;
CREATE TABLE patients (
    Id VARCHAR(50) PRIMARY KEY,
    BIRTHDATE DATE,
    DEATHDATE VARCHAR(20),
    SSN VARCHAR(20),
    DRIVERS VARCHAR(30),
    PASSPORT VARCHAR(30),
    PREFIX VARCHAR(10),
    FIRST VARCHAR(100),
    MIDDLE VARCHAR(100),
    LAST VARCHAR(100),
    SUFFIX VARCHAR(20),
    MAIDEN VARCHAR(100),
    MARITAL VARCHAR(10),
    RACE VARCHAR(50),
    ETHNICITY VARCHAR(50),
    GENDER VARCHAR(10),
    BIRTHPLACE VARCHAR(150),
    ADDRESS VARCHAR(200),
    CITY VARCHAR(100),
    STATE VARCHAR(100),
    COUNTY VARCHAR(100),
    FIPS VARCHAR(20),
    ZIP VARCHAR(20),
    LAT DECIMAL(12,8),
    LON DECIMAL(12,8),
    HEALTHCARE_EXPENSES DECIMAL(15,2),
    HEALTHCARE_COVERAGE DECIMAL(15,2),
    INCOME DECIMAL(15,2)
);
# ENCOUNTERS TABLE CREATION
CREATE TABLE encounters (
    Id VARCHAR(50) PRIMARY KEY,
    START VARCHAR(50),
    STOP VARCHAR(50),
    PATIENT VARCHAR(50),
    ORGANIZATION VARCHAR(50),
    PROVIDER VARCHAR(50),
    PAYER VARCHAR(50),
    ENCOUNTERCLASS VARCHAR(50),
    CODE VARCHAR(50),
    DESCRIPTION VARCHAR(255),
    BASE_ENCOUNTER_COST DECIMAL(15,2),
    TOTAL_CLAIM_COST DECIMAL(15,2),
    PAYER_COVERAGE DECIMAL(15,2),
    REASONCODE VARCHAR(50),
    REASONDESCRIPTION VARCHAR(255)
);
/* DATA IMPORT WORKFLOW
Data Source: Synthea Synthetic Healthcare Data
Import Method: MySQL Workbench Table Data Import Wizard
Execution Order:
1. Create the database and tables in Section 1.
2. Import patients.csv and encounters.csv using the
   MySQL Workbench Table Data Import Wizard.
3. Run the cleaning and analysis queries in Section 2.
4. Do not rerun CREATE TABLE statements or repeat
   the imports on an already populated database.
   
Source Files:
 1. patients.csv
 2. encounters.csv
 
Expected records:
 patients: 108
 encounters: 5,571
*/

#SECTION 2: DATA CLEANING AND VALIDATION
-- DEATHDATE CLEANING
-- Run after importing patients.csv.

SET SQL_SAFE_UPDATES = 0;

UPDATE patients
SET DEATHDATE = NULL
WHERE DEATHDATE = '';

ALTER TABLE patients
MODIFY DEATHDATE DATE;

SELECT COUNT(*) AS total_patients
FROM patients;
SELECT
    Id,
    BIRTHDATE,
    DEATHDATE,
    GENDER,
    RACE,
    ETHNICITY,
    CITY,
    STATE
FROM patients
LIMIT 10;


SELECT COUNT(*) AS total_encounters
FROM encounters;
SELECT
    Id,
    START,
    STOP,
    PATIENT,
    ENCOUNTERCLASS,
    DESCRIPTION,
    TOTAL_CLAIM_COST,
    REASONDESCRIPTION
FROM encounters
LIMIT 10;

SET SQL_SAFE_UPDATES = 1;
/* ENCOUNTER TIMESTAMP CLEANING
Convert encounter timestamps to DATETIME
 Validate patient and encounter records
 Analyze encounter utilization and costs
*/
/* Synthea timestamps contain a UTC 'Z' suffix.
   This step removes the suffix and retains the original
   clock time as a MySQL DATETIME; it does not convert time zones.
*/
UPDATE encounters
SET START = REPLACE(REPLACE(START, 'T', ' '), 'Z', ''),
    STOP  = REPLACE(REPLACE(STOP, 'T', ' '), 'Z', '');
ALTER TABLE encounters
MODIFY START DATETIME,
MODIFY STOP DATETIME;
SET SQL_SAFE_UPDATES = 1;
SELECT
    Id,
    START,
    STOP,
    ENCOUNTERCLASS,
    DESCRIPTION
FROM encounters
LIMIT 10;
SELECT COUNT(*) AS total_encounters
FROM encounters;
SELECT
    p.Id AS patient_id,
    p.GENDER,
    p.RACE,
    p.ETHNICITY,
    p.CITY,
    e.START,
    e.ENCOUNTERCLASS,
    e.DESCRIPTION,
    e.TOTAL_CLAIM_COST,
    e.REASONDESCRIPTION
FROM patients p
JOIN encounters e
    ON p.Id = e.PATIENT
LIMIT 20;
SELECT
    p.GENDER,
    COUNT(*) AS total_encounters
FROM patients p
JOIN encounters e
    ON p.Id = e.PATIENT
GROUP BY p.GENDER;
SELECT
    ENCOUNTERCLASS,
    COUNT(*) AS total_encounters
FROM encounters
GROUP BY ENCOUNTERCLASS
ORDER BY total_encounters DESC;
SELECT
    ENCOUNTERCLASS,
    COUNT(*) AS total_encounters,
    ROUND(AVG(TOTAL_CLAIM_COST), 2) AS avg_claim_cost
FROM encounters
GROUP BY ENCOUNTERCLASS
ORDER BY avg_claim_cost DESC;
SELECT
    ENCOUNTERCLASS,
    COUNT(*) AS total_encounters,
    ROUND(SUM(TOTAL_CLAIM_COST), 2) AS total_claim_cost
FROM encounters
GROUP BY ENCOUNTERCLASS
ORDER BY total_claim_cost DESC;

SELECT
    CASE
        WHEN TIMESTAMPDIFF(YEAR, p.BIRTHDATE, e.START) < 18 THEN '0-17'
        WHEN TIMESTAMPDIFF(YEAR, p.BIRTHDATE, e.START) BETWEEN 18 AND 34 THEN '18-34'
        WHEN TIMESTAMPDIFF(YEAR, p.BIRTHDATE, e.START) BETWEEN 35 AND 49 THEN '35-49'
        WHEN TIMESTAMPDIFF(YEAR, p.BIRTHDATE, e.START) BETWEEN 50 AND 64 THEN '50-64'
        ELSE '65+'
    END AS age_group,

    COUNT(*) AS total_encounters,

    ROUND(AVG(e.TOTAL_CLAIM_COST), 2) AS avg_claim_cost,

    ROUND(SUM(e.TOTAL_CLAIM_COST), 2) AS total_claim_cost

FROM patients p
JOIN encounters e
    ON p.Id = e.PATIENT

GROUP BY age_group

ORDER BY FIELD(
    age_group,
    '0-17',
    '18-34',
    '35-49',
    '50-64',
    '65+'
);
SELECT
    YEAR(START) AS encounter_year,
    COUNT(*) AS total_encounters,
    ROUND(SUM(TOTAL_CLAIM_COST), 2) AS total_claim_cost,
    ROUND(AVG(TOTAL_CLAIM_COST), 2) AS avg_claim_cost
FROM encounters
GROUP BY YEAR(START)
ORDER BY encounter_year;
SELECT
    REASONDESCRIPTION,
    COUNT(*) AS total_encounters
FROM encounters
WHERE REASONDESCRIPTION IS NOT NULL
  AND REASONDESCRIPTION <> ''
GROUP BY REASONDESCRIPTION
ORDER BY total_encounters DESC
LIMIT 10;

# DATA QUALITY VALIDATION: DUPLICATE PATIENT IDS

SELECT
    Id,
    COUNT(*) AS duplicate_count
FROM patients
GROUP BY Id
HAVING COUNT(*) > 1;

#DATA QUALITY VALIDATION: DUPLICATE ENCOUNTER IDS
SELECT
    Id,
    COUNT(*) AS duplicate_count
FROM encounters
GROUP BY Id
HAVING COUNT(*) > 1;

# DATA QUALITY VALIDATION: UNMATCHED PATIENT IDS
SELECT
    COUNT(*) AS unmatched_encounters
FROM encounters e
LEFT JOIN patients p
    ON e.PATIENT = p.Id
WHERE p.Id IS NULL;
SELECT
    e.Id AS encounter_id,
    e.PATIENT AS patient_id,
    e.START AS encounter_start,
    e.ENCOUNTERCLASS AS encounter_type
FROM encounters e
LEFT JOIN patients p
    ON e.PATIENT = p.Id
WHERE p.Id IS NULL;

# DATA QUALITY VALIDATION: MISSING ENCOUNTER REASONS
SELECT
    COUNT(*) AS missing_reason_count
FROM encounters
WHERE REASONDESCRIPTION IS NULL
   OR TRIM(REASONDESCRIPTION) = '';

# DATA QUALITY VALIDATION: INVALID ENCOUNTER DATES
SELECT
    COUNT(*) AS invalid_date_count
FROM encounters
WHERE STOP < START;

# DATA QUALITY VALIDATION: CLAIM COSTS
SELECT
    SUM(CASE WHEN TOTAL_CLAIM_COST IS NULL
        THEN 1 ELSE 0 END) AS missing_costs,

    SUM(CASE WHEN TOTAL_CLAIM_COST < 0
        THEN 1 ELSE 0 END) AS negative_costs,

    SUM(CASE WHEN TOTAL_CLAIM_COST = 0
        THEN 1 ELSE 0 END) AS zero_costs
FROM encounters;
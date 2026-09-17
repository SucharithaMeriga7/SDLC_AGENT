/*=========================================================
Object Name : QA_AEROSPACE_PARTS_PIPELINE
Purpose     : QA acceptance criteria queries
Database    : GEN_AI_POC_SNOWFLAKECOE
Schema      : SDLC_WIZARD
Warehouse   : SNOWFLAKE_LEARNING_WH
SP          : SP_LOAD_AEROSPACE_PARTS_SCD1
AC Range    : AC-001 through AC-010
=========================================================*/

USE DATABASE GEN_AI_POC_SNOWFLAKECOE;
USE SCHEMA SDLC_WIZARD;
USE WAREHOUSE SNOWFLAKE_LEARNING_WH;

-- ============================================================
-- AC-001: TARGET TABLE EXISTS AND IS ACCESSIBLE
-- PASS: Returns row count >= 0 with no errors
-- ============================================================
SELECT
    'AC-001'                                AS acceptance_criteria,
    'TARGET TABLE EXISTS AND IS ACCESSIBLE' AS description,
    COUNT(*)                                AS row_count,
    CASE WHEN COUNT(*) >= 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM AEROSPACE_PARTS_TARGET;

-- ============================================================
-- AC-002: SCHEMA VALIDATION — REQUIRED COLUMNS PRESENT
-- PASS: All 13 expected columns returned
-- ============================================================
SELECT
    'AC-002'                                  AS acceptance_criteria,
    'SCHEMA VALIDATION — REQUIRED COLUMNS'    AS description,
    COUNT(*)                                  AS columns_found,
    CASE WHEN COUNT(*) = 13 THEN 'PASS' ELSE 'FAIL' END AS result
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'SDLC_WIZARD'
  AND TABLE_NAME   = 'AEROSPACE_PARTS_TARGET'
  AND COLUMN_NAME IN (
      'PART_NUMBER','PART_NAME','MANUFACTURER','CATEGORY',
      'WEIGHT_KG','UNIT_COST','LEAD_TIME_DAYS','CERTIFICATION_STATUS',
      'STATUS','RISK_SCORE','UPDATED_AT','DW_INSERT_DATE','DW_UPDATE_DATE'
  );

-- ============================================================
-- AC-003: NO DUPLICATE PART_NUMBER IN TARGET
-- PASS: duplicate_count = 0
-- ============================================================
SELECT
    'AC-003'                              AS acceptance_criteria,
    'NO DUPLICATE PART_NUMBER IN TARGET'  AS description,
    COUNT(*)                              AS duplicate_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
    SELECT PART_NUMBER
    FROM AEROSPACE_PARTS_TARGET
    GROUP BY PART_NUMBER
    HAVING COUNT(*) > 1
);

-- ============================================================
-- AC-004: MANUFACTURER IS UPPERCASED
-- PASS: non_upper_count = 0
-- ============================================================
SELECT
    'AC-004'                    AS acceptance_criteria,
    'MANUFACTURER IS UPPERCASED' AS description,
    COUNT(*)                    AS non_upper_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM AEROSPACE_PARTS_TARGET
WHERE MANUFACTURER <> UPPER(MANUFACTURER);

-- ============================================================
-- AC-005: WEIGHT_KG NULL FOR ZERO OR NEGATIVE SOURCE VALUES
-- PASS: invalid_weight_count = 0
-- ============================================================
SELECT
    'AC-005'                                        AS acceptance_criteria,
    'WEIGHT_KG NULL FOR ZERO/NEGATIVE SOURCE VALUES' AS description,
    COUNT(*)                                        AS invalid_weight_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM AEROSPACE_PARTS_TARGET tgt
JOIN AEROSPACE_PARTS_SOURCE src ON tgt.PART_NUMBER = src.PART_NUMBER
WHERE src.WEIGHT_KG <= 0
  AND tgt.WEIGHT_KG IS NOT NULL;

-- ============================================================
-- AC-006: RISK_SCORE DERIVATION IS CORRECT
-- PASS: invalid_risk_count = 0
-- ============================================================
SELECT
    'AC-006'                          AS acceptance_criteria,
    'RISK_SCORE DERIVATION IS CORRECT' AS description,
    COUNT(*)                          AS invalid_risk_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM AEROSPACE_PARTS_TARGET
WHERE RISK_SCORE <> CASE
    WHEN CERTIFICATION_STATUS = 'Pending' AND LEAD_TIME_DAYS > 90  THEN 'High Risk'
    WHEN CERTIFICATION_STATUS = 'Pending' OR  LEAD_TIME_DAYS > 120 THEN 'Medium Risk'
    WHEN CERTIFICATION_STATUS IN ('FAA','EASA','Dual')
         AND LEAD_TIME_DAYS <= 90                                   THEN 'Low Risk'
    ELSE 'Medium Risk'

-- ============================================================
-- AC-007: SOFT DELETE — ABSENT SOURCE RECORDS DECOMMISSIONED
-- PASS: undecommissioned_count = 0
-- ============================================================
SELECT
    'AC-007'                                          AS acceptance_criteria,
    'SOFT DELETE — ABSENT RECORDS ARE DECOMMISSIONED' AS description,
    COUNT(*)                                          AS undecommissioned_
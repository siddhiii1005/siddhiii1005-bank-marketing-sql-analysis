-- =====================================================================
-- Bank Marketing Campaign Analysis | 01: Data Exploration
-- Dataset: UCI Bank Marketing (bank-additional-full), 41,188 contacts
-- Engine: SQLite (syntax portable to PostgreSQL/MySQL with minor edits)
-- =====================================================================

-- Q1. How big is the dataset and what is the baseline conversion rate?
SELECT
    COUNT(*)                                          AS total_contacts,
    SUM(y = 'yes')                                    AS conversions,
    ROUND(100.0 * SUM(y = 'yes') / COUNT(*), 2)       AS baseline_conv_rate_pct
FROM bank_marketing;
-- Result: 41,188 contacts | 4,640 conversions | 11.27% baseline

-- Q2. How much calling effort does the campaign actually spend?
-- (each row stores `campaign` = number of dial attempts for that client)
SELECT
    SUM(campaign)                                     AS total_dial_attempts,
    ROUND(AVG(campaign), 2)                           AS avg_attempts_per_client,
    MAX(campaign)                                     AS max_attempts_single_client
FROM bank_marketing;
-- Result: 105,754 total dials | 2.57 avg | one client was called 56 times(!)

-- Q3. Data quality check: unknown values by column
SELECT
    SUM(job = 'unknown')        AS unknown_job,
    SUM(marital = 'unknown')    AS unknown_marital,
    SUM(education = 'unknown')  AS unknown_education,
    SUM("default" = 'unknown')  AS unknown_default
FROM bank_marketing;

-- =====================================================================
-- Bank Marketing Campaign Analysis | 02: Who Actually Converts?
-- Techniques: GROUP BY aggregation, CASE bucketing, window functions
-- =====================================================================

-- Q4. Conversion rate by occupation, ranked (window function)
SELECT
    job,
    COUNT(*)                                          AS contacts,
    SUM(y = 'yes')                                    AS conversions,
    ROUND(100.0 * SUM(y = 'yes') / COUNT(*), 1)       AS conv_rate_pct,
    RANK() OVER (ORDER BY 1.0 * SUM(y='yes') / COUNT(*) DESC) AS rank_by_conv
FROM bank_marketing
GROUP BY job
ORDER BY conv_rate_pct DESC;
-- Finding: students (31.4%) and retirees (25.2%) convert at 2-3x the
-- 11.3% average; blue-collar (6.9%) converts worst despite 9,254 calls.

-- Q5. Conversion by age band (CASE bucketing)
SELECT
    CASE
        WHEN age < 25 THEN 'a) under 25'
        WHEN age < 35 THEN 'b) 25-34'
        WHEN age < 50 THEN 'c) 35-49'
        WHEN age < 60 THEN 'd) 50-59'
        ELSE               'e) 60+'
    END                                               AS age_band,
    COUNT(*)                                          AS contacts,
    ROUND(100.0 * SUM(y = 'yes') / COUNT(*), 1)       AS conv_rate_pct
FROM bank_marketing
GROUP BY age_band
ORDER BY age_band;
-- Finding: 60+ converts at 39.6% and under-25 at 24.0% — yet 78% of all
-- calls went to the 25-59 middle, the worst-performing range.

-- Q6. History is the strongest signal: prior campaign outcome
SELECT
    poutcome                                          AS prior_outcome,
    COUNT(*)                                          AS contacts,
    ROUND(100.0 * SUM(y = 'yes') / COUNT(*), 1)       AS conv_rate_pct
FROM bank_marketing
GROUP BY poutcome
ORDER BY conv_rate_pct DESC;
-- Finding: clients who said yes before convert at 65.1% — 5.8x baseline.

-- Q7. Do repeat dial attempts pay off? (diminishing returns)
SELECT
    CASE
        WHEN campaign = 1  THEN 'a) 1 attempt'
        WHEN campaign <= 3 THEN 'b) 2-3 attempts'
        WHEN campaign <= 5 THEN 'c) 4-5 attempts'
        ELSE                    'd) 6+ attempts'
    END                                               AS attempts_bucket,
    COUNT(*)                                          AS clients,
    ROUND(100.0 * SUM(y = 'yes') / COUNT(*), 1)       AS conv_rate_pct
FROM bank_marketing
GROUP BY attempts_bucket
ORDER BY attempts_bucket;
-- Finding: conversion decays 13.0% -> 11.2% -> 8.7% -> 5.5% as attempts
-- pile up. Persistence past 3 calls barely pays.

-- Q8. Wasted effort quantified: dials beyond the 3rd attempt
SELECT
    SUM(MAX(campaign - 3, 0))                              AS dials_beyond_3rd,
    SUM(campaign)                                          AS total_dials,
    ROUND(100.0 * SUM(MAX(campaign - 3, 0)) / SUM(campaign), 1)
                                                           AS pct_of_effort,
    SUM(CASE WHEN campaign > 3 AND y = 'yes' THEN 1 END)   AS conversions_won_after_3rd
FROM bank_marketing;
-- Finding: 28,044 dials (26.5% of ALL calling effort) were 4th+ attempts,
-- producing only 555 conversions (12% of the total).
-- NOTE: in PostgreSQL use GREATEST(campaign - 3, 0) instead of MAX(...).

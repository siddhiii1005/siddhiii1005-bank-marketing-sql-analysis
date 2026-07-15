-- =====================================================================
-- Bank Marketing Campaign Analysis | 03: The Targeting Strategy
-- Techniques: CTEs, CASE scoring, cumulative window functions
-- Business question: if we can't call everyone, who do we call first?
-- =====================================================================

-- Q9. Score every client into a priority tier, then measure each tier
WITH scored AS (
    SELECT *,
        CASE
            WHEN poutcome = 'success'                        THEN '1: Prior converters'
            WHEN age >= 60 OR job IN ('student', 'retired')  THEN '2: Students, retired & 60+'
            WHEN poutcome = 'failure'                        THEN '3: Warm (contacted before)'
            ELSE                                                  '4: Cold mass market'
        END AS tier
    FROM bank_marketing
),
tier_stats AS (
    SELECT
        tier,
        COUNT(*)                                        AS contacts,
        SUM(y = 'yes')                                  AS conversions,
        ROUND(100.0 * SUM(y = 'yes') / COUNT(*), 1)     AS conv_rate_pct
    FROM scored
    GROUP BY tier
)
SELECT
    tier, contacts, conversions, conv_rate_pct,
    -- cumulative share of calls made and conversions captured (window fns)
    ROUND(100.0 * SUM(contacts)    OVER (ORDER BY tier)
                / SUM(contacts)    OVER (), 1)          AS cum_pct_of_calls,
    ROUND(100.0 * SUM(conversions) OVER (ORDER BY tier)
                / SUM(conversions) OVER (), 1)          AS cum_pct_of_conversions
FROM tier_stats
ORDER BY tier;
-- =====================================================================
-- RESULT (the money table):
--   Tier 1  |  1,373 calls | 65.1% conv |  3.3% of calls -> 19.3% of conversions
--   Tier 2  |  2,655 calls | 22.4% conv |  9.8% of calls -> 32.1% of conversions
--   Tier 3  |  3,784 calls | 12.3% conv | 19.0% of calls -> 42.1% of conversions
--   Tier 4  | 33,376 calls |  8.1% conv |  100% of calls -> 100%  of conversions
--
-- BUSINESS RECOMMENDATION:
--   1) Call tiers 1-3 first: 19% of the call list captures 42% of all
--      conversions at a 25.0% conversion rate (2.2x the campaign average).
--   2) Cap every client at 3 attempts: eliminates 26.5% of total dial
--      effort while preserving 88% of conversions.
--   Combined: materially lower cost per acquisition with a fraction of
--   the calling budget.
-- =====================================================================

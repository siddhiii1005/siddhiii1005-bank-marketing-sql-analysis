# Bank Marketing Campaign: SQL Segmentation Analysis

Who should the bank call first, and who should it stop calling?

This project analyzes 41,188 telemarketing contacts from a Portuguese bank's term deposit campaign using SQL. Rather than jumping straight to a prediction model, I approached it the way an analyst on the marketing team would: score the client base into priority tiers, measure the wasted effort, and give the campaign manager a call strategy backed by numbers.

The result: 19% of the call list captures 42% of all conversions, and capping repeat calls at 3 attempts removes 26.5% of total dialing effort while keeping 88% of the wins.

Tools used: SQL (SQLite), CTEs, window functions, CASE scoring, Python for data loading, Tableau for the dashboard.

## Business Context

The bank ran phone campaigns between 2008 and 2010 selling term deposits. The raw numbers show a brute force operation:

- 105,754 dial attempts across 41,188 clients produced 4,640 conversions, a rate of 11.27%
- Clients were called 2.57 times on average, and one client was called 56 times
- Calls were spread across all segments with no visible prioritization

Since call center time is the main cost of a campaign like this, the analysis set out to answer three questions:

1. Who converts? Which client segments say yes at rates far above the 11.3% average?
2. What is wasted? How much dialing effort produces almost nothing?
3. What should change? Can we define a concrete calling policy and quantify its impact?

## Methodology

All analysis is written in SQL and runs against a local SQLite database. The queries are portable to PostgreSQL or MySQL, and dialect differences are noted in the comments.

| Step | File | What it does |
|------|------|--------------|
| 1. Load | `scripts/load_data.py` | Loads the CSV into SQLite in one command |
| 2. Explore | `sql/01_exploration.sql` | Baseline conversion rate, effort audit, data quality checks |
| 3. Segment | `sql/02_segment_analysis.sql` | Conversion by occupation, age band, campaign history and attempt count, using GROUP BY, CASE bucketing and RANK() |
| 4. Strategize | `sql/03_targeting_strategy.sql` | A CTE based scoring model that assigns every client to a priority tier, then cumulative window functions to measure calls made against conversions captured |

The core of the project is the tier model. I kept it deliberately simple so a marketing team could actually put it into practice:

```sql
CASE
    WHEN poutcome = 'success'                        THEN '1: Prior converters'
    WHEN age >= 60 OR job IN ('student', 'retired')  THEN '2: Students, retired & 60+'
    WHEN poutcome = 'failure'                        THEN '3: Warm (contacted before)'
    ELSE                                                  '4: Cold mass market'
END AS tier
```

## Key Findings

**Campaign history is the strongest signal in the data.** Clients who converted in a previous campaign convert again at 65.1%, nearly six times the average. Even clients who previously said no convert at 14.2%, better than the 8.8% rate of clients who were never contacted before. Despite this, prior converters made up only about 3% of the call list.

**The best demographics were barely called.** Students convert at 31.4%, retirees at 25.2%, and clients aged 60 and above at 39.6%. Blue collar clients convert at 6.9%. Yet 78% of all calls went to the 25 to 59 age range, which is the worst performing part of the base.

**Persistence does not pay.** Conversion decays steadily with each repeat attempt: 13.0% on the first call, 11.2% at 2 to 3 attempts, 8.7% at 4 to 5, and just 5.5% at 6 or more. Dials beyond the third attempt add up to 28,044 calls, which is 26.5% of the campaign's entire effort, and they produced only 12% of conversions.

**A simple tier list concentrates the wins.**

| Priority tier | Clients | Conversion rate | Cumulative: % of calls to % of conversions |
|---|---|---|---|
| 1. Prior converters | 1,373 | 65.1% | 3.3% of calls, 19.3% of conversions |
| 2. Students, retired and 60+ | 2,655 | 22.4% | 9.8% of calls, 32.1% of conversions |
| 3. Warm (contacted before) | 3,784 | 12.3% | 19.0% of calls, 42.1% of conversions |
| 4. Cold mass market | 33,376 | 8.1% | 100% of calls, 100% of conversions |

![Conversion by tier](charts/1_conversion_by_tier.png)
![Cumulative capture](charts/2_cumulative_capture.png)

## Recommendation to the Business

1. Work the list top down. Tiers 1 to 3 hold 19% of clients but 42% of conversions, converting at 25.0% against the campaign average of 11.3%. When capacity is limited, the cold mass market should be called last or moved to a cheaper channel such as email.
2. Cap every client at 3 attempts. This cuts 26.5% of total dialing at the cost of 12% of conversions, and the freed capacity can be redeployed onto fresh tier 1 and tier 2 leads.

The net effect is the same number of conversions with roughly half the calling budget, or a much larger number of conversions from the same team.

## Dashboard

An interactive Tableau dashboard is in progress. It will mirror the four charts in the charts folder: a conversion rate KPI, the tier comparison, the occupation ranking, and the attempt decay curve.

## Project Structure

```
data/
    bank-additional-full.csv    UCI Bank Marketing dataset, 41,188 rows
    README.md                   source and citation
sql/
    01_exploration.sql          baseline rates, effort audit, data quality
    02_segment_analysis.sql     who converts: job, age, history, attempts
    03_targeting_strategy.sql   CTE tier model and cumulative window functions
scripts/
    load_data.py                CSV to SQLite in one command
charts/                         findings visualized with matplotlib and seaborn
```

## How to Reproduce

```bash
pip install pandas
python scripts/load_data.py
sqlite3 bank.db < sql/01_exploration.sql
sqlite3 bank.db < sql/02_segment_analysis.sql
sqlite3 bank.db < sql/03_targeting_strategy.sql
```

## Limitations

A few honest notes on what this analysis can and cannot claim.

The tiers were built from the outcomes of this same campaign, so the capture numbers are retrospective. Before deploying the rules, I would validate them on a holdout period.

The call duration column is deliberately excluded from the strategy. Duration is only known after a call ends, so using it to decide who to call would be data leakage.

Savings are expressed as a share of dial attempts. Turning that into currency requires the bank's internal cost per call, which is not public.

## Dataset and Citation

UCI Machine Learning Repository, Bank Marketing dataset: https://archive.ics.uci.edu/dataset/222/bank+marketing

Moro, S., Cortez, P., and Rita, P. (2014). A Data Driven Approach to Predict the Success of Bank Telemarketing. Decision Support Systems, 62, 22 to 31.

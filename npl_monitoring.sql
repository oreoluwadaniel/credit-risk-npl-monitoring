/*===========================================================
CREDIT RISK & NON-PERFORMING LOAN (NPL)
INTELLIGENCE MONITORING SYSTEM

Business Objective
------------------------------------------------------------
This analysis evaluates the overall health of the lending
portfolio by measuring credit risk exposure, delinquency
levels, portfolio concentration risk, and changes in loan
performance over time.

The goal is to provide an early warning framework that helps
leadership identify emerging risks before they materially
impact portfolio performance.

Business Context
------------------------------------------------------------
Stratavax operates across multiple markets including Nigeria,
the United Kingdom, and the United States and offers a range
of lending products such as:

1. Consumer Loans
2. SME Lending
3. Credit Cards

Leadership requires continuous visibility into portfolio
performance to ensure that credit risks remain within
acceptable limits.

Key Questions Answered
------------------------------------------------------------
1. What percentage of the portfolio is non-performing?
2. Is the NPL ratio improving or deteriorating over time?
3. Which countries contribute the highest credit risk?
4. Which customer segments are most likely to default?
5. Are early delinquency indicators increasing?
6. Are specific loan vintages performing poorly?
7. Is portfolio concentration creating excessive exposure?
8. What changes in portfolio risk require immediate attention?

This workflow follows a credit risk analytics process:

Data Validation -> Deduplication -> Portfolio Monitoring
-> Early Warning Analysis -> Risk Segmentation
-> Concentration Risk Analysis -> Vintage Analysis
-> Trend Monitoring -> Decision Support

===========================================================*/

USE "credit risk";

/*-----------------------------------------------------------
STEP 1: DATA QUALITY VALIDATION

Review the portfolio dataset to validate record volumes,
loan identifiers, and reporting periods before performing
credit risk analysis.
-----------------------------------------------------------*/

SELECT TOP 10 *
FROM loan_panel;

SELECT COUNT(*)
FROM loan_panel;

SELECT *
FROM loan_panel
WHERE loan_id IS NULL;

SELECT
MIN(month_end),
MAX(month_end)
FROM loan_panel;

SELECT DISTINCT days_past_due
FROM loan_panel;

/*-----------------------------------------------------------
STEP 2: DUPLICATE RECORD VALIDATION

Identify duplicate loan records reported within the same
reporting period to ensure accurate portfolio calculations.
-----------------------------------------------------------*/

SELECT
loan_id,
month_end,
COUNT(*)
FROM loan_panel
GROUP BY loan_id, month_end
HAVING COUNT(*) > 1;

/*-----------------------------------------------------------
STEP 2B: DUPLICATE RECORD RESOLUTION

The check above returns real duplicates in this dataset. For
example, loan LOAN000408 has two rows for the 2023-01-31
reporting period, one showing 30 days past due and another
showing 0 days past due. Left unresolved, this kind of
duplicate double counts a loan's exposure in every KPI below
and can quietly shift a delinquency rate in either direction.

Where a loan_id and month_end pair appears more than once, we
keep the row reporting the higher days_past_due value. This is
a deliberate, conservative choice, if two systems disagree on
how delinquent a loan is, the portfolio should reflect the
more cautious reading rather than the more comfortable one.
-----------------------------------------------------------*/

WITH ranked_panel AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY loan_id, month_end
            ORDER BY days_past_due DESC
        ) AS rn
    FROM loan_panel
)
DELETE FROM ranked_panel
WHERE rn > 1;

/*-----------------------------------------------------------
STEP 3: BUILD ANALYTICAL DATA MODEL

Create a consolidated reporting view combining loan
performance, customer characteristics, and lending
information to support portfolio risk monitoring.
-----------------------------------------------------------*/

CREATE VIEW v_portfolio_base AS
SELECT
lp.loan_id,
lp.month_end,
lp.days_past_due,
lp.pd_estimate,
lp.lgd_estimate,
l.loan_amount,
l.origination_date,
c.credit_score,
c.country,
l.tenure_months

FROM loan_panel lp
JOIN loans l
ON lp.loan_id = l.loan_id
JOIN customers c
ON l.customer_id = c.customer_id;

/*-----------------------------------------------------------
KPI 1: NON-PERFORMING LOAN (NPL) RATIO (EXPOSURE WEIGHTED)

Measures the dollar value of the lending portfolio classified
as non-performing (ninety days or more past due) as a share of
total loan exposure.

This is the primary indicator of portfolio health because it
weights risk by how much money is actually at stake, a single
large defaulted loan moves this number more than ten small
ones.
-----------------------------------------------------------*/

SELECT
month_end,
SUM(
CASE
WHEN days_past_due >= 90
THEN loan_amount
ELSE 0
END
) * 1.0 / SUM(loan_amount) AS npl_ratio_exposure

FROM v_portfolio_base
GROUP BY month_end
ORDER BY month_end;

/*-----------------------------------------------------------
KPI 2: EARLY WARNING DELINQUENCY SYSTEM (LOAN COUNT WEIGHTED)

Measures the proportion of loans (by count, not dollar value)
sitting in each delinquency bucket, to provide an early warning
signal separate from the exposure view above.

30 Days Past Due : Early Risk Indicator
60 Days Past Due : Elevated Risk Indicator
90+ Days Past Due : Non-Performing Loan Indicator
-----------------------------------------------------------*/

SELECT
month_end,
SUM(
    CASE
        WHEN days_past_due = 30 THEN 1
        ELSE 0
    END
) * 1.0 / COUNT(*) AS dpd_30_rate,

SUM(
    CASE
        WHEN days_past_due = 60 THEN 1
        ELSE 0
    END
) * 1.0 / COUNT(*) AS dpd_60_rate,

SUM(
    CASE
        WHEN days_past_due >= 90 THEN 1
        ELSE 0
    END
) * 1.0 / COUNT(*) AS npl_rate

FROM v_portfolio_base
GROUP BY month_end
ORDER BY month_end;

/*-----------------------------------------------------------
KPI 3: VINTAGE ANALYSIS

Measures how loans originating in the same month perform over
time, so weak underwriting periods or deteriorating cohorts
show up early.

Loans are grouped by origination month, not by the exact
origination timestamp. The source data stores origination_date
down to the second, so grouping by the raw timestamp would put
almost every loan in its own group of one and defeat the point
of a vintage view entirely.
-----------------------------------------------------------*/

SELECT
DATEFROMPARTS(YEAR(l.origination_date), MONTH(l.origination_date), 1) AS vintage_month,
lp.month_end,
COUNT(*) AS loans,

SUM(
    CASE
        WHEN lp.days_past_due >= 90 THEN 1
        ELSE 0
    END
) * 1.0 / COUNT(*) AS npl_rate

FROM loan_panel lp
JOIN loans l
ON lp.loan_id = l.loan_id

GROUP BY
DATEFROMPARTS(YEAR(l.origination_date), MONTH(l.origination_date), 1),
lp.month_end

ORDER BY
vintage_month,
lp.month_end;

/*-----------------------------------------------------------
KPI 4: CREDIT RISK SEGMENTATION

Groups borrowers according to their credit scores to identify
which segments contribute the greatest portfolio risk.

Prime     : Lower Risk Customers
Mid Tier  : Moderate Risk Customers
Subprime  : Higher Risk Customers
-----------------------------------------------------------*/

SELECT
CASE
    WHEN credit_score >= 700 THEN 'Prime'
    WHEN credit_score >= 600 THEN 'Mid'
    ELSE 'Subprime'
END AS risk_band,

COUNT(*) AS loans,

SUM(
    CASE
        WHEN days_past_due >= 90 THEN 1
        ELSE 0
    END
) * 1.0 / COUNT(*) AS npl_rate

FROM v_portfolio_base

GROUP BY
CASE
    WHEN credit_score >= 700 THEN 'Prime'
    WHEN credit_score >= 600 THEN 'Mid'
    ELSE 'Subprime'
END;

/*-----------------------------------------------------------
KPI 5: PORTFOLIO CONCENTRATION RISK

Measures the concentration of non-performing loans across
countries to identify markets contributing disproportionate
levels of credit risk.
-----------------------------------------------------------*/

SELECT
country,
COUNT(*) AS total_loans,
SUM(
    CASE
        WHEN days_past_due >= 90 THEN 1
        ELSE 0
    END
) AS npl_loans
FROM v_portfolio_base
GROUP BY country
ORDER BY npl_loans DESC;

/*-----------------------------------------------------------
KPI 6: PORTFOLIO TREND MONITORING

Tracks month-over-month changes in the Non-Performing Loan
ratio to identify improving or deteriorating portfolio
performance.

Positive values indicate rising portfolio risk while
negative values indicate improving credit quality.
-----------------------------------------------------------*/

WITH npl_trend AS (
SELECT
    month_end,

    COUNT(
        CASE
            WHEN days_past_due >= 90 THEN 1
        END
    ) * 1.0 / COUNT(*) AS npl_rate

FROM loan_panel
GROUP BY month_end
)
SELECT
month_end,
npl_rate,
npl_rate -
LAG(npl_rate)
OVER (ORDER BY month_end)
AS change_in_npl
FROM npl_trend;

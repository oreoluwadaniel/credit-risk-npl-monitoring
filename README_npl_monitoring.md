# Credit risk and non-performing loan monitoring

SQL project analyzing a multi-market consumer lending portfolio to measure how much of it is going bad, how fast, and where.

## Business problem

Picture a lender operating consumer loans, SME loans, and credit cards across several countries. Every month, leadership needs one honest answer to a hard question: is the portfolio getting healthier or riskier?

That sounds simple until you try to answer it properly. A portfolio can look stable in total while one country or one underwriting quarter is quietly falling apart underneath it. A rising delinquency count doesn't always mean rising dollar risk, and a shrinking one doesn't always mean the opposite. Leadership at a lender like this (I've named it Stratavax for this project) needs a way to see past the headline number and catch a deteriorating segment before it shows up as a loss.

This script builds that view. It measures the non-performing loan (NPL) ratio, tracks early delinquency, breaks risk down by credit tier, country, and loan vintage, and shows whether things are trending up or down month over month.

## Data source

The dataset is a synthetic loan portfolio built to mirror how a real lender's data warehouse is structured. It's not scraped or pulled from a real institution, this is representative data designed for portfolio and demonstration purposes, but it follows the shape, scale, and messiness of an actual credit risk dataset.

Three tables feed this analysis:

**customers** (1,000 records): customer_id, country, customer_type, annual_income, credit_score, created_at. Customers span five markets, Nigeria, the UK, the US, the UAE, and Singapore, split roughly evenly (190 to 210 customers each).

**loans** (1,000 records): loan_id, customer_id, loan_amount, interest_rate, tenure_months, origination_date. Loan sizes range from a few hundred to just under 20,000, split into small, medium, and large exposure bands.

**loan_panel** (10,000 records): a monthly performance snapshot per loan, with loan_id, month_end, days_past_due, pd_estimate, and lgd_estimate. This is an unbalanced panel, loans join it in the month they originate and are tracked forward from there, so not every loan has a row in every month. The panel runs from January 2023 through at least January 2025.

One thing worth flagging up front: the script's own business narrative describes Stratavax as operating in "Nigeria, the United Kingdom, and the United States." The actual customer data covers five countries, not three, UAE and Singapore are both present in meaningful volume. I've kept the original narrative in the script header for continuity, but the country-level KPI in this analysis reflects all five markets found in the data, not just the three named in the brief.

## Methodology

I worked through this in the order a credit risk analyst actually would, not the order that looks impressive:

1. **Validate the data first.** Row counts, null checks on the primary key, the reporting date range, and the actual distinct values of days_past_due. You don't build KPIs on top of a table you haven't looked at.
2. **Check for duplicates before trusting any aggregate.** A loan reported twice in the same month will quietly inflate every ratio downstream.
3. **Build one clean, reusable view** (`v_portfolio_base`) joining the panel to loan and customer attributes, so every KPI after this point pulls from the same trusted source instead of repeating the same three-way join six times.
4. **Measure the headline NPL ratio two ways**, by dollar exposure and by loan count, because they answer different questions and leadership should see both.
5. **Layer in the diagnostic views**, early delinquency buckets, vintage cohorts, credit tier segmentation, country concentration, and the month-over-month trend, each one narrowing in on a different way the portfolio could be quietly deteriorating.

## Analysis and error check

I went through this script line by line against the real data rather than assuming it was clean, and found three issues worth fixing.

**A broken query.** KPI 3 (vintage analysis) had a stray set of triple backticks sitting in the middle of the SELECT statement, the kind of thing that sneaks in when SQL gets copied out of a markdown file. It would have thrown a straight syntax error the moment anyone tried to run it. Removed.

**A vintage analysis that couldn't actually work.** The original query grouped loans by `origination_date`, but that column stores a full timestamp down to the second. Grouping by it doesn't create cohorts of loans that originated around the same time, it creates one group per loan, because no two loans share the exact same second. I changed the grouping key to the calendar month of origination, so loans that started in, say, March 2023 are now actually compared against each other as a vintage.

**A duplicate the validation step wasn't actually stopping.** Step 2 in the original script checks for duplicate loan_id and month_end combinations, which is good practice, but it only reports them. It never removes them. I ran that check against the real data and it isn't hypothetical: loan LOAN000408 has two rows for the January 2023 reporting period, one showing 30 days past due, the other showing 0 days past due with a prev_dpd of 30. Left in place, that duplicate gets counted twice in every KPI that touches that month, inflating the exposure denominator and nudging the 30-day delinquency rate. I added a deduplication step right after the check that keeps the row reporting the higher days_past_due value for any duplicate pair, on the reasoning that a risk report should default to the more cautious reading when two records disagree, not the more comfortable one.

I also confirmed something that turned out fine: days_past_due in this dataset only ever takes the values 0, 30, 60, or 90. That matters because several KPIs use exact-match CASE logic (`WHEN days_past_due = 30`), which would silently miscategorize any in-between value like 45 or 75 if one existed. It doesn't, so the logic holds, but I wanted to check rather than assume.

## Insight

Working from the raw panel data directly (10,000 loan-month observations across the full history), the portfolio's overall delinquency mix breaks down as: 68.8% current, 16.0% at 30 days past due, 10.7% at 60 days past due, and 4.5% at 90 or more days past due (non-performing).

That last figure is the one that matters most to leadership, and on its own it looks manageable. But it's a count, not a dollar figure, and 4.5% of loans by count isn't the same as 4.5% of the money at risk. That gap between the count-weighted and exposure-weighted view is exactly why the script reports both KPI 1 (exposure weighted) and KPI 2 (count weighted) instead of picking one. A portfolio where the same 4.5% of loans happen to be the largest ones is in a very different position than one where they're the smallest.

## Recommendation

Report both NPL measures side by side every month, not just one blended number, and set a specific trigger: if the exposure-weighted NPL ratio moves meaningfully ahead of the count-weighted one, that's a signal that risk is concentrating in larger loans and probably deserves a closer look at underwriting limits for high-ticket lending. Pair that with the vintage view so any given month's NPL number comes with context on which origination cohort is driving it, a spike from one bad underwriting quarter needs a very different response than a slow, portfolio-wide drift.

## Business impact

Catching a deteriorating vintage or a concentrating risk pocket a month or two earlier than a blended headline number would show it gives collections and underwriting teams a real head start. In lending, the cost of finding out about a bad cohort late isn't just the missed payments, it's the extra months of continuing to originate similar loans before anyone notices the pattern. A monitoring setup that separates exposure from count, and current performance from vintage and geography, is what turns "the NPL ratio went up" into "here's specifically what's driving it and what to do about it."

## What was done

Built a full credit risk monitoring workflow in T-SQL: data validation, duplicate detection and resolution, a reusable analytical view, and six KPIs covering exposure-weighted NPL, count-weighted early warning delinquency, vintage cohort performance, credit tier segmentation, country concentration, and month-over-month trend. Reviewed the original script against the real dataset, found and fixed a broken query, a vintage grouping bug, and an unresolved duplicate-record risk, and documented all three with the actual data that proves them.

## Tools used and how they helped

**T-SQL (SQL Server dialect).** Chosen because it's what the source script was already written in (`SELECT TOP 10` and `CREATE VIEW` syntax confirm the dialect), and because window functions like `LAG()` and conditional aggregation with `CASE` inside `SUM()` are exactly the right tools for month-over-month trend analysis and multi-bucket segmentation without needing a second tool.

**Window functions (`LAG() OVER`)** for the trend KPI, comparing each month's NPL rate to the one before it without a self-join.

**Conditional aggregation (`SUM(CASE WHEN ... THEN ... END)`)** for building multiple delinquency buckets and risk bands in a single pass over the data instead of running six separate queries.

**A reusable view (`v_portfolio_base`)** so every downstream KPI shares one validated, joined source of truth instead of six slightly different versions of the same join.

## Results

A monitoring script that runs clean against the real dataset, catches the exact kind of data quality issue (duplicate records) that quietly distorts credit risk reporting in production systems, and gives leadership two complementary views of portfolio health (by exposure and by count) instead of one number that hides more than it reveals.

## Files in this repository

- `npl_monitoring.sql`, the corrected, documented SQL script
- `loans_sample.csv` (300 of 1,000 loans), `customers_sample.csv` (300 of 1,000 customers), `loan_panel_sample.csv` (500 of 10,000 panel rows), representative samples of the three source tables, kept smaller here for readability. The full dataset is what the figures in this README are based on.

## How to run this

The script targets SQL Server (T-SQL syntax). Load the CSV files into tables named `customers`, `loans`, and `loan_panel` matching the column names shown in the Data Source section above, then run the script top to bottom. Step 1 and Step 2 are read-only validation queries meant to be reviewed before Step 2B runs the actual deduplication. Note that the sample files included here are a subset of the full dataset, so a duplicate check against just the sample may return fewer or no results even though the full data confirmed the issue described below.

> This case study has been folded into a combined portfolio repo: https://github.com/oreoluwadaniel/credit-risk-banking-portfolio. Kept here for history; the combined repo is the current version.

# Enterprise Credit Portfolio Health Monitoring & NPL Intelligence Framework

## Project Overview

Managing credit risk requires more than monitoring today's Non-Performing Loan (NPL) ratio. Portfolio deterioration often begins months before losses become visible through headline metrics.

A lending portfolio may appear healthy at the aggregate level while specific customer segments, loan vintages, or geographic markets quietly deteriorate underneath. Without continuous portfolio monitoring, these emerging risks frequently remain undetected until they materially impact profitability.

This project builds an enterprise-level Credit Portfolio Health Monitoring framework designed to provide early warning indicators of portfolio deterioration across multiple lending products and markets.

The framework enables risk teams to answer critical business questions such as:

> - Is portfolio risk increasing or decreasing over time?
> - Which customer segments are driving portfolio deterioration?
> - Are larger loan exposures becoming riskier than smaller loans?
> - Which loan vintages are performing poorly?
> - Which markets contribute most to portfolio risk?
> - How concentrated is Non-Performing Loan exposure?
> - Where should underwriting and collections teams intervene first?

Rather than focusing solely on current portfolio performance, the objective of this project is to identify where portfolio risk is emerging before it becomes a realized loss.

---

## Business Problem

Traditional credit risk reporting typically focuses on static portfolio metrics such as:

- Non-Performing Loan Ratios
- Delinquency Counts
- Portfolio Exposure
- Collection Performance

While valuable, these metrics provide limited visibility into the underlying drivers of portfolio performance.

Two portfolios may report identical NPL ratios while exhibiting completely different risk characteristics:

- One portfolio may contain large concentrated exposures.
- Another may contain deteriorating loan vintages.
- A third may be experiencing rising early-stage delinquencies across specific markets.

Without segmented portfolio monitoring, these risks remain hidden behind aggregate statistics.

This project addresses that challenge by providing a comprehensive portfolio monitoring framework capable of tracking:

- Portfolio Health
- Credit Risk Concentration
- Early Delinquency Trends
- Vintage Performance
- Geographic Risk Distribution
- Month-over-Month Portfolio Changes

---

## Dataset

This project uses a synthetic lending portfolio consisting of three related tables.

| Table | Description |
|-------|------------|
| customers | Customer demographics, income information and credit scores |
| loans | Loan information including amounts, tenures and origination dates |
| loan_panel | Monthly loan performance observations |

### Portfolio Composition

- 1,000 Customers
- 1,000 Loans
- 10,000 Monthly Loan Observations
- Five International Markets
- Consumer Lending Products
- SME Lending Products
- Credit Card Products

### Countries Included

- Nigeria
- United Kingdom
- United States
- United Arab Emirates
- Singapore

The portfolio spans monthly observations between January 2023 and January 2025.

---

## Project Architecture

```

                   CUSTOMERS
                        |
                        |
                        |
                      LOANS
                        |
                        |
                        |
                   LOAN PANEL
                 (Monthly Performance)
                        |
                        |
                        ↓
                 Data Validation Layer
                (Duplicate Detection)
                        |
                        |
                        ↓
                  Portfolio Base View
                  (v_portfolio_base)
                        |
                        |
                        ↓
                  Portfolio Monitoring
                        |
       ---------------------------------------------------
       |                |                |                |
       ↓                ↓                ↓                ↓
 Exposure NPL      Count NPL        Early Warning      Vintage
   Analysis         Analysis        Delinquencies      Analysis
       |                |                |                |
       ----------------------------------------------------
                        |
                        ↓
                 Credit Tier Analysis
                        |
                        ↓
                 Country Risk Analysis
                        |
                        ↓
                  Month-over-Month Trends
                        |
                        ↓
                 Portfolio Risk Intelligence
                        |
                        ↓
                 Business Recommendations


```

---

## Technologies Used

- SQL Server (T-SQL)
- SQL Views
- Window Functions
- Common Table Expressions (CTEs)
- Conditional Aggregation
- Portfolio Risk Analytics
- Financial Analytics
- Credit Risk Monitoring
- Data Validation Techniques
- Business Intelligence Reporting

---

## Methodology

The framework follows a layered portfolio monitoring approach.

### Data Validation

The dataset was validated for:

- Duplicate observations
- Missing values
- Invalid delinquency classifications
- Reporting date consistency
- Loan-level integrity across reporting periods

### Portfolio Monitoring Framework

A reusable reporting layer (`v_portfolio_base`) was developed to provide a single source of truth for all downstream analyses.

The framework performs:

- Exposure-weighted NPL Analysis
- Count-weighted NPL Analysis
- Early Delinquency Monitoring
- Vintage Cohort Analysis
- Credit Tier Segmentation
- Geographic Risk Analysis
- Portfolio Trend Monitoring

### Early Warning Monitoring

Rather than waiting for loans to become non-performing, the framework monitors:

- 30 Day Delinquencies
- 60 Day Delinquencies
- Portfolio Risk Concentration
- Emerging Vintage Risks
- Month-over-Month Portfolio Changes

This provides risk teams with earlier intervention opportunities before severe delinquency occurs.

---

## KPIs Developed

This project includes:

- Exposure Weighted NPL Ratio
- Count Weighted NPL Ratio
- Early Delinquency Analysis
- Vintage Cohort Performance
- Credit Tier Analysis
- Country-Level Risk Monitoring
- Portfolio Trend Analysis
- Risk Concentration Analysis
- Early Warning Indicators
- Portfolio Health Monitoring

---

## Data Quality Challenges Solved

### Duplicate Monthly Observations

Duplicate loan records were identified within the monthly loan performance panel.

Without validation procedures, duplicated observations can distort:

- NPL Ratios
- Delinquency Rates
- Portfolio Exposure Metrics
- Vintage Analysis

#### Solution

The framework implements:

- Duplicate detection procedures
- Portfolio validation checks
- Record deduplication logic
- Risk-preserving resolution techniques

Where duplicate observations conflict, the framework preserves the higher delinquency value to ensure conservative portfolio risk reporting.

---

### Vintage Analysis Improvements

The original implementation grouped loans using full timestamp values.

#### Solution

Vintage cohorts are now grouped using calendar month classifications, allowing loans originated during the same period to be analyzed collectively.

---

## Key Insights

Portfolio-level analysis revealed:

- 68.8% of loan observations remain Current.
- 16.0% are 30 Days Past Due.
- 10.7% are 60 Days Past Due.
- 4.5% are Non-Performing Loans.

More importantly, the project demonstrates why exposure-weighted and count-weighted portfolio metrics must be monitored simultaneously.

A portfolio where:

> - 4.5% of loans are non-performing by count

is materially different from one where:

> - 4.5% of total loan exposure is non-performing.

Risk concentration matters just as much as portfolio size.

---

## Business Recommendations

- Monitor exposure-weighted and count-weighted NPL ratios simultaneously.
- Implement early warning alerts for rising delinquency trends.
- Monitor portfolio deterioration across loan vintages.
- Continuously track geographic risk concentrations.
- Prioritize segment-level portfolio monitoring over aggregate statistics.

---

## Business Impact

This framework enables lending institutions to:

- Detect portfolio deterioration earlier.
- Monitor concentrated credit exposures.
- Improve collections prioritization.
- Enhance underwriting strategies.
- Identify emerging portfolio risks.
- Improve executive-level portfolio reporting.

Most importantly, it transforms portfolio monitoring from:

> **"What is our NPL ratio?"**

into

> **"Why is portfolio risk changing and where is it coming from?"**

---

## Skills Demonstrated

This project demonstrates proficiency in:

- Advanced SQL
- Portfolio Risk Analytics
- Financial Analytics
- Credit Risk Monitoring
- Data Validation
- Window Functions
- Data Modeling
- Business Intelligence Reporting
- Portfolio Intelligence Framework Design
- Problem Solving

---

## Project Deliverables

- Credit Portfolio Monitoring Framework
- NPL Intelligence Dashboard Logic
- Portfolio Early Warning Indicators
- Vintage Cohort Analysis
- Country-Level Risk Monitoring
- Portfolio Trend Analysis
- Data Quality Validation Checks
- Business Recommendations

---

## Results

The final solution delivers an enterprise-level credit portfolio monitoring framework capable of providing both current-state portfolio assessments and early warning indicators of emerging credit risks.

By combining exposure analysis, delinquency monitoring, vintage analysis, and portfolio trend intelligence, the framework provides:

- Accurate portfolio health monitoring.
- Reliable credit risk reporting.
- Improved visibility into portfolio deterioration.
- Enhanced decision-making for risk and collections teams.
- A scalable foundation for predictive portfolio risk analytics.

---

> **Disclaimer:** This project uses a synthetic lending dataset designed for analytical and educational purposes. The portfolio metrics presented here are intended to demonstrate enterprise credit risk monitoring techniques and should not be interpreted as real-world lending benchmarks.

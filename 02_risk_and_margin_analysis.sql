-- ====================================================================
-- PROJECT: Health Insurance Claim Risk & Margin Analytics
-- STEP 2: Risk Profiling, Claims Concentration & Margin Optimization
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. RISK PROFILING & COMBINED FACTOR ANALYSIS
-- Objective: Evaluate the compound risk impact of smoking status and BMI categories
-- --------------------------------------------------------------------

-- STEP 1.1: DATA DISCOVERY & INTEGRITY CHECK
-- Objective: Verify total record counts and validate distinct categorical values (smoker types).
SELECT
    COUNT (*) AS total_records,
    COUNT (DISTINCT smoker) AS smoker_types
FROM insurance_claims;

-- STEP 1.2: PRE-ANALYSIS DATA PREVIEW
-- Objective: Inspect a sample of the raw dataset to understand record structure and formatting.
SELECT *
FROM insurance_claims
LIMIT 10;

-- STEP 1.3: PORTFOLIO BASELINE METRICS
-- Objective: Establish global benchmarks for total policyholders, portfolio costs, and average claims.
SELECT
    COUNT(*) AS total_policyholders,
    ROUND(AVG(charges), 2) AS global_avg_claim_cost,
    ROUND(SUM(charges), 2) AS total_portfolio_cost,
    ROUND(AVG(bmi), 2) AS global_avg_bmi
FROM insurance_claims;

-- STEP 1.4: FEATURE ENGINEERING & BMI CATEGORIZATION
-- Objective: Transform continuous BMI values into standardized clinical risk tiers to segment the portfolio.
SELECT
    CASE
        WHEN bmi < 18.5 THEN 'Underweight'
        WHEN bmi >= 18.5 AND bmi < 25 THEN 'Normal'
        WHEN bmi >= 25 AND bmi < 30 THEN 'Overweight'
        ELSE 'Obese'
    END AS bmi_category,
    COUNT(*) AS customer_count
FROM insurance_claims
GROUP BY bmi_category
ORDER BY customer_count DESC;

-- STEP 1.5: MULTI-FACTOR RISK PROFILING & FINANCIAL IMPACT
-- Objective: Evaluate compound risk by crossing smoking status and BMI tiers, calculating severity, segment cost, and percentage share of total claims.
SELECT
    smoker,
    CASE
        WHEN bmi < 18.5 THEN 'Underweight'
        WHEN bmi >= 18.5 AND bmi < 25 THEN 'Normal'
        WHEN bmi >= 25 AND bmi < 30 THEN 'Overweight'
        ELSE 'Obese'
    END AS bmi_category,
    COUNT(*) AS total_policyholders,
    ROUND(AVG(charges), 2) AS avg_claim_cost,
    ROUND(SUM(charges), 2) AS total_segment_cost,
    ROUND((SUM(charges) * 100 / (SELECT SUM(charges) FROM insurance_claims)), 2) AS pct_of_total_claims
FROM insurance_claims
GROUP BY smoker,bmi_category
ORDER BY avg_claim_cost DESC;



-- ====================================================================
-- 2. PARETO RISK CONCENTRATION ANALYSIS (Deciles)
-- Objective: Identify loss ratio concentration across policyholder risk deciles
-- ====================================================================

-- STEP 2.1: DATA RANKING & DECILE SEGMENTATION WITH CTE
-- Objective: Order policyholder claims from highest to lowest and assign 10 risk deciles (NTILE).
WITH RankedClaims AS (
    SELECT
        charges,
        NTILE(10) OVER (ORDER BY charges DESC) AS deciles
    FROM insurance_claims
)

-- STEP 2.2: DECILE-LEVEL AGGREGATION & METRICS
-- Objective: Calculate headcount, total claims cost, and average claim severity for each risk decile.
SELECT
    deciles,
    COUNT(*) AS policyholders,
    ROUND(SUM(charges), 2) AS total_claims,
    ROUND(AVG(charges), 2) AS avg_claim
FROM RankedClaims
GROUP BY deciles

-- STEP 2.3: PARETO SHARE & CONCENTRATION CALCULATION
-- Objective: Compute percentage contribution of each decile against global portfolio claims.
ROUND(SUM(charges) * 100.0 / (SELECT SUM(charges) FROM insurance_claims), 2) AS pct_claims_share

-- STEP 2.4: SEQUENTIAL ORDERING & EXECUTIVE REPORTING
-- Objective: Display deciles 1 to 10 in order to visualize loss concentration for risk strategy.
WITH RankedClaims AS (
    SELECT
        charges,
        NTILE(10) OVER (ORDER BY charges DESC) AS deciles
    FROM insurance_claims
)

SELECT
    deciles,
    COUNT(*) AS policyholders,
    ROUND(SUM(charges), 2) AS total_claims,
    ROUND(AVG(charges), 2) AS avg_claim,
    ROUND(SUM(charges) * 100.0 / (SELECT SUM(charges) FROM insurance_claims), 2) AS pct_claims_share
FROM RankedClaims
GROUP BY deciles
ORDER BY deciles ASC;




-- --------------------------------------------------------------------
-- 3. UNDERWRITING MARGIN TRANSFORMATION SIMULATION
-- Objective: Simulate premium surcharge adjustments on high-risk tiers
-- --------------------------------------------------------------------
SELECT
    smoker,
    COUNT(*) AS policyholders,
    ROUND(SUM(charges), 2) AS current_total_claims,
    --Simulate an underwriting policy change by applying a 25% premium surcharge specifically to high-risk policyholders (smokers with BMI >= 30) while leaving low-risk tiers unchanged.
    ROUND(SUM(CASE WHEN smoker = 'yes' AND bmi >=30 THEN charges * 1.25 ELSE charges END), 2) AS simulated_revenue,
    --Isolate and measure the net additional revenue generated exclusively by the 25% high-risk surcharge to evaluate margin expansion potential.
    ROUND(SUM(CASE WHEN smoker = 'yes' AND bmi >= 30 THEN charges * 0.25 ELSE 0 END), 2) AS addional_margin
FROM insurance_claims
GROUP BY smoker;
-- ====================================================================
-- PROJECT: Health Insurance Claim Risk & Margin Analytics
-- STEP 1: Database Schema Definition, Data Ingestion & Sanity Check
-- ====================================================================


DROP TABLE IF EXISTS insurance_claims;

CREATE TABLE insurance_claims (
    age INTEGER,
    sex TEXT,
    bmi REAL,
    children INTEGER,
    smoker TEXT,
    region TEXT,
    charges REAL
);


SELECT 
    COUNT(*) AS total_registros,
    ROUND(AVG(charges), 2) AS promedio_costo
FROM insurance_claims;
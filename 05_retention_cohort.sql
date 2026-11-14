-- !preview conn=con
-- 05_retention_cohort.sql
-- MCC full-time retention from counts, with a 95% margin of error for each
-- year-to-year change. File year Y holds the fall Y-1 entering cohort.
-- RRFTCTA = adjusted full-time first-time cohort; RET_NMF = number retained.
-- The cohorts are full counts, not samples; the margins treat each cohort as
-- one draw from a stable process (two-proportion normal approximation).

WITH mcc AS (
  SELECT year - 1 AS entering_fall,
         RRFTCTA AS cohort,
         RET_NMF AS retained,
         RET_PCF AS rate_ipeds,
         100.0 * RET_NMF / RRFTCTA AS rate,
         100.0 * RET_NMF / RRFTCTA * (100 - 100.0 * RET_NMF / RRFTCTA) / RRFTCTA AS var
  FROM ef_d
  WHERE UNITID = 193326
)
SELECT entering_fall,
       cohort,
       retained,
       rate_ipeds,
       round(rate, 1) AS rate,
       round(1.96 * sqrt(var), 1) AS moe_95,
       round(rate - lag(rate) OVER (ORDER BY entering_fall), 1) AS change,
       round(1.96 * sqrt(var + lag(var) OVER (ORDER BY entering_fall)), 1) AS change_moe_95,
       round((rate - lag(rate) OVER (ORDER BY entering_fall))
             / sqrt(var + lag(var) OVER (ORDER BY entering_fall)), 2) AS z
FROM mcc
ORDER BY entering_fall;

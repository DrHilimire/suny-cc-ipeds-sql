-- !preview conn=con
-- 08_om_margins.sql
-- MCC's 8-year award rate for each entering group, with a 95% margin of
-- error, to show how large a difference from other colleges needs to be.

WITH mcc AS (
  SELECT OMCHRT, OMACHRT, 1.0 * OMAWDN8 / OMACHRT AS p
  FROM om
  WHERE UNITID = 193326
    AND OMCHRT IN (10, 20, 30, 40, 50)
    AND year = (SELECT max(year) FROM om)
)
SELECT OMCHRT AS entering_group,
       OMACHRT AS adjusted_cohort,
       round(100 * p, 1) AS award_8yr,
       round(100 * 1.96 * sqrt(p * (1 - p) / OMACHRT), 1) AS moe_95
FROM mcc
ORDER BY OMCHRT;

-- !preview conn=con
-- 03_peer_size.sql
-- Fall 2024 headcount for each SUNY community college, largest first, and
-- each college's difference from MCC (UNITID 193326) in percent.
-- EFALEVEL = 1 is the all-students row; EFTOTLT is total headcount.

WITH fall_2024 AS (
  SELECT UNITID, EFTOTLT AS headcount
  FROM ef_a
  WHERE year = 2024
    AND EFALEVEL = 1
),
mcc AS (
  SELECT headcount FROM fall_2024 WHERE UNITID = 193326
)
SELECT rank() OVER (ORDER BY f.headcount DESC) AS size_rank,
       s.UNITID,
       s.INSTNM,
       f.headcount,
       round(100.0 * (f.headcount - mcc.headcount) / mcc.headcount, 1) AS pct_vs_mcc
FROM suny_cc AS s
LEFT JOIN fall_2024 AS f ON s.UNITID = f.UNITID
CROSS JOIN mcc
ORDER BY size_rank;

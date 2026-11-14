-- !preview conn=con
-- 04_retention.sql
-- Full-time retention for the fall 2019 to fall 2023 entering cohorts: MCC,
-- the comparison colleges, and the median of all SUNY community colleges.
-- File year Y holds the fall Y-1 cohort. RET_PCF is the percent of first-time,
-- full-time students who re-enrolled or completed by fall Y.
-- For part-time students, use RET_PCP.

WITH by_college AS (
  SELECT d.UNITID,
         max(CASE WHEN d.year = 2020 THEN d.RET_PCF END) AS f2019,
         max(CASE WHEN d.year = 2021 THEN d.RET_PCF END) AS f2020,
         max(CASE WHEN d.year = 2022 THEN d.RET_PCF END) AS f2021,
         max(CASE WHEN d.year = 2023 THEN d.RET_PCF END) AS f2022,
         max(CASE WHEN d.year = 2024 THEN d.RET_PCF END) AS f2023
  FROM ef_d AS d
  JOIN suny_cc AS s ON d.UNITID = s.UNITID
  GROUP BY d.UNITID
),
combined AS (
  SELECT p.sort_order, p.label, c.f2019, c.f2020, c.f2021, c.f2022, c.f2023,
         c.f2023 - c.f2019 AS change, NULL AS n_colleges
  FROM by_college AS c
  JOIN peers AS p ON c.UNITID = p.UNITID
  UNION ALL
  -- Each column's median is taken separately; change is the median of each college's change
  SELECT 6, 'SUNY median', median(f2019), median(f2020), median(f2021),
         median(f2022), median(f2023), median(f2023 - f2019),
         least(count(f2019), count(f2020), count(f2021), count(f2022), count(f2023))
  FROM by_college
)
SELECT label, f2019, f2020, f2021, f2022, f2023, change, n_colleges
FROM combined
ORDER BY sort_order;

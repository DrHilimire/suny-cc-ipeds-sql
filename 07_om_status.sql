-- !preview conn=con
-- 07_om_status.sql
-- Outcome Measures, all four entering groups combined (OMCHRT = 50): where
-- students stood 8 years after entry, as percent of the adjusted cohort.
--   award_here           earned an award at this college
--   elsewhere_no_award   no award here; enrolled at another college after leaving
--   still_here           no award; still enrolled here
--   unknown_no_award     no award; no known later enrollment (the remainder)
-- College rows add to 100%. The median row takes each column's median separately.

WITH status AS (
  SELECT o.UNITID,
         o.OMACHRT AS adjusted_cohort,
         100.0 * o.OMAWDN8 / NULLIF(o.OMACHRT, 0) AS award_here,
         100.0 * o.OMENRAI / NULLIF(o.OMACHRT, 0) AS elsewhere_no_award,
         100.0 * o.OMENRYI / NULLIF(o.OMACHRT, 0) AS still_here,
         100.0 * o.OMENRUN / NULLIF(o.OMACHRT, 0) AS unknown_no_award
  FROM om AS o
  JOIN suny_cc AS s ON o.UNITID = s.UNITID
  WHERE o.OMCHRT = 50
    AND o.year = (SELECT max(year) FROM om)
),
combined AS (
  SELECT p.sort_order, p.label, s.adjusted_cohort, s.award_here, s.elsewhere_no_award,
         s.still_here, s.unknown_no_award, NULL AS n_colleges
  FROM status AS s
  JOIN peers AS p ON s.UNITID = p.UNITID
  UNION ALL
  SELECT 6, 'SUNY median', median(adjusted_cohort), median(award_here),
         median(elsewhere_no_award), median(still_here), median(unknown_no_award),
         count(award_here)
  FROM status
)
SELECT label,
       CAST(round(adjusted_cohort) AS INTEGER) AS adjusted_cohort,
       round(award_here, 1) AS award_here,
       round(elsewhere_no_award, 1) AS elsewhere_no_award,
       round(still_here, 1) AS still_here,
       round(unknown_no_award, 1) AS unknown_no_award,
       n_colleges
FROM combined
ORDER BY sort_order;

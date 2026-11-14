-- !preview conn=con
-- 06_om_completion.sql
-- Outcome Measures: percent of each entering group that earned an award at
-- the college within 8 years, for MCC, the comparison colleges, and the
-- median of all SUNY community colleges. The 2024 file covers students who
-- entered July 2016 to June 2017, with status as of August 31, 2024.
-- Entering groups (OMCHRT): 10 first-time full-time, 20 first-time part-time,
-- 30 non-first-time full-time, 40 non-first-time part-time, 50 all four;
-- 51 Pell grant in the entering year, 52 no Pell grant in the entering year.
-- Rate = awards within 8 years (OMAWDN8) / adjusted cohort (OMACHRT).

WITH rates AS (
  SELECT o.UNITID, o.OMCHRT,
         100.0 * o.OMAWDN8 / NULLIF(o.OMACHRT, 0) AS award_8yr
  FROM om AS o
  JOIN suny_cc AS s ON o.UNITID = s.UNITID
  WHERE o.year = (SELECT max(year) FROM om)
),
by_college AS (
  SELECT UNITID,
         max(CASE WHEN OMCHRT = 10 THEN award_8yr END) AS ft_first,
         max(CASE WHEN OMCHRT = 20 THEN award_8yr END) AS pt_first,
         max(CASE WHEN OMCHRT = 30 THEN award_8yr END) AS ft_transfer_in,
         max(CASE WHEN OMCHRT = 40 THEN award_8yr END) AS pt_transfer_in,
         max(CASE WHEN OMCHRT = 50 THEN award_8yr END) AS all_entering,
         max(CASE WHEN OMCHRT = 52 THEN award_8yr END)
           - max(CASE WHEN OMCHRT = 51 THEN award_8yr END) AS pell_gap
  FROM rates
  GROUP BY UNITID
),
combined AS (
  SELECT p.sort_order, p.label, c.ft_first, c.pt_first, c.ft_transfer_in,
         c.pt_transfer_in, c.all_entering, c.pell_gap, NULL AS n_colleges
  FROM by_college AS c
  JOIN peers AS p ON c.UNITID = p.UNITID
  UNION ALL
  -- Each column's median is taken separately; the Pell gap is computed per college first
  SELECT 6, 'SUNY median', median(ft_first), median(pt_first), median(ft_transfer_in),
         median(pt_transfer_in), median(all_entering), median(pell_gap),
         least(count(ft_first), count(pt_first), count(ft_transfer_in),
               count(pt_transfer_in), count(all_entering), count(pell_gap))
  FROM by_college
)
SELECT label,
       round(ft_first, 1) AS ft_first,
       round(pt_first, 1) AS pt_first,
       round(ft_transfer_in, 1) AS ft_transfer_in,
       round(pt_transfer_in, 1) AS pt_transfer_in,
       round(all_entering, 1) AS all_entering,
       round(pell_gap, 1) AS pell_gap,
       n_colleges
FROM combined
ORDER BY sort_order;

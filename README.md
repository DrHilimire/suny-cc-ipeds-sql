# Community College Benchmarking with IPEDS and SQL

This project builds a small institutional research (IR) database from public federal data and uses SQL (Structured Query Language) to compare student retention and completion at Monroe Community College (MCC) in Rochester, NY, with other State University of New York (SUNY) community colleges. The data come from the Integrated Postsecondary Education Data System (IPEDS). This is an independent exercise with public data. It was not produced for or reviewed by MCC.

## Summary

**Questions.** An IR office answers these every year:

1. What share of new full-time students return for a second year?
2. What share of all entering students, including part-time and transfer-in students, earn a credential?
3. What happens to students who leave without one?

**Why these measures.** Retention is measured one year after entry and Outcome Measures eight years after, so together they cover the start and end of a student's time at a college. Colleges report both to the federal government every year, and both appear in each college's IPEDS Data Feedback Report.

**Answers.**

- **Retention.** MCC's full-time first-to-second-year retention was 56% to 61% for the fall 2019 to fall 2023 entering cohorts. The fall 2022 cohort was the highest (61.3%). The fall 2023 cohort (57.0%) was within the range of fall 2019 to 2021 (56.0% to 59.3%). The 4.3-point change from fall 2022 slightly exceeds its 95% margin of error (3.5 points), but with four year-to-year changes examined it is weak evidence of a real change. The latest figures are provisional.
- **Completion.** Of degree- or certificate-seeking students who entered MCC between July 2016 and June 2017, 28.2% had earned a certificate or associate degree at MCC by August 31, 2024. That is within the range of the four SUNY community colleges closest to MCC in size (23.2% to 36.5%). The median of all 29 SUNY community colleges was 33.7%, but the median college's entering cohort was 1,614 students, against 5,081 at MCC.
- **By entering group.** Compared with the 29-college median, MCC's rate was close for first-time part-time students (17.9% vs. 19.1%), 4.8 points lower for first-time full-time students, and 7 to 8 points lower for students who had attended college before. The 95% margins on MCC's own rates are 1.6 to 3.9 points by group.
- **Leaving without an award.** The share who left without an MCC award and later enrolled at another college matched the median (26.4% vs. 26.9%). The share with no award and no known later enrollment was higher (43.6% vs. 38.0%). IPEDS computes that category as a remainder and counts enrollment elsewhere only when a college can confirm it, so differences between colleges can reflect tracking methods as well as student outcomes.

An award at the entering college is one of several successful outcomes at a community college. Students who transfer before finishing count as non-completers in these figures.

## Questions this raises for an IR office

Public data can show where a college differs from others. Internal data are needed to explain why. With access to a college's records, these would be my next steps.

1. **Reconcile with internal records.** Rebuild the fall 2022 and fall 2023 retention cohorts and the 2016-17 Outcome Measures cohort from the student information system and confirm they match what was reported to IPEDS. Internal records also show the fall 2024 cohort's retention before IPEDS publishes it.
2. **Look inside the "unknown" group.** Match students who left without an award to National Student Clearinghouse records, if that is not already part of reporting, to see how many enrolled elsewhere, where, and whether they earned a degree there.
3. **Use the college's own comparison group.** Rerun the queries with the comparison group the college uses for its IPEDS Data Feedback Report, or any peer set it uses with SUNY, in place of the size-only match here.
4. **Break results down.** Report retention and completion by program, by full-time and part-time status, by Pell status within each entering group, and by age and race and ethnicity.
5. **Judge single-year changes against the college's own history.** Add each new cohort, including part-time retention, to a control chart so a change is compared with the usual year-to-year variation before it is reported as a trend.

## SQL techniques used

| Technique | Where | Purpose |
|---|---|---|
| Common table expressions (`WITH`) | queries 03 to 08 | Build each step as a named table that can be checked |
| A view and a lookup table | `01_load.R` | Define the SUNY college list and the comparison colleges once |
| Inner, left, and cross joins | 03 to 07 | Restrict to SUNY colleges; keep a college even if its headcount is missing; compare each college with MCC |
| Conditional aggregation (`max(CASE WHEN ...)`) | 04, 06 | Turn long IPEDS files into one row per college |
| Window functions (`rank`, `lag`) | 03, 05 | Rank by size; year-to-year change and its margin |
| `UNION ALL` | 04, 06, 07 | Add the SUNY median row |
| `NULLIF` | 06, 07 | Avoid dividing by an empty cohort |

Example from `06_om_completion.sql`. IPEDS stores Outcome Measures as one row per college per entering group. This step makes one row per college and computes each college's Pell gap before any median is taken:

```sql
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
)
```

The queries run in DuckDB, a database that runs inside R. The core SQL carries over to SQL Server, Oracle, and PostgreSQL, but a few DuckDB conveniences would need changes: `median(x)` becomes `PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY x)`, and PostgreSQL's `round(x, 1)` needs a numeric argument.

## Comparison colleges

Fall 2024 headcount for the 29 colleges (`03_peer_size.sql`) puts MCC fifth, at 8,641 students. I used a band of 10% above or below MCC's headcount, set after viewing the ranking, which gives four colleges: Westchester (+8%), Hudson Valley (+7%), Onondaga (-1%), and Erie (-6%). The next closest, Dutchess, is 24% smaller.

This is a size match only, and headcount is a rough measure of size: it includes non-degree students such as high school students taking college courses. It is not MCC's own comparison group. A fuller match would also use part-time share, share of students receiving Pell grants (federal grants for low-income students), and program mix.

## Retention

Percent of first-time, full-time, degree- or certificate-seeking students who re-enrolled or completed their program by the following fall (`04_retention.sql`). For 2-year colleges, IPEDS counts students who completed their program within the year as retained.

| Entering cohort | Fall 2019 | Fall 2020 | Fall 2021 | Fall 2022 | Fall 2023 |
|---|---|---|---|---|---|
| Monroe (MCC) | 56 | 57 | 59 | 61 | 57 |
| Westchester | 61 | 61 | 65 | 62 | 65 |
| Hudson Valley | 54 | 57 | 62 | 61 | 61 |
| Onondaga | 53 | 48 | 51 | 53 | 55 |
| Erie | 55 | 55 | 57 | 54 | 56 |
| SUNY median (29) | 56 | 53 | 57 | 58 | 58 |

Table values are the whole-number rates IPEDS publishes. Each year's median is computed separately. The fall 2019 cohort's second fall was fall 2020, the first of the COVID-19 pandemic. MCC's first-time, full-time entering cohort fell from 2,171 in fall 2019 to 1,590 in fall 2020 (-27%).

**Is the fall 2023 change more than chance?** `05_retention_cohort.sql` computes MCC's rates from counts and adds a 95% margin of error for each year-to-year change. The cohorts are full counts, not samples, so the margins rest on an assumption: each cohort is one draw from a stable process in which students' outcomes are independent. The change from the fall 2022 to the fall 2023 cohort (61.3% to 57.0%) slightly exceeds its margin (4.3 vs. 3.5 points; z = 2.4). The three earlier changes (+1.0 to +2.3) do not. Four changes were examined, and with a Bonferroni correction for four comparisons (z above 2.5 required) this one would not count. It also follows the highest value in the series, where some return toward the average is expected. The fall 2023 rate is within the range of fall 2019 to 2021, so fall 2022 is the year that stands out. The fall 2023 cohort was also larger than the fall 2022 cohort (1,536 vs. 1,436), so a change in who enrolled is one possible explanation that these data cannot test.

## Completion and later enrollment: Outcome Measures

The standard IPEDS graduation rate counts only first-time, full-time students. At community colleges many students attend part-time or have attended college before, so Outcome Measures, which covers all four groups and tracks later enrollment elsewhere, is the more complete measure. The 2024 file covers degree- or certificate-seeking undergraduates who entered between July 1, 2016 and June 30, 2017, with status as of August 31, 2024. Each student is counted once, under their highest award.

Percent earning an award (certificate or associate degree) at the entering college within 8 years (`06_om_completion.sql`):

| | First-time, full-time | First-time, part-time | Transfer-in, full-time | Transfer-in, part-time | All four groups | Pell gap |
|---|---|---|---|---|---|---|
| Monroe (MCC) | 29.6 | 17.9 | 29.8 | 26.3 | 28.2 | 10.5 |
| Westchester | 27.9 | 20.6 | 32.5 | 23.9 | 26.9 | -0.7 |
| Hudson Valley | 37.9 | 24.4 | 37.8 | 33.5 | 36.5 | 11.3 |
| Onondaga | 23.5 | 13.9 | 29.0 | 23.7 | 23.2 | 5.8 |
| Erie | 31.0 | 18.1 | 41.4 | 27.0 | 31.9 | 4.1 |
| SUNY median (29) | 34.4 | 19.1 | 37.6 | 33.5 | 33.7 | 6.8 |

- "Transfer-in" means students who had attended college after high school before entering (IPEDS: non-first-time).
- The Pell gap is the award rate of students who did not receive a Pell grant in their entering year minus the rate of those who did, in percentage points. It is computed for each college, and the median row is the median of those gaps. It is not adjusted for differences between Pell recipients and other students in full-time and first-time status, and those differences vary by college, so gaps are not directly comparable across colleges.
- Each column's median is computed separately.
- For scale, the 95% margin on MCC's own 8-year award rate is 1.2 points for all students and 1.6 to 3.9 points for the four entering groups (`08_om_margins.sql`).

Outcomes of all four entering groups combined, 8 years after entry, as percent of the adjusted cohort (`07_om_status.sql`):

| | Adjusted cohort | Award here | No award, enrolled at another college after leaving | No award, still enrolled here | No award, no known later enrollment |
|---|---|---|---|---|---|
| Monroe (MCC) | 5,081 | 28.2 | 26.4 | 1.8 | 43.6 |
| Westchester | 4,387 | 26.9 | 27.9 | 1.6 | 43.6 |
| Hudson Valley | 3,459 | 36.5 | 25.3 | 1.2 | 37.0 |
| Onondaga | 3,391 | 23.2 | 30.5 | 0.9 | 45.4 |
| Erie | 4,205 | 31.9 | 25.3 | 1.1 | 41.6 |
| SUNY median (29) | 1,614 | 33.7 | 26.9 | 1.0 | 38.0 |

- The adjusted cohort is the entering cohort minus students IPEDS allows colleges to exclude: those who died, became permanently disabled, or left for military service, a federal foreign aid service, or an official church mission (5 of 5,086 students at MCC).
- College rows add to 100% apart from rounding. The median row takes each column's median separately, so it describes no single college and need not add to 100%.
- "Enrolled at another college after leaving" counts confirmed enrollment at any point in the eight years, not enrollment in year 8.
- A student who earned an award and then enrolled at another college is counted only under "award here," so the "enrolled at another college" column understates how many students went on to another college.

## Limits

- IPEDS reports college-level totals, not student records. This analysis can describe differences between colleges but cannot explain them.
- An award at the entering college is one of several successful outcomes. Students who transfer before finishing count as non-completers, which lowers the rate at colleges where early transfer is common.
- Comparison colleges were matched on size only. Program mix, part-time share, and Pell share are not controlled.
- Outcome Measures describes students who entered in 2016-17, and the later years of their tracking period overlapped the pandemic.
- Margins of error were computed for MCC only, not for differences between colleges.

## Appendix A. Data and definitions

**Source.** IPEDS Complete Data Files, National Center for Education Statistics (NCES), downloaded as comma-separated values (CSV) files.

| Table | IPEDS file | Describes |
|---|---|---|
| `hd` | HD2025 | College names, location, sector, and system |
| `ef_a` | EF2024A | Fall 2024 headcount |
| `ef_d` | EF2020D to EF2024D | Fall 2019 to fall 2023 entering cohorts, measured the following fall |
| `om` | OM2024 | Students entering July 2016 to June 2017, status at August 31, 2024 |

IPEDS file years are not cohort years, which is the main trap with these files. The 2020 to 2023 files are revised (`_rv`) releases. The 2024 files and the 2025 directory are provisional, so those values may change.

**Colleges.** SUNY counts 30 community colleges. This analysis uses the 29 that IPEDS classifies as public 2-year (sector 4). The Fashion Institute of Technology is not included because IPEDS classifies it as a 4-year college. Every median is based on all 29; each query reports the count.

## Appendix B. How to run

**Setup.** Install R and RStudio, then in R:

```r
install.packages(c("duckdb", "DBI"))
```

**Data.** From the [IPEDS data center](https://nces.ed.gov/ipeds/datacenter/), Complete Data Files, download the files in Appendix A and unzip the CSVs into a folder named `raw` in the project folder. Where a zip holds both an original and a revised (`_rv`) file, keep only the `_rv` file. The raw files and the database are not stored in this repository.

**Run.** `01_load.R` builds `ipeds.duckdb`, defines the SUNY college view and the comparison colleges, and defines `run_sql()`. In a new R session, run it again first.

```r
setwd("path/to/project")
source("01_load.R")
for (f in list.files(pattern = "^0[2-8].*\\.sql$")) {
  cat("\n==", f, "==\n")
  print(run_sql(f))
}
```

| File | Does |
|---|---|
| `01_load.R` | Loads each IPEDS file type into one table, defines the college lists, and defines `run_sql()` |
| `02_find_peers.sql` | Lists New York's public 2-year colleges and their systems |
| `03_peer_size.sql` | Ranks SUNY community colleges by fall 2024 headcount, with each one's difference from MCC |
| `04_retention.sql` | Retention by entering cohort for MCC, comparison colleges, and the SUNY median |
| `05_retention_cohort.sql` | MCC retention from counts, with margins of error |
| `06_om_completion.sql` | 8-year award rates by entering group, and the Pell gap |
| `07_om_status.sql` | Outcomes of all entering groups after 8 years |
| `08_om_margins.sql` | 95% margins on MCC's 8-year award rates |

Each `.sql` file also runs from RStudio's Preview button while `con` is open.

## Source

U.S. Department of Education, National Center for Education Statistics, Integrated Postsecondary Education Data System (IPEDS), Complete Data Files, accessed November 2026. Definitions follow the [IPEDS Outcome Measures instructions](https://nces.ed.gov/IPEDS/use-the-data/download-survey-material/2022/outcome%20measures/package_13_101.pdf) and the [IPEDS data release schedule](https://nces.ed.gov/ipeds/survey-components/data-release-schedule).

Matt Hilimire, PhD

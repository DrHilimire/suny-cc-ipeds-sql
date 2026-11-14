# 01_load.R
# Load IPEDS complete data files (CSV) into a DuckDB database, one table per
# file type, with a year column taken from each file name. Then define the
# SUNY community college list and the comparison colleges used by the queries.
# Before running: unzip the CSVs into raw/ and set the working directory to
# the project folder.
# Author: Matt Hilimire, November 2026

# Setup (run once): install.packages(c("duckdb", "DBI"))

library(DBI)
con <- dbConnect(duckdb::duckdb(), dbdir = "ipeds.duckdb")

files <- list.files("raw", pattern = "\\.csv$", full.names = TRUE, ignore.case = TRUE)
print(basename(files))

# When a zip held an original and a revised (_rv) file, keep only the _rv file
base <- sub("_rv", "", tolower(basename(files)))
if (any(duplicated(base))) {
  stop("Delete the non-_rv copies of: ", paste(unique(base[duplicated(base)]), collapse = ", "))
}

load_table <- function(table, regex) {
  f <- files[grepl(regex, basename(files), ignore.case = TRUE)]
  if (length(f) == 0) return(cat("No files for", table, "\n"))
  sql <- function(encoding) paste0("
    CREATE OR REPLACE TABLE ", table, " AS
    SELECT CAST(regexp_extract(filename, '(\\d{4})[a-z]*(_rv)?\\.csv$', 1, 'i') AS INTEGER) AS year,
           * EXCLUDE (filename)
    FROM read_csv(['", paste(f, collapse = "', '"), "'],
                  union_by_name = true, filename = true, sample_size = -1,
                  encoding = '", encoding, "')")
  # Older IPEDS files are Latin-1 rather than UTF-8
  tryCatch(dbExecute(con, sql("utf-8")), error = function(e) {
    message("Reading ", table, " as Latin-1. UTF-8 error: ", conditionMessage(e))
    dbExecute(con, sql("latin-1"))
  })
  print(dbGetQuery(con, paste("SELECT year, count(*) AS n_rows FROM", table,
                              "GROUP BY year ORDER BY year")))
}

load_table("hd", "^hd\\d{4}(_rv)?\\.csv$")      # directory
load_table("ef_a", "^ef\\d{4}a(_rv)?\\.csv$")   # fall enrollment
load_table("ef_d", "^ef\\d{4}d(_rv)?\\.csv$")   # retention
load_table("om", "^om\\d{4}(_rv)?\\.csv$")      # Outcome Measures

# SUNY community colleges: public 2-year colleges (sector 4) in the SUNY system
dbExecute(con, "
  CREATE OR REPLACE VIEW suny_cc AS
  SELECT UNITID, INSTNM, CITY
  FROM hd
  WHERE STABBR = 'NY'
    AND SECTOR = 4
    AND F1SYSNAM = 'State University of New York System'
    AND year = (SELECT max(year) FROM hd)")

# Comparison colleges: every SUNY community college within 10% of MCC's
# fall 2024 headcount (see 03_peer_size.sql)
dbExecute(con, "
  CREATE OR REPLACE TABLE peers AS
  SELECT * FROM (VALUES
    (1, 193326, 'Monroe (MCC)'),
    (2, 197294, 'Westchester'),
    (3, 191719, 'Hudson Valley'),
    (4, 194222, 'Onondaga'),
    (5, 191083, 'Erie')
  ) AS t(sort_order, UNITID, label)")

# Run a .sql file and return the result
run_sql <- function(file) dbGetQuery(con, paste(readLines(file), collapse = "\n"))

# When finished: dbDisconnect(con)

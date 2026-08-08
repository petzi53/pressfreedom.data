# Detect RSF Data Period by Year

Determines which structural period a given year belongs to based on
known changes in RSF's data format and calculation methodology.

## Usage

``` r
get_period(year)
```

## Arguments

- year:

  Integer. Year to check.

## Value

Character. One of: `"period_1"` (2002-2012), `"period_2"` (2013-2021),
or `"period_3"` (2022-2026). Returns `NA` for year 2011 (no official RSF
data).

## Details

\*\*Period 1 (2002-2012):\*\* - 16 columns with fixed structure -
Encoding: ISO-8859-1 - Delimiter: semicolon (;) - Scores not comparable
across years (within-year ranks only)

\*\*Period 2 (2013-2021):\*\* - 16 columns, same structure as Period 1 -
Encoding: ISO-8859-1 - Delimiter: semicolon (;) - Scores comparable
across years (new calculation method introduced)

\*\*Period 3 (2022-2026):\*\* - 22-25 columns (varies by year) -
Encoding: UTF-8 - Delimiter: semicolon (;) - Major restructuring:
columns reordered, score dimensions added - Column names vary by year
(e.g., "Score" vs "Score 2026")

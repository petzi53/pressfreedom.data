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

This function determines the structural period a year belongs to, which
drives column mapping and normalization logic.

\*\*Important:\*\* Encoding is NOT period-based. Use
[`detect_csv_encoding()`](https://www.peter-baumgartner.net/pressfreedom.data/reference/detect_csv_encoding.md)
to determine per-file encoding. Period 1-2 (2002-2021) are UTF-8 despite
the structural naming; Period 3 (2022-2026) mixed UTF-8 (2022-2024) and
ISO-8859-1 (2025-2026) without warning.

\*\*Period 1 (2002-2012):\*\* - 16 columns with fixed structure -
Delimiter: semicolon (;) - Scores not comparable across years
(within-year ranks only)

\*\*Period 2 (2013-2021):\*\* - 16 columns, same structure as Period 1 -
Delimiter: semicolon (;) - Scores comparable across years (new
calculation method introduced)

\*\*Period 3 (2022-2026):\*\* - 22-25 columns (varies by year) -
Delimiter: semicolon (;) - Major restructuring: columns reordered, score
dimensions added - Column names vary by year (e.g., "Score" vs "Score
2026")

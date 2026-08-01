# Detect CSV File Encoding

Guesses whether a raw RSF CSV file is UTF-8 or a Latin-1 variant. Used
by clean_period_1(), clean_period_2(), and clean_period_3() because RSF
has switched export encoding across years without notice (e.g. 2002-2021
exports are UTF-8 despite once being assumed ISO-8859-1, and 2025-2026
arrived as ISO-8859-1 while 2022-2024 were UTF-8).

## Usage

``` r
detect_csv_encoding(filepath)
```

## Arguments

- filepath:

  Character. Path to raw CSV file

## Value

Character. Either "UTF-8" or "ISO-8859-1"

## Details

Uses readr::guess_encoding(), which ranks candidate encodings by
confidence. Falls back to "UTF-8" if detection is inconclusive, since
that has been the more common case historically.

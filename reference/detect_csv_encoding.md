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
confidence. Explicitly detects UTF-8/US-ASCII and the ISO-8859-1 family
(ISO-8859-1, windows-1252, latin1) and normalizes all to one of these
two outcomes. Raises an error if: - readr::guess_encoding() returns zero
candidates (truly indeterminate), or - the top candidate is neither
UTF-8/ASCII nor the ISO-8859-1 family (an unexpected encoding, typically
indicating data corruption or a source format change).

This explicit design prevents silent misidentification: if RSF ever
introduces a third encoding, or a file is corrupted, the error is
visible at parse time rather than allowing bad data downstream.

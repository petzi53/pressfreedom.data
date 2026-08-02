# Get Encoding for RSF Data by Period (Deprecated)

**Deprecated:** this period-based heuristic turned out to be wrong for
Period 1-2 (2002-2021 RSF exports are actually UTF-8, not ISO-8859-1)
and unreliable in general, since RSF has switched encodings within a
period without notice (e.g. 2025-2026 arrived as ISO-8859-1 while
2022-2024 were UTF-8). The cleaning pipeline now detects the encoding of
each downloaded file directly with
[`detect_csv_encoding()`](https://www.peter-baumgartner.net/pressfreedom.data/reference/detect_csv_encoding.md)
instead of guessing from the year. This function is kept only for
backward compatibility and should not be used for new code.

## Usage

``` r
get_period_encoding(year)
```

## Arguments

- year:

  Integer. Year to check.

## Value

Character. Encoding string: `"ISO-8859-1"` for Period 1-2, `"UTF-8"` for
Period 3.

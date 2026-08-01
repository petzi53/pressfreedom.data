# Standardize Decimal Separators

Converts comma decimal separators to periods for Period 1-2 data
(ISO-8859-1 encoded data used commas as decimal separators).

## Usage

``` r
standardize_decimal_separators(df, cols)
```

## Arguments

- df:

  Data frame to process

- cols:

  Character vector of column names to standardize

## Value

Data frame with decimal separators converted from comma to period

## Details

This function targets numeric columns that may contain comma separators.
It is primarily for Period 1-2 data where European number formatting was
used.

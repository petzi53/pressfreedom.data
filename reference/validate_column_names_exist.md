# Validate That Expected Raw Columns Exist in a CSV

Fails loudly if any expected raw column name is missing from the data
frame, rather than letting downstream renaming silently produce all-NA
columns. Intended to be called right after reading a raw CSV and
resolving the column mapping (including any overrides), before any
renaming happens.

## Usage

``` r
validate_column_names_exist(df, expected_raw_cols, year)
```

## Arguments

- df:

  Data frame. The raw CSV, read with all columns as character.

- expected_raw_cols:

  Character vector. Raw column names the mapping expects to find in
  \`df\`.

- year:

  Numeric. Year of the data (for the error message).

## Value

Invisible \`NULL\`. Called for its side effect (aborting on failure).

## Details

This exists because RSF has renamed export columns before without notice
(e.g. "Score" -\> "Score 2025") and may rename others in the future in
ways that cannot be predicted ahead of time (e.g. "Economic Context" -\>
"Economy"). Without this check, a renamed column silently resolves to
\`NA\` for every row via \`normalize_column_names()\`, and the corrupted
data can ship undetected. See \`load_column_overrides()\` for how to fix
a failure this raises without changing package code.

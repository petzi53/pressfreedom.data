# Load User-Provided Column Name Overrides

Reads \`period3_column_overrides.csv\`, if present, and returns any
override mappings for the given year as a named list suitable for
\`apply_column_overrides()\`.

## Usage

``` r
load_column_overrides(year, overrides_file = NULL)
```

## Arguments

- year:

  Numeric. Year to look up overrides for.

- overrides_file:

  Character. Path to the overrides CSV. Defaults to the file shipped in
  \`inst/extdata/\` via \`system.file()\`.

## Value

Named list (\`target_col = "actual_col"\`, ...) of overrides for
\`year\`, or \`NULL\` if the file doesn't exist or has no rows for
\`year\`.

## Details

This is the general-purpose safety net for RSF column renames – both the
ones already seen (e.g. \`"Score"\` -\> \`"Score 2025"\`) and any
future, unpredictable ones (e.g. \`"Economic Context"\` -\>
\`"Economy"\`). There is no special-cased detection logic for any single
column, including \`score\`: every rename, however likely, is handled
the same way, via this override file. When
\`validate_column_names_exist()\` aborts because an expected column is
missing, add a row to the CSV:

“\` year,target_col,expected_col,actual_col
2027,economic_context,Economic Context,Economy “\`

\`target_col\` is the unified output column name (from
\`target_columns\`); \`expected_col\` documents what the mapping
originally expected (for human readability only, not used
programmatically); \`actual_col\` is the raw column name actually found
in that year's CSV. Append future rows to the same file rather than
creating a new file per year.

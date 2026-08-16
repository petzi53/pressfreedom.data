# Column Mapping for Period 3 (2022-2026)

Period 3 raw columns mapped to unified 20-column structure. Note:
\`score\` maps to the plain "Score" raw name, which is what RSF has used
in most Period 3 years (2022-2024). Years where RSF appended the year to
the column name instead (2025: "Score 2025", 2026: "Score 2026") are
handled via \`inst/extdata/period3_column_overrides.csv\`, the same
generic mechanism used for any other unpredictable RSF rename – see
\`load_column_overrides()\`. This mapping is intentionally not
special-cased for "Score", since only 2 of the 5 Period 3 years so far
have used the year-suffixed name. Named in target column order.

## Usage

``` r
period_3_mapping
```

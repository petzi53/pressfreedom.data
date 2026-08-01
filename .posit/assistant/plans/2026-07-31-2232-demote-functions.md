# Plan: Demote maintenance functions to internal; drop third vignette

## Decision (superseding the earlier "third vignette" plan)

After discussion, Peter chose: **demote the 7 maintenance/update functions to
internal (unexported), and drop the planned third public vignette entirely.**

Rationale (see chat for full discussion):

- Standard CRAN data-package convention keeps ETL/update logic in unexported
  `data-raw/` scripts, not the public API (`nycflights13`, `babynames`, `gapminder`
  pattern via `usethis::use_data_raw()`).
- `update_rwb_data()` cannot work correctly on an installed/CRAN copy of the package
  anyway -- it hard-codes `here::here()` paths that only resolve inside Peter's
  development checkout, and it performs a `git commit`. Exporting it as if it were a
  user-facing function is misleading regardless of documentation quality.
- The non-ASCII pre-commit hook and git-commit step are maintainer/repo concerns, not
  something a package consumer or the downstream Shiny app ever touches -- a signal
  these functions are internal tooling.
- The package's real audience (Shiny app + CRAN users) only needs
  `data(rwb_standardized)` and column documentation, not ETL internals.

## Scope: the 7 functions to demote

1. `download_rwb_data()` (`R/download.R`)
2. `clean_rwb_single()` (`R/clean.R`)
3. `clean_all_rwb_years()` (`R/clean.R`)
4. `combine_cleaned_periods()` (`R/combine.R`)
5. `consolidate_and_standardize_countries()` (`R/standardize.R`)
6. `standardize_rwb_countries()` (`R/standardize.R`)
7. `update_rwb_data()` (`R/update.R`), plus its S3 print method `print.rwb_update()`

## Implementation steps

1. **Remove `@export` from all 7 functions** (and `print.rwb_update()`), replacing/
   adding `@keywords internal` so they stay documented (roxygen still generates
   `.Rd` files for Peter's own reference) but are hidden from the public help index
   and no longer appear in `NAMESPACE`.
2. **Regenerate documentation**: `devtools::document()` to rebuild `NAMESPACE` and
   `man/*.Rd`. Confirm the 7 (8, counting the print method) no longer appear as
   `export(...)` lines.
3. **Add a maintainer runbook script**: `data-raw/update-data.R` (new), a plain,
   commented script showing Peter's actual yearly workflow, e.g.:
   ```r
   # Run once per year when RSF publishes new data.
   # Requires a full dev checkout (devtools::load_all() gives access to
   # unexported functions); not runnable from an installed copy.
   devtools::load_all()
   result <- update_rwb_data()
   print(result)
   ```
   Already covered by the existing `data-raw/` -> `.Rbuildignore` precedent
   (`data-raw/rwb_standardized.R` already exists there).
4. **Revise `vignettes/getting-started.Rmd`:**
   - Remove the "Annual Updates" section including the "Manual Control" subsection (only relevant to internal-function
     users).
   - Update the FAQ's "Where can I learn more" third bullet with the following decision: Would there a special website to document functions still necessary? There are no public functions left.
5. **Do not create** `vignettes/maintaining-the-data.Rmd` (cancels the previous
   plan's core deliverable).
6. **NEWS.md**: add an entry noting the breaking API change -- these functions are no
   longer part of the public API (unexported); document the rationale briefly for
   anyone who was calling them directly (e.g., `pressfreedom.data:::update_rwb_data()`
   still works for advanced/dev use, just not via `::`).
7. **Verification:**
   - `devtools::document()` then `devtools::check()` (or at least
     `devtools::load_all()` + run `testthat::test_dir("tests/testthat")`) to confirm
     `test-clean.R` still passes -- it calls functions by bare name, which works
     whether exported or not within the package's own test environment.
   - Re-render `getting-started.Rmd` to confirm it knits cleanly after edits.
   - Confirm `NAMESPACE` diff only removes the intended 8 `export()` lines.

## Flagged for a follow-up decision (not in this pass)

`NAMESPACE` currently also exports 12 other low-level helpers that look like even
clearer internal-implementation details of Phase B/D (`clean_period_1/2/3`,
`convert_factors_to_character`, `detect_csv_encoding`, `detect_score_column`,
`get_period`, `get_period_encoding`, `get_years_to_download`,
`normalize_column_names`, `resolve_percent_scaling`,
`standardize_decimal_separators`). Same argument applies to these, arguably more
strongly. Recommend a follow-up pass to demote these too for API consistency, but
keeping this pass scoped to the 7 functions explicitly discussed, per your call.

## Files touched

| File | Change |
|---|---|
| `R/download.R` | Remove `@export` from `download_rwb_data()` |
| `R/clean.R` | Remove `@export` from `clean_rwb_single()`, `clean_all_rwb_years()` |
| `R/combine.R` | Remove `@export` from `combine_cleaned_periods()` |
| `R/standardize.R` | Remove `@export` from `consolidate_and_standardize_countries()`, `standardize_rwb_countries()` |
| `R/update.R` | Remove `@export` from `update_rwb_data()`, `print.rwb_update()` |
| `NAMESPACE`, `man/*.Rd` | Regenerated via `devtools::document()` |
| `data-raw/update-data.R` | New: maintainer runbook script |
| `vignettes/getting-started.Rmd` | Rewrite "Annual Updates" section + FAQ pointer |
| `NEWS.md` | New entry documenting the breaking API change |

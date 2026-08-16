# pressfreedom.data 0.3.0

## Major changes

* **Unified column rename mechanism:** RSF periodically renames columns in their
  exports (e.g., 2025–2026: "Score" → "Score 2025"/"Score 2026"). All such
  renames now flow through a single, transparent override system
  (`inst/extdata/period3_column_overrides.csv` + three validation/override
  functions) instead of special-cased detection logic. This makes future RSF
  format changes maintainable without code edits — just append a row to the
  CSV. Includes three new safety net functions for per-column validation,
  override loading, and mapping patching.

* **Improved encoding robustness:** Each raw RSF CSV is now scanned per-file
  for encoding (UTF-8 vs. ISO-8859-1 inherited from RSF's silent 2025 switch),
  preventing mojibake that would otherwise propagate silently into RDS datasets.
  Detection happens at download time; data are converted to UTF-8 during
  cleaning.

## Internal refactoring

* Removed `detect_score_column()` function (functionality moved to override
  mechanism, making score renames no longer special).
* Simplified `normalize_column_names()` signature: dropped unused `period` and
  `year` parameters. Function now does pure mechanical rename/reorder; all
  period/year-specific logic moved to caller. This removes ~22 lines of code
  and clarifies the API boundary.
* Test harness: suppressed console output from validation failure-case tests,
  so only "All validation checks passed!" appears in `R CMD check` output,
  avoiding false suspicion of package issues during CRAN review.

## Compliance

* Addressed all feedback from CRAN v0.2.0 rejection (Aug 8, 2026): DESCRIPTION
  URL, print method documentation, removal of unexported function examples,
  elimination of `\dontrun{}`, replacement of `cat()` with `message()`, removal
  of package-relative path defaults from internal functions.

# pressfreedom.data 0.2.0

## Breaking changes

* ETL/update functions (`download_rwb_data()`, `clean_rwb_single()`,
  `clean_all_rwb_years()`, `combine_cleaned_periods()`,
  `standardize_rwb_countries()`, `update_rwb_data()`, and related internal
  helpers) are no longer exported. They rely on a development checkout
  (`here::here()` paths, git operations) and were never usable from an
  installed copy of the package. The public API is now just the
  `rwb_standardized` dataset. Use `pressfreedom.data:::fun()` if you still
  need direct access.

* `zone` now uses English region names instead of RSF's original French
  labels, e.g. `"MENA"` -> `"Middle East & North Africa"`,
  `"Afrique"` -> `"Africa"`. Update any code that filters or joins on the
  old French values (see `?rwb_standardized` for the full mapping). This
  also fixes a recurring `zone` mojibake/encoding issue.

* Fixed `score_n_1` for 2023-2026 (720 rows), which was about 100x too
  large (e.g. `9265` instead of `92.65`) due to a missing decimal-scaling
  step. It's now on the same 0-100 scale as `score`. Remove any manual
  rescaling workaround for these years.

## Documentation

* Clarified the `rwb_` naming convention (RSF vs. RWB) in
  `?rwb_standardized`.
* De-duplicated content between `README.md` and
  `vignette("getting-started")`; consolidated citation info into
  `inst/CITATION`.
* Added a `\value` tag to `print.rwb_update()`'s documentation and cited
  the RSF web service in the `Description:` field, addressing CRAN
  feedback on the initial 0.2.0 submission.

## Internal (CRAN feedback, 0.2.0 resubmission)

* Removed `\examples` from the unexported helpers `download_rwb_data()`,
  `get_period()`, and `get_years_to_download()` rather than exporting
  them, eliminating the package's only `\dontrun{}` usage.
* `download_rwb_data()` now uses `message()` instead of unconditional
  `cat()` for progress/summary output, so it can be suppressed with
  `suppressMessages()`.
* Removed package-relative default paths (e.g. `"inst/extdata"`,
  `here::here("data", "cleaned")`) from `download_rwb_data()`,
  `get_years_to_download()`, `clean_rwb_single()`,
  `clean_all_rwb_years()`, `combine_cleaned_periods()`, and
  `standardize_rwb_countries()`. These arguments are now required with no
  default, so the functions never write to (or read from) a package or
  home directory implicitly.

## Other

* New hex sticker logo, redesigned to be visually distinct from the
  companion `pressfreedom` Shiny app's logo.

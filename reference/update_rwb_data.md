# Update Reporters Without Borders Press Freedom Data

Orchestrates the full yearly update workflow: downloads missing years,
cleans them, recombines all periods, re-standardizes countries, exports
to package format, and validates the result.

## Usage

``` r
update_rwb_data(
  years = NULL,
  download = TRUE,
  clean = TRUE,
  combine = TRUE,
  standardize = TRUE,
  validate = TRUE,
  verbose = TRUE,
  auto_commit = TRUE
)
```

## Arguments

- years:

  Integer vector. Years to download and clean. Defaults to `NULL`:
  auto-detect missing years via
  [`get_years_to_download()`](https://petzi53.github.io/pressfreedom.data/reference/get_years_to_download.md).

- download:

  Logical. If `TRUE`, download missing years. If `FALSE`, skip download
  (useful for testing). Default: `TRUE`.

- clean:

  Logical. If `TRUE`, clean newly downloaded years. If `FALSE`, skip
  cleaning. Default: `TRUE`.

- combine:

  Logical. Always `TRUE`; recombines all periods to recalculate
  evolution columns. Cannot be skipped. Default: `TRUE`.

- standardize:

  Logical. Always `TRUE`; re-standardizes countries to apply
  consolidation rules consistently. Cannot be skipped. Default: `TRUE`.

- validate:

  Logical. If `TRUE`, run validation checks on output. Default: `TRUE`.

- verbose:

  Logical. If `TRUE`, print progress messages. Default: `TRUE`.

- auto_commit:

  Logical. If `TRUE`, auto-commit changes to git with a descriptive
  message. Default: `TRUE`.

## Value

Invisible list with class "rwb_update" containing: - `status`:
"success", "partial", or "failed" - `years_downloaded`: Integer vector
of years downloaded - `years_cleaned`: Integer vector of years cleaned -
`rows_before`: Row count in combined RDS before update - `rows_after`:
Row count in combined RDS after update - `consolidations_applied`:
Number of consolidation rules applied - `validation_passed`: Logical,
`TRUE` if all checks pass - `messages`: Character vector of progress
messages - `git_commit`: Commit hash if auto-committed; `NA` otherwise

## Details

This function implements the "minimal disruption principle": only new
years are downloaded and cleaned. Phases C-D (combine, standardize)
always run because evolution columns depend on year N-1's data.

\*\*Workflow Overview:\*\*

1\. \*\*Detection (Phase A pre-check)\*\* - If `years = NULL`, detect
missing years via
[`get_years_to_download()`](https://petzi53.github.io/pressfreedom.data/reference/get_years_to_download.md) -
If no years missing, report and return early (unless
`standardize = TRUE`)

2\. \*\*Download (Phase A)\*\* - Only if `download = TRUE` - Downloads
CSVs for detected missing years to `inst/extdata/` - Validates each CSV
before saving - On download failure: aborts update with error message

3\. \*\*Clean (Phase B)\*\* - Only if `clean = TRUE` and years
detected - Cleans newly downloaded years via
[`clean_rwb_single()`](https://petzi53.github.io/pressfreedom.data/reference/clean_rwb_single.md) -
Outputs normalized RDS to `data/cleaned/period_X/` - On cleaning
failure: aborts update and reports which year failed

4\. \*\*Combine (Phase C)\*\* - Always runs (required) - Recombines all
cleaned periods via
[`combine_cleaned_periods()`](https://petzi53.github.io/pressfreedom.data/reference/combine_cleaned_periods.md) -
Recalculates evolution columns (rank_n_1, score_n_1, etc.) - Output:
`data/processed/rwb_combined.rds` - Cost: ~1-2 seconds

5\. \*\*Standardize (Phase D)\*\* - Always runs (required) -
Re-standardizes all rows via
[`standardize_rwb_countries()`](https://petzi53.github.io/pressfreedom.data/reference/standardize_rwb_countries.md) -
Applies consolidation rules from
`inst/extdata/consolidation_mapping.csv` - Output:
`data/processed/rwb_standardized.rds` - Cost: ~2-3 seconds

6\. \*\*Export\*\* - Regenerates `rwb_standardized.rda` via
`data-raw/rwb_standardized.R` - Cost: \<1 second

7\. \*\*Validation\*\* - Only if `validate = TRUE` - Checks row count
increase matches expectations - Verifies no duplicate rows - Ensures all
required columns present - On validation failure: reports issues but
doesn't abort

8\. \*\*Git Commit\*\* - Only if `auto_commit = TRUE` - Stages updated
RDS files - Creates commit with message describing what changed - On
commit failure: reports warning but doesn't abort update

\*\*Intelligent Defaults:\*\* - `combine = TRUE`, `standardize = TRUE`:
Cannot be overridden (always required) - `validate = TRUE`: Recommended
for production workflows - `auto_commit = TRUE`: Recommended; provides
git history of updates - `verbose = TRUE`: Recommended for interactive
use

\*\*Error Handling:\*\* - Download fails -\> Aborts with error -
Cleaning fails -\> Aborts and reports which year failed -
Combine/Standardize fail -\> Aborts (indicates data corruption) -
Validation fails -\> Reports issues; doesn't abort - Git commit fails
-\> Reports warning; doesn't abort update

\*\*Example: Minimal yearly update\*\* “\`r \# Run once per year when
new RSF data available result \<- update_rwb_data() \# Auto-detects
missing years, downloads, cleans, combines, standardizes print(result)
“\`

\*\*Example: Testing without download\*\* “\`r \# Test
combining/standardizing without network calls result \<-
update_rwb_data(years = NULL, download = FALSE, clean = FALSE) “\`

## See also

\-
[`download_rwb_data`](https://petzi53.github.io/pressfreedom.data/reference/download_rwb_data.md)
for Phase A details -
[`clean_rwb_single`](https://petzi53.github.io/pressfreedom.data/reference/clean_rwb_single.md)
for Phase B details -
[`combine_cleaned_periods`](https://petzi53.github.io/pressfreedom.data/reference/combine_cleaned_periods.md)
for Phase C details -
[`standardize_rwb_countries`](https://petzi53.github.io/pressfreedom.data/reference/standardize_rwb_countries.md)
for Phase D details -
[`get_years_to_download`](https://petzi53.github.io/pressfreedom.data/reference/get_years_to_download.md)
for missing year detection

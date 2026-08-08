# CRAN Submission Comments

## Submission type

This is a new submission (first release of pressfreedom.data to CRAN).

## Test environments

* local macOS (aarch64-apple-darwin23), R 4.6.1 -- 0 errors | 0 warnings | 0 notes
* win-builder (R-devel, x86_64-w64-mingw32) -- checked twice:
  * First run: 2 NOTEs (see "NOTEs addressed before this submission" below);
    both real issues have since been fixed.
  * Second run (after fixes): 1 NOTE (no errors, no warnings) -- only the
    two expected NOTEs listed below ("New submission",
    "Possibly misspelled words ... RSF") remain. Confirms both real issues
    were resolved.
* GitHub Actions R-CMD-check matrix (macOS release, Windows release,
  Ubuntu devel/release/oldrel-1): all 5 jobs passed
  (https://github.com/petzi53/pressfreedom.data/actions/runs/30748471422).

## R CMD check results

0 errors | 0 warnings | 0 notes (local check)

### Expected NOTEs on CRAN's incoming checks

* "New submission" -- expected for a first release.
* "Possibly misspelled words in DESCRIPTION: RSF" -- false positive.
  RSF (Reporters Sans Frontieres) is the organization's real legal
  abbreviation, spelled out and explained in the Description field.

## NOTEs addressed before this submission

The first win-builder devel check surfaced two real, now-fixed issues (in
addition to the two expected NOTEs above):

1. **DESCRIPTION metadata mismatch:** an explicit `Author:` field was
   present alongside `Authors@R` and had drifted out of sync (missing the
   ORCID recorded in `Authors@R`). Removed the redundant `Author:` field
   so it is derived automatically and stays in sync.
2. **Invalid URLs:**
   * `man/download_rwb_data.Rd` documented a per-year URL template using a
     `<year>` placeholder, which 404s as a literal URL. Replaced with a
     concrete, verified working example (`.../2024.csv`, HTTP 200) plus a
     note that the year can be substituted.
   * The pkgdown site URL in `DESCRIPTION` (`https://petzi53.github.io/pressfreedom.data`)
     301-redirects to a custom domain
     (`https://www.peter-baumgartner.net/pressfreedom.data/`), configured
     intentionally via a `CNAME` file in the GitHub Pages repo. Updated
     `DESCRIPTION` and `_pkgdown.yml` to use the canonical custom-domain
     URL directly.

`urlchecker::url_check()` confirms all URLs now resolve correctly.

## Resubmission (2026-08-08): issues fixed from CRAN feedback

CRAN's initial review of 0.2.0 (Konstanze Lauseker) flagged five issues,
all now fixed:

1. **Missing web service link in `Description:`** -- added a sentence
   citing the RSF website in angle-bracket form
   (`<https://rsf.org>`).
2. **Missing `\value` tag** -- added to `print.rwb_update.Rd` (the
   exported S3 method), describing the invisible return and its side
   effect.
3. **Examples for unexported functions** (`download_rwb_data()`,
   `get_period()`, `get_years_to_download()`) -- removed their
   `\examples` blocks rather than exporting them; they are internal
   maintainer-only ETL helpers, not part of the public API.
4. **`\dontrun{}` usage** -- all `\dontrun{}` in the package lived inside
   the three `\examples` blocks removed in (3), plus one unnecessary
   `\dontrun{}` around the trivial, instant `rwb_standardized` dataset
   example, which has been unwrapped. The package now has zero
   `\dontrun{}` usage.
5. **Unconditional `cat()`/`print()` console output** -- `download_rwb_data()`
   now uses `message()` (suppressible via `suppressMessages()`) instead of
   `cat()`. `update_rwb_data()` already used `cli::cli_inform()`/`cli_warn()`
   gated by a `verbose` argument. `print.rwb_update()`'s `cat()` calls are
   unchanged, per CRAN's own carve-out for print methods.
6. **Functions writing to the package/home directory by default** --
   removed package-relative default arguments (e.g. `"inst/extdata"`,
   `here::here("data", "cleaned")`) from `download_rwb_data()`,
   `get_years_to_download()`, `clean_all_rwb_years()`,
   `combine_cleaned_periods()`, and
   `standardize_rwb_countries()`. These path arguments are now required
   (no default), so the functions never write to or read from a package
   or home directory implicitly. All internal call sites were updated to
   pass explicit paths. (`clean_rwb_single()` was already
   required-argument-only and needed no change.)

Verified locally: `devtools::check(cran = TRUE)` -- 0 errors | 0 warnings |
0 notes.

## Downstream dependencies

This is a new package with no reverse dependencies.

## Additional notes

* The package ships one exported dataset (`rwb_standardized`) as its
  public API; the download/clean/combine/standardize ETL pipeline used to
  build that dataset is implemented but intentionally unexported (internal
  maintainer tooling, documented in vignettes rather than the reference
  index).
* Two vignettes are included (`getting-started`, `visualizing-trends`)
  and build cleanly under `R CMD check --as-cran`.

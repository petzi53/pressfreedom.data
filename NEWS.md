# pressfreedom.data 0.2.0

## Package logo

* Replaced the hex sticker logo. The package now uses a gold circular badge
  containing a small white-on-teal data-grid icon, layered on the existing
  choropleth world map, to signal "data package" rather than "interactive
  tool." The previous design (same map, paired with a microphone icon) has
  been handed off to the companion `pressfreedom` Shiny app, which now shows
  the microphone inside an orange square badge instead. Both logos keep the
  same gold border, teal background, white text, and font so the two
  packages read as a family while remaining visually distinct -- including
  at favicon/thumbnail size, where the circular gold badge and the square
  orange badge are still easy to tell apart even when icon-level detail is
  no longer legible.

## Documentation

* Clarified the `rwb_` naming convention in `?rwb_standardized`: RSF
  (Reporters Sans Frontieres) is the organization's French legal name, while
  RWB (Reporters Without Borders) is its common English name -- the package
  uses the `rwb_` prefix throughout since it targets English-speaking users.

* De-duplicated README.md and `vignette("getting-started")`: each now owns
  a distinct job (README = install + minimal example; vignette = full
  walkthrough + FAQ), with the column dictionary consolidated at
  `?rwb_standardized` and citation information consolidated in a new
  `inst/CITATION` file (`citation("pressfreedom.data")`) instead of
  duplicated BibTeX blocks.

## Breaking changes

* The ETL/update functions are no longer part of the public API:
  `download_rwb_data()`, `clean_rwb_single()`, `clean_all_rwb_years()`,
  `combine_cleaned_periods()`, `consolidate_and_standardize_countries()`,
  `standardize_rwb_countries()`, `update_rwb_data()`, and its S3 print method
  `print.rwb_update()` are now unexported (internal). They remain in the
  package and are still fully documented, but no longer appear in
  `NAMESPACE`, the public help index, or are callable via `::`.

  The same demotion applies to 12 lower-level Phase B/D helper functions
  that these higher-level functions call internally: `clean_period_1()`,
  `clean_period_2()`, `clean_period_3()`, `convert_factors_to_character()`,
  `detect_csv_encoding()`, `detect_score_column()`, `get_period()`,
  `get_period_encoding()`, `get_years_to_download()`,
  `normalize_column_names()`, `resolve_percent_scaling()`, and
  `standardize_decimal_separators()`. `validate_standardization()` was
  already unexported and is now consistently marked internal as well.

  Rationale: these functions cannot work correctly against an installed/CRAN
  copy of the package (they hard-code `here::here()` paths that only resolve
  inside a development checkout, and `update_rwb_data()` performs a `git
  commit`), so exporting them as user-facing functions was misleading. This
  follows the standard CRAN data-package convention (e.g. `nycflights13`,
  `babynames`, `gapminder`) of keeping ETL/update logic out of the public
  API; the package's public interface is now just `data(rwb_standardized)`
  and its column documentation (`?rwb_standardized`).

  If you were previously calling any of these functions directly, they still
  work via the triple-colon operator for advanced/development use, e.g.
  `pressfreedom.data:::update_rwb_data()`. The maintainer's annual update
  workflow is now documented as a runbook script at
  `data-raw/update-data.R`.

* The `zone` column now uses English region names instead of RSF's original
  French labels, for consistency with every other column in
  `rwb_standardized` (`country_en`, `iso`, dimension names, etc.):

  | Old (French) | New (English) |
  |---|---|
  | `Afrique` | `Africa` |
  | `Ameriques` | `Americas` |
  | `Asie-Pacifique` | `Asia-Pacific` |
  | `EEAC` | `Eastern Europe & Central Asia` |
  | `MENA` | `Middle East & North Africa` |
  | `UE Balkans` | `EU & Balkans` |

  Any downstream code that filters or joins on the old French `zone` values
  (e.g. `zone == "MENA"`) will need to be updated to use the new English
  names. The translation is applied during standardization
  (`consolidate_and_standardize_countries()`), with the mapping stored in
  `inst/extdata/zone_mapping.csv`. A validation check now aborts the
  pipeline if any unrecognized `zone` value appears after translation.

  This also permanently resolves the recurring `zone` mojibake/encoding
  issue: none of the six English names contain diacritics, so there is
  nothing left for an upstream encoding glitch to corrupt.

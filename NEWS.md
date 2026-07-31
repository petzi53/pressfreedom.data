# pressfreedom.data 0.2.0

## Breaking changes

* The ETL/update functions are no longer part of the public API:
  `download_rwb_data()`, `clean_rwb_single()`, `clean_all_rwb_years()`,
  `combine_cleaned_periods()`, `consolidate_and_standardize_countries()`,
  `standardize_rwb_countries()`, `update_rwb_data()`, and its S3 print method
  `print.rwb_update()` are now unexported (internal). They remain in the
  package and are still fully documented, but no longer appear in
  `NAMESPACE`, the public help index, or are callable via `::`.

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

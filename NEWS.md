# pressfreedom.data 0.2.0

## Breaking changes

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

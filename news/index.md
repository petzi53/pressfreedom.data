# Changelog

## pressfreedom.data 0.2.0

### Breaking changes

- ETL/update functions
  ([`download_rwb_data()`](https://www.peter-baumgartner.net/pressfreedom.data/reference/download_rwb_data.md),
  [`clean_rwb_single()`](https://www.peter-baumgartner.net/pressfreedom.data/reference/clean_rwb_single.md),
  [`clean_all_rwb_years()`](https://www.peter-baumgartner.net/pressfreedom.data/reference/clean_all_rwb_years.md),
  [`combine_cleaned_periods()`](https://www.peter-baumgartner.net/pressfreedom.data/reference/combine_cleaned_periods.md),
  [`standardize_rwb_countries()`](https://www.peter-baumgartner.net/pressfreedom.data/reference/standardize_rwb_countries.md),
  [`update_rwb_data()`](https://www.peter-baumgartner.net/pressfreedom.data/reference/update_rwb_data.md),
  and related internal helpers) are no longer exported. They rely on a
  development checkout
  ([`here::here()`](https://here.r-lib.org/reference/here.html) paths,
  git operations) and were never usable from an installed copy of the
  package. The public API is now just the `rwb_standardized` dataset.
  Use `pressfreedom.data:::fun()` if you still need direct access.

- `zone` now uses English region names instead of RSF’s original French
  labels, e.g. `"MENA"` -\> `"Middle East & North Africa"`, `"Afrique"`
  -\> `"Africa"`. Update any code that filters or joins on the old
  French values (see
  [`?rwb_standardized`](https://www.peter-baumgartner.net/pressfreedom.data/reference/rwb_standardized.md)
  for the full mapping). This also fixes a recurring `zone`
  mojibake/encoding issue.

- Fixed `score_n_1` for 2023-2026 (720 rows), which was about 100x too
  large (e.g. `9265` instead of `92.65`) due to a missing
  decimal-scaling step. It’s now on the same 0-100 scale as `score`.
  Remove any manual rescaling workaround for these years.

### Documentation

- Clarified the `rwb_` naming convention (RSF vs. RWB) in
  [`?rwb_standardized`](https://www.peter-baumgartner.net/pressfreedom.data/reference/rwb_standardized.md).
- De-duplicated content between `README.md` and
  [`vignette("getting-started")`](https://www.peter-baumgartner.net/pressfreedom.data/articles/getting-started.md);
  consolidated citation info into `inst/CITATION`.

### Other

- New hex sticker logo, redesigned to be visually distinct from the
  companion `pressfreedom` Shiny app’s logo.

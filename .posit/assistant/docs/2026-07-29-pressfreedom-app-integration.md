# Plan: Integrate pressfreedom.data with pressfreedom App

**Date:** 2026-07-29  
**Author:** Posit Assistant  
**Status:** Ready for Review

---

## Overview

Set up the infrastructure to enable the pressfreedom package to load its dataset from pressfreedom.data (currently uses rwb-book as a temporary source). This involves:

1. Exporting the standardized dataset from pressfreedom.data as an R package dataset
2. Updating pressfreedom package dependencies to include pressfreedom.data
3. Modifying pressfreedom's `data-raw/rwb.R` to load from pressfreedom.data instead of rwb-book
4. Documenting the migration for future annual updates

---

## Current State

### pressfreedom.data (source)
- ✅ Phase A–D complete
- Output: `data/processed/rwb_standardized.rds` (4,192 rows, 191 countries, 22 columns)
- **Gap:** Dataset not exported as package data (no `data/rwb.rda`)
- Functions exist in `R/standardize.R` but no exported dataset object

### pressfreedom (app)
- Loads data from: `rwb-book` project → `../rwb-book/data/chap011/rwb/rwb.rds`
- Stores as: `data/rwb.rda` (via `usethis::use_data(rwb)`)
- Package dependencies: `shiny` (Imports), several viz/utility packages (Suggests)
- **Missing:** pressfreedom.data in dependencies
- Current dataset: 4,020 rows, 20 columns (legacy rwb-book structure)

---

## Key Differences: rwb_standardized vs Current rwb

| Aspect | Current `rwb` | New `rwb_standardized` |
|--------|---------------|------------------------|
| Rows | 4,020 | 4,192 |
| Columns | 20 | 22 |
| Countries | ~180 | 191 |
| New cols | None | `country_name_original`, `consolidation_flag` |
| Country names | Inconsistent (Russia, Czech Republic, etc.) | Standardized (Russian Federation, Czechia, etc.) |
| Cyprus handling | Cyprus, Cyprus North | Cyprus, Northern Cyprus |
| Data source | rwb-book | pressfreedom.data |

---

## Proposed Implementation

### Phase 0: Fix data-raw Structure in pressfreedom.data

**Location:** pressfreedom.data package

**Problem:** `data-raw/consolidation_mapping.csv` triggers R CMD check warnings (data-raw should only contain `.R` scripts)

**Solution:**
1. Move `data-raw/consolidation_mapping.csv` → `inst/extdata/consolidation_mapping.csv`
2. Update `R/standardize.R` function to load via `system.file()`:
   ```r
   consolidate_and_standardize_countries <- function(combined_df, consolidation_mapping = NULL) {
     if (is.null(consolidation_mapping)) {
       consolidation_mapping <- readr::read_csv(
         system.file("extdata", "consolidation_mapping.csv", 
                     package = "pressfreedom.data")
       )
     }
     # ... rest of function
   }
   ```
3. Run `devtools::check()` to confirm no warnings

**Why this matters:**
- `data-raw/` = Development-only scripts (`.R` files only)
- `inst/extdata/` = Package reference data (bundled with installed package)
- Binary/CSV files belong in `inst/extdata/`, accessed via `system.file()`
- Raw CSVs (Phase A) already in `inst/extdata/` — this aligns that structure

---

### Phase 1: Export Dataset from pressfreedom.data

**Location:** pressfreedom.data package (after Phase 0)

**Key decision:** Exported dataset will have 20 columns (audit columns removed). The RDS file retains all 22 columns for transparency.

1. **Create `data-raw/rwb_standardized.R`** — Script to prepare exported dataset
   ```r
   # Load the standardized RDS file (with 22 columns)
   rwb_standardized <- readRDS(here::here("data", "processed", "rwb_standardized.rds"))
   
   # Remove audit columns (keep only the 20-column structure for export)
   rwb_standardized <- rwb_standardized |>
     dplyr::select(-country_name_original, -consolidation_flag)
   
   # Ensure character types
   rwb_standardized <- rwb_standardized |>
     dplyr::mutate(
       iso = as.character(iso),
       country_en = as.character(country_en),
       zone = as.character(zone)
     )
   
   # Save as package data: data/rwb_standardized.rda
   usethis::use_data(rwb_standardized, overwrite = TRUE)
   ```

**Note:** The RDS file (`rwb_standardized.rds`) is not included in the package data/. Users who need the audit columns can load it directly via `readRDS()` if they have access to pressfreedom.data source code.

2. **Create `R/data.R`** — Documentation for exported dataset
   - Document the 20 columns (same as pressfreedom's current `rwb` documentation)
   - Note: Data spans 2002–2026 (2011 excluded), 191 countries
   - Reference Phase A–D pipeline in pressfreedom.data
   - Clarify that `country_name_original` and `consolidation_flag` are in RDS but not in package data

3. **Update `DESCRIPTION`**
   - Add LazyData: true (if not present)
   - Export data in NAMESPACE (via roxygen2)

4. **Build package**
   - `devtools::load_all()`
   - `devtools::document()`
   - Verify `rwb_standardized` is available as package data

---

### Phase 2: Update pressfreedom Package

**Location:** pressfreedom package

1. **Update `DESCRIPTION`**
   - Add `pressfreedom.data` to Imports (not Suggests)
   - Version constraint: `pressfreedom.data (>= 0.1.0)`
   - **Bump pressfreedom version:** 0.0.0.9001 → 0.1.0 (use `usethis::use_version("minor")`)

2. **Update `data-raw/rwb.R`**
   - Replace rwb-book loading and ALL corrections with pressfreedom.data loading:
     ```r
     # Load standardized data from pressfreedom.data
     # All data cleaning, corrections, and standardizations are handled
     # in pressfreedom.data (Phase A–D pipeline).
     rwb <- pressfreedom.data::rwb_standardized
     
     # Ensure character types (defensive coding)
     rwb <- rwb |>
       dplyr::mutate(
         iso = as.character(iso),
         country_en = as.character(country_en),
         zone = as.character(zone)
       )
     
     usethis::use_data(rwb, overwrite = TRUE)
     ```
   - **Remove:**
     - rwb-book path references
     - ALL country corrections (Russia → "Russian Federation", 2022 zone corrections, etc.)
     - Any data-specific adjustments
   - **Keep only:**
     - Type enforcement (character conversion)
     - Data verification checks (stopifnot)
   - Update comments to reference pressfreedom.data pipeline

3. **Update `R/data.R` Documentation**
   - Update row count to 4,192 (from 4,020)
   - Update country count to 191 (from ~180)
   - Update data source to: "pressfreedom.data package"
   - Note: Data now includes standardized country names (e.g., Czechia, Turkiye)

4. **Test App**
   - Run `devtools::load_all()`
   - Rebuild dataset with `source("data-raw/rwb.R")`
   - Launch Shiny app
   - Verify Map, Trends, Country views work correctly
   - Check that `rank_tier()` function handles 191 countries correctly

5. **Update App Comments**
   - Update `inst/app/app.R` comments if they reference rwb-book
   - Clarify that data now comes from pressfreedom.data

---

## Benefits

✅ **Single source of truth:** Data maintained in pressfreedom.data  
✅ **Reproducible:** Full pipeline documented and version-controlled  
✅ **Maintainable:** Annual updates handled in pressfreedom.data; pressfreedom just loads it  
✅ **Transparency:** Country standardization decisions visible in pressfreedom.data  
✅ **Decoupled:** pressfreedom.data independent; pressfreedom depends on it  

---

## Risk Considerations & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| New row count (4,192 vs 4,020) | rank_tier() buckets might shift | Test app with new data; verify buckets still meaningful |
| New columns in RDS but not exported | Downstream confusion | Document clearly that audit columns exist in RDS but not in package data |
| Removed temporal data fields | App breakage if code references them | Check if pressfreedom app uses `country_name_original` or `consolidation_flag` (unlikely) |
| pressfreedom.data version updates | pressfreedom suddenly breaks if dependency updates | Pin version in DESCRIPTION; update pressfreedom on release schedule |
| Cyprus vs Northern Cyprus names | Regional views might shift | Map might show "Cyprus" and "Northern Cyprus" instead of "Cyprus North"; update if needed |

---

## Implementation Order

**Phase 0: Fix pressfreedom.data structure**
1. **Phase 0a:** Move `data-raw/consolidation_mapping.csv` → `inst/extdata/consolidation_mapping.csv`
2. **Phase 0b:** Update `R/standardize.R` to load mapping via `system.file()`
3. **Phase 0c:** Run `devtools::check()` to verify no warnings

**Phase 1: Export dataset from pressfreedom.data**
4. **Phase 1a:** Create `data-raw/rwb_standardized.R` in pressfreedom.data
5. **Phase 1b:** Create `R/data.R` documentation in pressfreedom.data
6. **Phase 1c:** Update pressfreedom.data DESCRIPTION & NAMESPACE
7. **Phase 1d:** Build & verify pressfreedom.data exports `rwb_standardized`
8. **Phase 1e:** Commit Phase 0 & 1 changes

**Phase 2: Integrate into pressfreedom app**
9. **Phase 2a:** Update pressfreedom DESCRIPTION (add pressfreedom.data dependency)
10. **Phase 2b:** Update pressfreedom `data-raw/rwb.R`
11. **Phase 2c:** Update pressfreedom `R/data.R` documentation
12. **Phase 2d:** Rebuild pressfreedom data with `source("data-raw/rwb.R")`
13. **Phase 2e:** Test pressfreedom app (Map, Trends, Country)
14. **Phase 2f:** Commit & merge pressfreedom changes

---

## Future Annual Updates

Once integrated:

1. **May (or when RSF publishes new index):**
   - Update pressfreedom.data with new raw CSV
   - Run Phase A–D pipeline
   - Update pressfreedom.data version

2. **In pressfreedom.data:**
   - `source("data-raw/rwb_standardized.R")`
   - Rebuild package: `devtools::load_all()` → `devtools::document()` → `devtools::check()`

3. **In pressfreedom:**
   - Update pressfreedom.data dependency version in DESCRIPTION
   - `source("data-raw/rwb.R")`
   - `devtools::load_all()` → `devtools::check()`
   - Test app
   - Update version & release

**Expected time:** ~30 minutes annually

---

## User Decisions

1. **Audit columns:** ✅ Keep only in RDS file (exclude from exported dataset)
   - `country_name_original` and `consolidation_flag` remain in `rwb_standardized.rds` for auditability
   - Exported `rwb_standardized` dataset (in package) will have 20 columns only
   - Users who need audit trail can read RDS directly

2. **Corrections/adjustments:** ✅ Remove all corrections from pressfreedom app
   - All data cleaning and adjustments belong in pressfreedom.data
   - pressfreedom's `data-raw/rwb.R` will load pressfreedom.data output as-is (no modifications)
   - This means removing current Russia and 2022 zone corrections from pressfreedom
   - Implications: If app needs these corrections, add them to pressfreedom.data Phase D pipeline

3. **Breaking changes:** ✅ Acceptable (packages not yet public)
   - Row count: 4,020 → 4,192 ✓
   - Country count: ~180 → 191 ✓
   - Country names: Russia → Russian Federation, etc. ✓
   - No backward compatibility constraints needed

4. **Version bumping:** ✅ YES, bump to 0.1.0 (breaking changes documented)
   - pressfreedom.data: Keep at 0.1.0 (no change)
   - pressfreedom: Bump 0.0.0.9001 → 0.1.0
   - Reason: Documents data pipeline restructuring and breaking changes
   - Reference: See `.posit/assistant/docs/2026-07-29-versioning-during-development.md`

---

## Success Criteria

✅ pressfreedom.data exports `rwb_standardized` as package data  
✅ pressfreedom loads from pressfreedom.data (not rwb-book)  
✅ pressfreedom DESCRIPTION declares pressfreedom.data dependency  
✅ pressfreedom app runs without errors  
✅ Map, Trends, Country views display correctly  
✅ Documentation updated in both packages  
✅ No hardcoded rwb-book paths remain  

---

---

## Key Implementation Changes (User Decisions Applied)

### Correction Removal from pressfreedom App

The current `pressfreedom/data-raw/rwb.R` applies these corrections:
```r
# 1. Russia name change (2023+)
rwb <- rwb |>
  dplyr::mutate(
    country_en = dplyr::case_when(
      year_n >= 2023 & country_en == "Russia" ~ "Russian Federation",
      TRUE ~ country_en
    )
  )

# 2. 2022 zone corrections (40 + 13 + 19 countries)
rwb <- rwb |>
  dplyr::mutate(
    zone = dplyr::case_when(
      # ... 76 lines of zone logic for 2022
    )
  )
```

**Decision:** These corrections must be handled in pressfreedom.data, NOT pressfreedom.
- If app needs Russia correction: Add to pressfreedom.data Phase D standardization
- If app needs 2022 zone correction: Add to pressfreedom.data or document as-is data
- pressfreedom.data becomes single source of truth for all data decisions

**Action in Phase 2b:** Remove all correction logic from pressfreedom `data-raw/rwb.R`

---

## Appendix: data-raw/ vs inst/extdata/ Explanation

**Your observation was correct.** Here's why there's a difference:

### data-raw/ — Development-only directory
- Contains **scripts** (`.R` files) that create package data
- NOT included in the built package
- R CMD check **ignores `.R` scripts** here
- R CMD check **warns about data files** (CSV, RDS, etc.)
- Example: `pressfreedom/data-raw/rwb.R` (just a script — no warnings)

### inst/extdata/ — Package reference data directory
- Contains **data files** used by package functions
- **Included** in the built package
- R CMD check has **no warnings** for data files here
- Accessible via `system.file()` in R code
- Example: `pressfreedom.data/inst/extdata/*.csv` (reference data)

### Why consolidation_mapping.csv is problematic in data-raw/
- Currently in: `pressfreedom.data/data-raw/consolidation_mapping.csv`
- R CMD check sees CSV in `data-raw/` and warns (expects only `.R` scripts there)
- Should be in: `inst/extdata/consolidation_mapping.csv` (bundled with package)

### The fix for pressfreedom.data
1. Move mapping CSV to `inst/extdata/`
2. Load it in `R/standardize.R` via `system.file()` instead of `here::here()`
3. This makes it accessible to users who install the package and use the functions

### Why pressfreedom app doesn't complain
- `pressfreedom/data-raw/rwb.R` contains **only code** (no data files)
- R CMD check ignores `.R` scripts in `data-raw/`
- No warning because there are no data files to warn about

---

---

## Final Checklist Before Implementation

✅ **User decisions incorporated:**
- Audit columns excluded from exported dataset (RDS retains them)
- ALL corrections removed from pressfreedom app (handled in pressfreedom.data)
- Breaking changes accepted
- Version bump: 0.0.0.9001 → 0.1.0 (documents restructuring)

✅ **Plan scope:**
- **Phase 0:** Fix pressfreedom.data directory structure (consolidation_mapping.csv move)
- **Phase 1:** Export dataset from pressfreedom.data as package data (rwb_standardized)
- **Phase 2:** Update pressfreedom app to load from pressfreedom.data (remove corrections)

✅ **Implementation order clear:**
- 3 phases, 14 steps total
- Both pressfreedom.data and pressfreedom projects affected
- Sequential: Phase 0 → Phase 1 → Phase 2
- Testing at end of Phase 2

---

## Approval for Implementation

**Ready to proceed with Phase 0, 1, and 2?** I will implement sequentially, updating you after each major phase.

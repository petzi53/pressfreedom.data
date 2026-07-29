# Revised Plan: Data Downloading and Cleaning Pipeline for pressfreedom.data

**Date:** Sunday, July 26, 2026  
**Project:** pressfreedom.data R Package  
**Revision:** Separates download from cleaning (ISO standardization occurs in cleaning phase)

---

## Key Decisions & Rationale

### 1. Separation of Concerns
**Download Phase (Plan A — This Document):**
- Download raw CSV files from RSF
- Store as-is without modification
- Handle only network/file I/O errors
- Detect and skip missing year 2011

**Cleaning Phase (Plan B — Future):**
- Normalize column names across periods
- Handle encoding issues
- Standardize country names to support ISO code mapping
- Address structural differences (2002–2012 vs. 2013–2021 vs. 2022–2026)
- Create period-aware transformations

**Combination Phase (Plan C — Future):**
- Only after cleaning
- Combine cleaned datasets
- Add ISO 3166 codes using standardized country names
- Produce final `rwb_combined.rds`

**Rationale:**
- Each phase has a single responsibility
- Raw data is preserved for auditability
- Cleaning logic can be developed and tested independently
- Column structure variations are handled in a dedicated phase
- No risk of losing raw data if cleaning needs revision

---

## Observed Data Structure

### Period 1: 2002–2012 (Pre-2013)
**File:** `rwb2002.csv`, `rwb2013.csv` (before structural change)

**Properties:**
- Delimiter: `;` (semicolon)
- Encoding: `ISO-8859-1` (Latin-1)
- Columns: 16 fixed columns
- Column order (left-to-right):
  ```
  Year (N), ISO, Rank N, Score N, Score N without the exactions, 
  Score N with the exactions, Score exactions, Rank N-1, Score N-1, 
  Rank evolution, FR_country, EN_country, ES_country, AR_country, 
  FA_country, Zone
  ```

**Notes:**
- ISO 3166 codes already present in `ISO` column
- Score values are numeric (decimals use comma: `0,5`, `1,5`)
- Country names in 5 languages (FR, EN, ES, AR, FA)
- Score values before 2013 don't support cross-year comparison (ranks only within year)

### Period 2: 2013–2021
**File:** `rwb2013.csv` (after structural change)

**Properties:**
- Delimiter: `;` (semicolon)
- Encoding: `ISO-8859-1` (Latin-1)
- Columns: Same 16 as Period 1
- Column structure: Identical to Period 1

**Notes:**
- Starting point for comparable scores across years
- ISO codes already present in `ISO` column
- Score calculation changed (now 0–100 scale, supports cross-year comparison)
- Ranks N-1 and Rank evolution added (comparing to previous year)

### Period 3: 2022–2026 (Recent Major Structural Change)
**File:** `rwb2022.csv`, `rwb2026.csv`

**Properties:**
- Delimiter: `;` (semicolon)
- Encoding: `UTF-8` (or similar, note encoding issues in AR/FA columns — visible as `?` in 2026)
- Columns: 22–25 (varies by year!)
- Column order: Completely different from Periods 1–2
  ```
  ISO, Score, Rank, Political Context, Rank_Pol, 
  Economic Context, Rank_Eco, Legal Context, Rank_Leg, 
  Social Context, Rank_Soc, Safety, Rank_Saf, Zone, 
  Country_EN, Country_FR, Country_ES, Country_AR, Country_FA,
  Year (N), Rank N-1, Rank evolution
  [2022 only]
  
  [2026 adds:]
  Country_PT, Score N-1, Score evolution
  [2026 renames:]
  Score → Score 2026
  ```

**Notes:**
- Completely reorganized column structure
- Added score **dimensions** (Political, Economic, Legal, Social, Safety) — each has own rank
- New language: Portuguese (`Country_PT`) added in 2026
- Score naming changes per year (`Score 2026` instead of `Score`)
- Country columns reordered (EN first in 2022, FR first in 2026!)
- Encoding issues visible in non-Latin scripts (AR, FA columns)
- ISO codes still present in `ISO` column

---

## Implementation Plan

### Phase 1: Download Pipeline ✓ (KEEP EXISTING)

**Status:** Already implemented in `R/download.R`

**Functions:**
- `download_rwb_data()` — Download CSVs from RSF
- `get_years_to_download()` — Identify missing years
- `update_rwb_data()` — Convenience wrapper

**Updates Needed:**
1. Add proper `delim = ";"` and `locale = readr::locale(encoding = "ISO-8859-1")` to handle Period 1–2 files
2. For Period 3 (2022+): Use `delim = ";"` and UTF-8 encoding
3. Handle encoding detection: Check year → apply appropriate encoding
4. Save files without modification (as-is)

**No changes to file storage:**
- Raw files: `data/raw/rwb<year>.csv`
- Each file stored exactly as RSF provides it

---

### Phase 2: Data Cleaning Pipeline (NEW PLAN B — NOT YET IMPLEMENTED)

**Goal:** Normalize data structures so that combining becomes tractable

**Functions to Create:**
1. `detect_period(year)` — Determine which period a year belongs to (Pre-2013, 2013–2021, 2022+)
2. `clean_period_1(df, year)` — Transform 2002–2012 data
3. `clean_period_2(df, year)` — Transform 2013–2021 data
4. `clean_period_3(df, year)` — Transform 2022–2026 data
5. `clean_rwb_data(year, input_dir, output_dir)` — Unified cleaning dispatcher

**Cleaning Tasks (All Periods):**
- ✅ Detect period based on year
- ✅ Read with correct encoding
- ✅ Standardize country column name → always `country`
- ✅ Standardize country names (remove accents, fix encoding issues)
- ✅ Standardize score column name → always `score`
- ✅ Convert score decimal separator (`,` → `.`)
- ✅ Add `year` column explicitly
- ✅ Preserve ISO code from original `ISO` column as-is (don't regenerate)
- ✅ Keep only comparable columns:
  - Period 1: Drop, or handle separately (not comparable across years)
  - Period 2: `ISO, country, year, score, rank, zone` + metadata columns
  - Period 3: `ISO, country, year, score, rank, zone, dimensions...` + metadata columns

**Output Structure (Post-Cleaning):**
```
data/
├── raw/
│   ├── rwb2002.csv (original, unmodified)
│   ├── rwb2013.csv (original, unmodified)
│   ├── rwb2022.csv (original, unmodified)
│   ├── rwb2026.csv (original, unmodified)
│   └── ...
├── cleaned/
│   ├── period_1_cleaned/
│   │   ├── rwb2002_cleaned.rds
│   │   ├── rwb2003_cleaned.rds
│   │   └── ... (2002–2012)
│   ├── period_2_cleaned/
│   │   ├── rwb2013_cleaned.rds
│   │   ├── rwb2014_cleaned.rds
│   │   └── ... (2013–2021)
│   ├── period_3_cleaned/
│   │   ├── rwb2022_cleaned.rds
│   │   ├── rwb2023_cleaned.rds
│   │   └── ... (2022–2026)
└── processed/
    └── (combined output — created in Phase 3)
```

**Why Separate Cleaned Directories?**
- Preserves traceability
- Makes it clear which data can be combined (Period 2+ is comparable across years)
- Period 1 may need special handling or exclusion from cross-year comparisons
- Allows independent testing and validation per period

---

### Phase 3: Data Combination & ISO Standardization (NEW PLAN C — NOT YET IMPLEMENTED)

**Goal:** Combine cleaned, normalized datasets

**Functions to Create:**
1. `get_special_country_mappings()` — Already exists, but now used after cleaning
2. `combine_cleaned_rwb_data()` — Combine cleaned period datasets
3. `add_iso_codes_final()` — Add ISO 2/3 codes using standardized country names

**Combination Strategy:**
- Read cleaned files from `data/cleaned/period_*/`
- Bind by rows (only Period 2+ combined, or Period 1 excluded, depending on use case)
- Country names are now normalized → reliable ISO code mapping
- Add `iso3` and `iso2` columns using `countrycode` + special mappings

**Output:**
```
data/processed/rwb_combined.rds
```

Contains:
- All rows from cleaned datasets
- Columns: `ISO, country, year, score, rank, zone, iso3, iso2, [dimensions if Period 3], ...`
- ~180+ rows per year × 24 years = ~4,300 rows total (if all years included)

---

## Targets Pipeline Integration

**Current `_targets.R` (to be updated):**

```r
# Phase 1: Download
tar_target(years_to_download, 2002:2026)
tar_target(
  raw_csvs,
  download_rwb_data(years_to_download, output_dir = here::here("data", "raw"))
)

# Phase 2: Clean (NEW)
tar_target(
  cleaned_data,
  {
    # Apply cleaning to all raw CSVs
    # Creates files in data/cleaned/period_*/
    clean_all_years(input_dir = here::here("data", "raw"),
                    output_dir = here::here("data", "cleaned"))
  },
  format = "file"
)

# Phase 3: Combine (NEW)
tar_target(
  rwb_combined,
  combine_cleaned_rwb_data(
    input_dir = here::here("data", "cleaned"),
    output_file = here::here("data", "processed", "rwb_combined.rds")
  ),
  format = "file"
)
```

---

## Implementation Order

### Plan A (This Document): Download Phase
1. ✅ Update `R/download.R` with correct encoding handling per period
2. ✅ Add period detection helper
3. ✅ Test downloading 2–3 sample years across periods
4. ✅ Verify files saved as-is (unmodified)

### Plan B (Future): Cleaning Phase
1. Create `R/clean.R` with period-aware cleaning functions
2. Create `R/utils.R` extensions for period detection, name standardization
3. Add unit tests for each period's cleaning logic
4. Generate cleaned files in `data/cleaned/period_*/`

### Plan C (Future): Combination Phase
1. Create/update `R/combine.R` for cleaned data combination
2. Update ISO mapping to work with standardized country names
3. Update `_targets.R` with full pipeline
4. Final testing and validation

---

## Key Technical Decisions

| Decision | Rationale |
|----------|-----------|
| **Raw files unchanged** | Preserves data integrity, allows re-cleaning if logic changes |
| **Separate cleaned dirs** | Clear separation of periods, supports period-specific analysis |
| **Encoding handling** | ISO-8859-1 for 2002–2021, UTF-8 for 2022+ (auto-detect by year) |
| **Period detection** | Based on year alone (simple, deterministic) |
| **Country name standardization** | Critical for reliable ISO code mapping later |
| **ISO codes preserved from raw** | Use existing `ISO` column, don't re-derive |
| **Dimensions kept separate** | Period 3 (2022+) dimensions stored as additional columns; Period 1–2 don't have them |

---

## Deliverables This Phase (Plan A: Download)

1. ✅ Updated `R/download.R` with encoding detection
2. ✅ Helper function: `get_period_encoding(year)` in `R/utils.R`
3. ✅ Updated tests: `tests/testthat/test-download.R`
4. ✅ Raw CSV files in `data/raw/` (untouched from RSF)
5. ✅ Updated DESCRIPTION & NAMESPACE (if needed)

---

## Notes for Future Plans

**Plan B (Cleaning):**
- Will need to define "country name standardization" rules (accents, case, etc.)
- May discover additional column discrepancies within periods (2022 vs. 2026 score naming)
- Consider whether Period 1 data should be included in final combination or separate

**Plan C (Combination):**
- Country name standardization must occur before ISO mapping
- May need manual lookup table for ambiguous names across periods
- Consider user documentation about Period 1 data limitations

---

## Approval Checkpoint

This plan:
- ✅ Separates download, clean, and combine phases
- ✅ Acknowledges structural differences across three periods
- ✅ Preserves raw data integrity
- ✅ Provides clear implementation sequence
- ✅ Addresses encoding, column naming, and score format issues
- ✅ Supports tidyverse/dplyr approach (to be applied in cleaning phase)

**Next steps:** Implement Plan A (Download) following these specifications, then create Plan B (Cleaning) once data structure nuances are fully understood.

# Phase D: Country Name Standardization

**Date:** July 28, 2026  
**Project:** pressfreedom.data R Package  
**Objective:** Standardize country names and ISO codes in the combined dataset

---

## Overview

**Phase D** applies standardization to the combined dataset from Phase C. This single pass handles:
- Country name normalization (remove accents, fix encoding)
- Special country cases (Taiwan, Kosovo, Palestine, Hong Kong)
- ISO 3-letter code mapping via `countrycode` package
- Validation of results

---

## Workflow

**Input:** `data/processed/rwb_combined.rds`
- 4,200 rows across 24 years
- 207 unique country entries
- 20-column structure from Phase B/C

**Output:** `data/processed/rwb_standardized.rds`
- Same structure as input
- Standardized country names
- Validated ISO codes

---

## Standardization Tasks

### 1. Country Name Normalization

**Remove accents and standardize encoding:**
- "Côte d'Ivoire" → "Cote d'Ivoire"
- "Réunion" → "Reunion"
- Handle other diacriticals

**Convert to proper case if needed**

### 2. Special Country Handling

Handle non-standard or ambiguous country names:
- Taiwan (may appear as "Taiwan", "Chinese Taipei", or similar)
- Kosovo (may appear as "Kosovo", "Kosovo*", or similar)
- Palestine (may appear as "Palestine", "Palestinian Territory", etc.)
- Hong Kong (SAR status)
- Other cases as needed

### 3. ISO Code Assignment

**Method:**
- Use `countrycode::countrycode()` package
- Map standardized `country_en` to ISO 3-letter codes
- Create lookup table for special cases before main conversion

**Validation:**
- All rows should have valid ISO codes after standardization
- No unmatched countries
- Log any mismatches for review

### 4. Output Validation

- All 4,200 rows preserved
- 20 columns intact
- No missing critical values (year_n, iso, country_en, score, rank)
- Unique year_n + country_en combinations

---

## Implementation

### Function Structure

**Main function:** `standardize_rwb_countries(input_file, output_file)`

**Helper functions:**
- `normalize_country_names(df)` — Remove accents, fix encoding
- `handle_special_countries(df)` — Map special cases
- `assign_iso_codes(df)` — Use countrycode package
- `validate_standardization(df)` — Check output quality

### Package Dependencies
- `countrycode` — ISO code mapping
- `stringi` — Unicode/accent handling (if needed)

---

## Error Handling

**If countrycode matching fails:**
1. Log unmatched countries
2. Attempt manual lookup for common variations
3. Review and report to user
4. Create custom mapping for persistent mismatches

---

## Output Quality Checks

- Row count: 4,200 (same as input)
- Column count: 20 (same as input)
- Column names: Unchanged
- Data types: Unchanged
- Missing y_n: 0
- Missing iso: 0
- Missing country_en: 0
- Unmatched countries: 0 (or documented)

---

## Next Steps

After Phase D:
- Final dataset: `data/processed/rwb_standardized.rds`
- Ready for analysis, modeling, or export
- All countries standardized and matched to ISO codes

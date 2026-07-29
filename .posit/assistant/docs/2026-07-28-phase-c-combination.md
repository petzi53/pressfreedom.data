# Phase C: Data Combination

**Date:** July 28, 2026  
**Status:** Complete  
**Output:** `data/processed/rwb_combined.rds`

---

## Objective

Combine all 23 normalized RDS files from Phase B (Periods 1, 2, and 3) into a single unified dataset ready for Phase D (Country Standardization).

---

## Implementation

### Function: `combine_cleaned_periods()`

**Location:** `R/combine.R`

**Purpose:** Read all RDS files from period subdirectories, row-bind, validate, and save combined file.

**Features:**
- Reads all files from `data/cleaned/period_1/`, `period_2/`, `period_3/`
- Row-binds maintaining structure
- Sorts by `year_n` and `country_en` for consistency
- Verifies output against 20-column structure
- Creates output directory if needed
- Provides progress messaging

---

## Output Specifications

### File
`data/processed/rwb_combined.rds`

### Dimensions
- **4,200 rows** (180–207 countries per year × 24 years)
- **20 columns** (unified structure)
- **File size:** ~74 KB

### Content
- **Year range:** 2002–2026 (24 years; 2011 intentionally missing)
- **Countries:** 207 unique entries
- **Sorted by:** `year_n` ascending, then `country_en` alphabetically

### Column Structure
```
year_n, iso, country_en, score, rank,
political_context, rank_pol, economic_context, rank_eco,
legal_context, rank_leg, social_context, rank_soc,
safety, rank_saf, zone, rank_n_1, rank_evolution,
score_n_1, score_evolution
```

---

## Data Quality Summary

| Metric | Value |
|--------|-------|
| Total rows | 4,200 |
| Years | 2002–2026 (24 years) |
| Countries | 207 unique |
| Missing year_n | 0 |
| Missing iso | 0 |
| Missing country_en | 0 |

### Missing Values by Period

**Period 1 (2002–2012):** 1,681 rows
- Dimension columns: All NA
- score_evolution: All NA
- Ranks/scores: All populated ✓

**Period 2 (2013–2021):** 1,619 rows
- Dimension columns: All NA
- score_evolution: All NA
- Ranks/scores: All populated ✓

**Period 3 (2022–2026):** 900 rows
- Dimensions: All populated ✓
- score_evolution:
  - 2022: All NA (by design)
  - 2023–2026: All populated ✓
- Ranks/scores: All populated ✓

---

## Next Step: Phase D

**Input:** `data/processed/rwb_combined.rds`  
**Output:** `data/processed/rwb_standardized.rds`

**Scope:**
1. Standardize country names
2. Handle special countries (Taiwan, Kosovo, Palestine, etc.)
3. Add standardized ISO 3-letter codes
4. Validate results

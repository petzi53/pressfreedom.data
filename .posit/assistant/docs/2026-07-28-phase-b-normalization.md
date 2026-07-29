# Phase B: Column Name Normalization

**Date:** July 28, 2026  
**Project:** pressfreedom.data R Package  
**Objective:** Normalize column names across all three periods to match the target database structure with consistent data types

---

## Overview

**Phase B** normalizes column names and data types across Periods 1, 2, and 3 to achieve a consistent 20-column structure as defined in `dev/rwb-structure.csv`.

**Workflow:**
- **Phase B** (current): Normalize periods separately
- **Phase C:** Combine normalized periods into single dataset
- **Phase D:** Standardize country names and codes

---

## Target Structure

**Total: 20 columns**

| Column | Data Type | Notes |
|--------|-----------|-------|
| `year_n` | numeric | Year of publication |
| `iso` | character | ISO 3166-1 alpha-3 code |
| `country_en` | character | English country name |
| `score` | numeric | Overall press freedom score |
| `rank` | numeric | Overall rank in that year |
| `political_context` | numeric | Political dimension score |
| `rank_pol` | numeric | Political dimension rank |
| `economic_context` | numeric | Economic dimension score |
| `rank_eco` | numeric | Economic dimension rank |
| `legal_context` | numeric | Legal dimension score |
| `rank_leg` | numeric | Legal dimension rank |
| `social_context` | numeric | Social dimension score |
| `rank_soc` | numeric | Social dimension rank |
| `safety` | numeric | Safety dimension score |
| `rank_saf` | numeric | Safety dimension rank |
| `zone` | character | Geographic zone |
| `rank_n_1` | numeric | Previous year's rank |
| `rank_evolution` | numeric | Rank change from previous year |
| `score_n_1` | numeric | Previous year's score (NA for Period 1–2 and 2022) |
| `score_evolution` | numeric | Score change from previous year (NA for Period 1–2 and 2022) |

---

## Period-Specific Processing

### Period 1: 2002–2012

**Input:** 16 raw columns (ISO-8859-1 encoding, semicolon-delimited)

**Key Transformations:**
- Map 16 raw columns to 9 normalized columns
- Convert comma decimals to periods
- Convert factors to character (iso, country_en, zone)
- Add 10 dimension columns as NA (not available in Period 1)
- Add score_evolution as NA (not available in Period 1)
- Handle 2012 special case: raw file contains "2011-12" → convert to year 2012

**Output:** 20 columns, all dimensions and score_evolution as NA

### Period 2: 2013–2021

**Input:** 16 raw columns (identical to Period 1; ISO-8859-1 encoding)

**Key Transformations:**
- Identical to Period 1 processing
- Convert comma decimals to periods
- Convert factors to character
- Add 10 dimension columns as NA
- Add score_evolution as NA

**Output:** 20 columns, all dimensions and score_evolution as NA

### Period 3: 2022–2026

**Input:** 22–25 columns (UTF-8 encoding, year-specific score naming in 2025–2026)

**Key Transformations:**
- Handle year-specific score naming (Score 2025, Score 2026 → score)
- Drop Situation column (2024+)
- Convert factors to character
- Apply decimal separator conversion to all numeric columns including score_evolution
- 2022: score_n_1 and score_evolution are NA (no 2021 data to compare)
- 2023+: All columns populated

**Output:** 20 columns, dimensions populated, score_evolution populated (2023+)

---

## Implementation Details

### Reading Raw Data

**Period 1 & 2:**
```r
readr::read_delim(
  filepath,
  delim = ";",
  col_types = readr::cols(.default = readr::col_character()),
  locale = readr::locale(encoding = "ISO-8859-1")
)
```

**Period 3:**
```r
readr::read_delim(
  filepath,
  delim = ";",
  col_types = readr::cols(.default = readr::col_character()),
  locale = readr::locale(encoding = "UTF-8")
)
```

### Decimal Separator Conversion

**Period 1 & 2:** Convert comma to period in numeric columns (Score N, Rank N, Score N-1, Rank N-1, Rank evolution)

**Period 3:** Convert comma to period in all numeric columns including score_evolution (handles 2023+ data)

### Factor to Character Conversion

Columns: `iso`, `country_en`, `zone` — preserve original values exactly, no level loss

---

## Data Quality Notes

### Missing Data Patterns

**Period 1 (2002–2012):** All dimension columns (political_context through rank_saf) and score_evolution are NA — these were not available in Period 1

**Period 2 (2013–2021):** All dimension columns and score_evolution are NA — same as Period 1 despite methodology improvements

**Period 3 (2022–2026):** 
- All dimension columns populated
- score_evolution: 2022 has all NA (no 2021 data); 2023+ populated
- All score and rank columns populated

### Special Cases Handled

1. **2012 year_n:** Raw file contains "2011-12" (text) → converts to NA → filled with year 2012 from parameter
2. **2025–2026 score column:** Raw columns named "Score 2025", "Score 2026" → normalized to "score"
3. **2024+ Situation column:** Dropped during processing (not in target structure)

---

## Functions in R/clean.R

### `clean_period_1(filepath, year)`
- Reads Period 1 raw CSV with ISO-8859-1 encoding
- Applies decimal separator conversion
- Maps 16 columns to 9, adds NA columns for dimensions
- Handles 2012 special case (year_n inference)
- Returns 20-column data frame

### `clean_period_2(filepath, year)`
- Reads Period 2 raw CSV with ISO-8859-1 encoding
- Identical processing to Period 1
- Returns 20-column data frame

### `clean_period_3(filepath, year)`
- Reads Period 3 raw CSV with UTF-8 encoding
- Drops Situation column if present
- Applies decimal separator conversion to all numeric columns (including score_evolution)
- Handles year-specific score naming
- Returns 20-column data frame

### `clean_rwb_single(filepath, year, output_dir)`
- Dispatcher: detects period from year, calls appropriate cleaner
- Validates output structure (20 columns, correct names and order)
- Saves as RDS file
- Returns output filepath

### `clean_all_rwb_years(input_dir, output_dir)`
- Batch processor: finds all rwb*.csv files
- Calls clean_rwb_single() for each year
- Creates period-specific subdirectories (period_1/, period_2/, period_3/)
- Returns processing summary

---

## Output Structure

```
data/cleaned/
├── period_1/
│   ├── rwb2002_cleaned.rds
│   ├── rwb2003_cleaned.rds
│   └── ... (11 files: 2002–2012)
├── period_2/
│   ├── rwb2013_cleaned.rds
│   ├── rwb2014_cleaned.rds
│   └── ... (9 files: 2013–2021)
└── period_3/
    ├── rwb2022_cleaned.rds
    ├── rwb2023_cleaned.rds
    ├── rwb2024_cleaned.rds
    ├── rwb2025_cleaned.rds
    └── rwb2026_cleaned.rds
```

**Total:** 25 RDS files (one per year, 2002–2026 excluding 2011)

---

## Testing

Test coverage in `tests/testthat/test-clean.R`:

1. **Column normalization** — Raw columns correctly renamed and dropped
2. **Decimal conversion** — Comma decimals converted to periods in all numeric columns
3. **Factor to character** — iso, country_en, zone converted without value loss
4. **Year-specific score naming** — 2025–2026 score columns correctly renamed
5. **Output structure** — Exactly 20 columns, correct order, correct data types
6. **Period-specific handling** — Dimension columns NA for Periods 1–2; populated for Period 3
7. **Special cases** — 2012 year_n filled, 2022 score_evolution NA, Situation column dropped
8. **Edge cases** — Missing values preserved, empty rows handled

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Period-specific subdirectories** | Clear separation; maintains auditability |
| **20-column unified structure** | Simplifies downstream combination and processing |
| **Character not factor** | Avoids unintended level ordering; matches user requirement |
| **Decimal conversion for all numeric columns in Period 3** | Ensures score_evolution in 2023+ is numeric, not character |
| **Infer year_n for 2012 from parameter** | Handles raw data quirk ("2011-12") directly in cleaner |
| **Keep raw files** | Auditability; allows re-cleaning if logic changes |

---

## Next Steps

After Phase B completion:
1. Proceed to Phase C (Combination): merge all three periods into single rwb_combined.rds
2. Then Phase D (Standardization): normalize country names and ISO codes

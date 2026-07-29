# Plan Revision: Optimal Sequencing of Normalization, Combination, and Standardization

**Date:** Tuesday, July 28, 2026, 17:03 CEST  
**Project:** pressfreedom.data R Package  
**Decision Point:** Should we combine normalized datasets before Plan B2 (country standardization)?  
**User Suggestion:** Yes — combine after B1 normalization, before B2 standardization

---

## Executive Summary

**Your Observation (User's Suggestion):**

In the current plan:
- **Phase C** (Combination) happens *after* Plan B2 (Country Standardization)
- Current sequence: B1 (Normalization) → B2 (Country Standardization) → C (Combination)

**Your Proposal:**
- Combine the three periods *immediately* after B1 normalization (same column names, same types)
- This creates `rwb_combined.rds` with all periods unified
- Then apply B2 standardization to the combined dataset once, rather than three times

**Recommended New Sequence:** B1 → **C (Early Combination)** → B2

---

## Current State (Plan B1 ✅ Completed)

**What's Done:**
- ✅ All three periods normalized to identical 20-column structure
- ✅ Column names standardized (snake_case)
- ✅ Data types standardized (factors → character for iso, country_en, zone)
- ✅ Files stored in `data/cleaned/period_1/`, `period_2/`, `period_3/`
- ✅ 23 cleaned RDS files (2002–2026, excluding 2011)

**Current File Structure:**
```
data/cleaned/
├── period_1/  (11 files: 2002–2012)
├── period_2/  (9 files: 2013–2021)
└── period_3/  (5 files: 2022–2026)
```

**Current Output:** Separate period directories

---

## Analysis: Why Combine Early?

### Advantages of Early Combination (Your Suggestion)

| Advantage | Explanation |
|-----------|-------------|
| **Single standardization pass** | Apply B2 (country names, special cases) once to combined data, not three separate times |
| **Eliminates redundancy** | No need to write standardization logic three times (once per period) |
| **Simpler logic** | Country standardization logic is identical across periods; easier to maintain one version |
| **Better auditability** | Easier to track which rows were standardized (single pass with logging) |
| **Clearer workflow** | Phases are: Normalize → Combine → Standardize → Final output |
| **Smaller code footprint** | B2 becomes simpler: one function (`standardize_rwb_countries()`) instead of three |
| **Easier testing** | Test country standardization once against combined data, not per-period |

### Potential Concerns (and Counter-Arguments)

| Concern | Response |
|---------|----------|
| **Lose period separation** | Period metadata still available in `year_n` column for filtering; can always split later if needed |
| **File size** | Combined RDS (all rows, all years) is small (~100–150 KB); not a storage concern |
| **Intermediate debugging** | Can always save combined file before standardization; easy to restore periods from combined if needed |
| **Separation of concerns** | Actually improved: each phase has single output (not three period-specific outputs) |

---

## Recommended Plan Revision

### New Sequencing

#### Phase B1: Column Normalization ✅ (Already Done)
- **Status:** Complete
- **Output:** `data/cleaned/period_1/`, `period_2/`, `period_3/` (normalized, separate)
- **Next:** Proceed to Phase C (Early Combination)

#### Phase C (Early): Data Combination → `rwb_combined.rds`
- **When:** Immediately after B1
- **Input:** All 23 cleaned RDS files from `data/cleaned/period_*/`
- **Process:**
  1. Read all files from all three periods
  2. Row-bind into single data frame
  3. Verify combined structure (all 20 columns present)
  4. Save as `data/processed/rwb_combined.rds`
- **Output:** Single combined file with all 4,300+ rows (23 years × ~180–185 countries per year)
- **Advantages:**
  - Single file for downstream standardization
  - No period-specific logic needed in B2
  - Clearer pipeline

#### Phase B2: Country Name Standardization (Revised)
- **When:** After Phase C (Early Combination)
- **Input:** `data/processed/rwb_combined.rds`
- **Process:**
  1. Read combined data
  2. Standardize country names (handle accents, encoding, special cases)
  3. Handle special countries (Taiwan, Kosovo, Palestine, etc.)
  4. Add ISO 3-letter codes using standardized names
  5. Save as `data/processed/rwb_standardized.rds` (or overwrite combined)
- **Output:** Final cleaned, standardized dataset
- **Advantages:**
  - Single pass over all data
  - Simpler logic (not repeated per-period)
  - Easier to validate results

---

## Implementation Steps for Plan B2 (Revised)

### Step 1: Create Early Combination Function
**File:** `R/combine.R` (new or update existing)

```r
combine_cleaned_periods <- function(
    input_dir = here::here("data", "cleaned"),
    output_file = here::here("data", "processed", "rwb_combined.rds")
) {
  # Read all RDS files from period_1, period_2, period_3
  # Row-bind them
  # Verify structure
  # Save to output_file
  # Return output_file path
}
```

**Inputs:**
- `data/cleaned/period_1/rwb*.rds` (11 files)
- `data/cleaned/period_2/rwb*.rds` (9 files)
- `data/cleaned/period_3/rwb*.rds` (5 files)

**Output:**
- `data/processed/rwb_combined.rds` (single file, all rows)

**Verification:**
- Total rows: ~4,300–4,400 (180–185 countries × 24 years)
- Columns: 20 (verify all present)
- No duplicates
- No missing year_n values

---

### Step 2: Revise Plan B2
**Create New Plan Document:** `2026-07-28-B2-revised-standardization.md`

**Scope (Simplified):**
1. Read `rwb_combined.rds`
2. Standardize country names in `country_en` column:
   - Remove accents (e.g., "Côte d'Ivoire" → "Cote d'Ivoire")
   - Fix encoding issues (AR, FA columns already dropped in B1)
   - Handle special cases:
     - Taiwan / "Taiwan"
     - Kosovo / "Kosovo"
     - Palestine / "Palestine"
     - Hong Kong (if present)
     - Etc.
3. Use standardized names to map ISO 3-letter codes (via `countrycode` package)
4. Save as `data/processed/rwb_standardized.rds`

**Key Simplifications:**
- No period-specific logic needed
- Single standardization function (not three)
- Single pass over all rows
- Easier to test and validate

---

### Step 3: Update `_targets.R`
**New Pipeline:**

```r
# Phase 1: Download
tar_target(
  raw_csvs,
  download_rwb_data(
    years = 2002:2026,
    output_dir = here::here("data", "raw")
  ),
  format = "file"
)

# Phase B1: Normalize (already done, kept as target for reproducibility)
tar_target(
  cleaned_data,
  clean_all_rwb_years(
    input_dir = here::here("data", "raw"),
    output_dir = here::here("data", "cleaned")
  ),
  format = "file"
)

# Phase C (Early): Combine
tar_target(
  rwb_combined,
  combine_cleaned_periods(
    input_dir = here::here("data", "cleaned"),
    output_file = here::here("data", "processed", "rwb_combined.rds")
  ),
  format = "file",
  depends_on = cleaned_data
)

# Phase B2: Standardize
tar_target(
  rwb_standardized,
  standardize_rwb_countries(
    input_file = here::here("data", "processed", "rwb_combined.rds"),
    output_file = here::here("data", "processed", "rwb_standardized.rds")
  ),
  format = "file",
  depends_on = rwb_combined
)
```

---

## Revised File Structure

### Before (Current Plan: B1 → B2 → C)
```
data/
├── raw/
│   ├── rwb2002.csv
│   ├── rwb2003.csv
│   └── ... (23 files)
├── cleaned/
│   ├── period_1/
│   │   ├── rwb2002_cleaned.rds
│   │   └── ... (11 files)
│   ├── period_2/
│   │   ├── rwb2013_cleaned.rds
│   │   └── ... (9 files)
│   └── period_3/
│       ├── rwb2022_cleaned.rds
│       └── ... (5 files)
└── processed/
    └── (empty at this stage)
```

### After (Revised Plan: B1 → C → B2)
```
data/
├── raw/
│   ├── rwb2002.csv
│   ├── rwb2003.csv
│   └── ... (23 files)
├── cleaned/
│   ├── period_1/
│   │   ├── rwb2002_cleaned.rds
│   │   └── ... (11 files)
│   ├── period_2/
│   │   ├── rwb2013_cleaned.rds
│   │   └── ... (9 files)
│   └── period_3/
│       ├── rwb2022_cleaned.rds
│       └── ... (5 files)
└── processed/
    ├── rwb_combined.rds            ← NEW: Early combination (Phase C)
    └── rwb_standardized.rds        ← Final output (Phase B2)
```

---

## Summary of Changes

| Aspect | Original Plan (B1→B2→C) | Revised Plan (B1→C→B2) |
|--------|---------|---------|
| **Order** | Normalize each period → Standardize each period → Combine | Normalize periods → Combine once → Standardize once |
| **B2 Logic** | Period-specific (3 functions) | Unified (1 function) |
| **Intermediate Files** | `period_*/` dirs + standardized variants | `period_*/` dirs → combined → standardized |
| **B2 Testing** | Test per-period standardization | Test standardization on full combined data |
| **Maintenance** | Harder (logic duplicated) | Easier (single standardization function) |
| **Output** | `data/processed/rwb_standardized.rds` | `data/processed/rwb_standardized.rds` (same, cleaner path) |

---

## Action Items

### Immediate (Plan Approval)
1. ✅ Review revised plan
2. ✅ Confirm agreement with early combination approach
3. ✅ Approve sequencing: B1 ✅ → C (new early phase) → B2 (revised)

### Implementation (If Approved)
1. Create `R/combine.R` with `combine_cleaned_periods()` function
2. Execute early combination to create `rwb_combined.rds`
3. Create revised Plan B2 document (`2026-07-28-B2-revised-standardization.md`)
4. Implement Plan B2 with unified standardization function
5. Update `_targets.R` to reflect new sequencing
6. Test entire pipeline: Download → B1 (Normalize) → C (Combine) → B2 (Standardize)

---

## Decision Point for User

**Questions for Approval:**

1. ✅ Does the revised sequencing (B1 → C → B2) align with your suggestion?
2. ✅ Should we proceed with early combination before country standardization?
3. ✅ Are you comfortable with the simplified B2 (unified function instead of per-period)?
4. ✅ Should we keep `data/cleaned/period_*/` after combination (for reproducibility), or remove them after creating combined file?

---

## Notes

- **B1 is complete:** No changes needed to normalization
- **Period structure preserved:** Year information still available via `year_n` column if future period-specific analysis is needed
- **Auditability maintained:** All raw files preserved, all steps reproducible
- **Code simplification:** B2 becomes more maintainable with unified standardization logic


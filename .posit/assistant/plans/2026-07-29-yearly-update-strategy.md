# Plan: Specialized Yearly Update Function Strategy

**Date:** 2026-07-29  
**Project:** pressfreedom.data  
**Context:** Peter's observation that the original specialized yearly update approach (via `dev/update_data.R`) has been lost after recent restructuring. Evaluate whether a dedicated `update_rwb_data()` function is viable and whether {targets} is still necessary.

---

## 1. THE ORIGINAL DESIGN (Git History)

### What Existed
Two files in the now-deleted `dev/` folder:

1. **`dev/update_data.R`** (commit 1690ea1)
   - Specialized script for annual incremental downloads
   - Detected missing years automatically
   - Downloaded only new years (no re-processing of historical data)
   - Reported year range dynamically

2. **`dev/ANNUAL_UPDATE_PROCEDURE.md`** (commit 3da1aa1)
   - Step-by-step workflow documentation
   - Emphasized: "No code changes needed annually—fully automated"
   - Four-step process: Download → Verify → Commit → Prepare for cleaning

### Key Design Philosophy
**Minimal disruption principle:** Only new data gets downloaded/cleaned; historical years are never re-processed unless country consolidations change.

---

## 2. CURRENT STATE: WHAT CHANGED?

### What's Gone
- `dev/` folder (deleted)
- Specialized update scripts (archived in git only)

### What Remains
All underlying infrastructure is intact:
- ✅ `get_years_to_download()` — Smart detection of missing years (utils.R)
- ✅ `download_rwb_data()` — Phase A download function
- ✅ `clean_rwb_single()` — Phase B cleaning for individual years
- ✅ `combine_cleaned_periods()` — Phase C combination (recalculates evolution columns)
- ✅ `standardize_rwb_countries()` — Phase D standardization
- ✅ `consolidation_mapping.csv` — Centralized country name rules
- ✅ `data-raw/rwb_standardized.R` — Export to package format

### Current Gap
No high-level function orchestrating the yearly workflow. Users must manually call 5 separate functions and understand which ones can/cannot be skipped.

---

## 3. CRITICAL INSIGHT: WHAT CAN TRULY BE SKIPPED?

### ❌ **Cannot Skip (Always Must Run)**

**Phase C: `combine_cleaned_periods()`**
- **Why:** Evolutionary columns (`rank_n_1`, `score_n_1`, `rank_evolution`, `score_evolution`) are calculated from *previous year's data*
- **Impact:** When adding year N, values for year N-1 shift (it becomes N-2's "previous")
- **Required logic:** Must recalculate entire combined dataset
- **Cost:** Fast (~1-2 seconds for 4,200 rows)

**Phase D: `standardize_rwb_countries()`**
- **Why:** Must apply consolidation rules to all years consistently
- **Cost:** Fast (~2-3 seconds)

**Export: `data-raw/rwb_standardized.R`**
- **Why:** Must regenerate the exported `.rda` file
- **Cost:** Trivial (~<1 second)

### ✅ **Can Skip (Conditional)**

**Phase A: Download**
- ✅ Skip if using `get_years_to_download()` — only download missing years
- ✅ Typical savings: ~90% of download time in annual updates

**Phase B: Clean individual years**
- ✅ Skip historical years — only clean newly downloaded years
- ⚠️ Exception: If RSF changes column naming (rare), all years need re-cleaning
- ✅ Typical savings: ~80% of cleaning time

**Phase D: Standardize**
- ⚠️ Must apply consolidation rules to all years for consistency
- ✅ Partial optimization: Can cache combined RDS if only cleaning code changed (not country consolidations)

---

## 4. PROPOSED SOLUTION: SPECIALIZED UPDATE FUNCTION

### Concept: `update_rwb_data()`

A single high-level orchestrator function that:
1. **Detects missing years** (Phase A pre-check)
2. **Downloads only new years** (Phase A - conditional)
3. **Cleans only new years** (Phase B - conditional)
4. **Recombines all periods** (Phase C - required)
5. **Re-standardizes all data** (Phase D - required)
6. **Exports to package format** (required)
7. **Validates output** (added safety check)
8. **Reports what was updated** (user feedback)

### Function Signature
```r
update_rwb_data(
  years = NULL,           # Default: auto-detect missing years
  download = TRUE,        # Skip download if FALSE (for testing)
  clean = TRUE,          # Skip cleaning if FALSE
  combine = TRUE,        # Never skip (always TRUE)
  standardize = TRUE,    # Never skip (always TRUE)
  verbose = TRUE,        # Print progress messages
  validate = TRUE        # Run validation checks
)
```

### Implementation Strategy

**Option A: Robust Implementation**
- Single exported function in `R/update.R`
- Calls existing phases transparently
- Handles errors gracefully with rollback
- Returns detailed status dataframe
- Suitable for production workflows

**Option B: Lightweight Implementation**
- Minimal orchestrator wrapper
- Just sequences existing functions
- Suitable for scripts/automation
- Less error handling

### Return Value
```r
list(
  status = "success" | "partial" | "failed",
  years_downloaded = c(2027),
  years_cleaned = c(2027),
  rows_before = 4200,
  rows_after = 4208,
  consolidations_applied = 14,
  validation_passed = TRUE,
  messages = c("Downloaded: 2027", "Cleaned: 2027", ...)
)
```

---

## 5. DOES {TARGETS} BECOME UNNECESSARY?

### Before (Without Specialized Function)
- Users must manually call 5 functions in correct sequence
- Manual tracking of which phases need to run
- Easy to forget steps
- Good use case for {targets} to enforce DAG

### After (With Specialized Function)
- Single function call: `update_rwb_data()`
- Orchestration logic is explicit in the R function
- Simple linear workflow (not branching)
- No DAG complexity
- ❌ **{targets} becomes less necessary**

### Why {targets} No Longer Makes Sense

1. **No branches or parallelization**
   - Phase C MUST recalculate evolution columns (can't parallelize)
   - Sequential: Download → Clean → Combine → Standardize → Export
   - Too short for meaningful optimization

2. **Frequency is low**
   - Runs once per year (~30 minutes)
   - {targets} shines for iterative/frequent pipelines, not annual scripts
   - Overkill for 5-step linear sequence

3. **Orchestration is explicit**
   - Single function call does the job
   - No need for {targets}'s DAG management
   - R function is simpler than targets workflow

4. **Caching benefits are minimal**
   - Only the download step has true cache potential
   - `get_years_to_download()` already handles this intelligently
   - Re-running phases is fast enough that caching doesn't matter

5. **Consolidation mapping is dynamic**
   - If `consolidation_mapping.csv` changes, all phases must re-run anyway
   - {targets} can't know about CSV changes automatically
   - Manual triggers needed regardless

### Revised Assessment
**{targets}: ❌ Not recommended**  
**Specialized function: ✅ Highly recommended**

The `update_rwb_data()` function is a better fit because:
- Simpler to understand and use
- Explicit control over each phase
- Clear error handling without DAG abstractions
- Perfect for annual batch workflows
- No additional dependencies (already have tidyverse tools)

---

## 6. IMPLEMENTATION PLAN

### Step 1: Create `R/update.R`

New file containing:
- `update_rwb_data()` — Main orchestrator function
- `validate_update()` — Helper to validate interim results
- `report_update()` — Helper to format user-friendly output

**Dependencies:**
- Uses existing: `download.R`, `clean.R`, `combine.R`, `standardize.R`, `utils.R`
- No new external packages needed

### Step 2: Restore `dev/` Folder Structure (Optional)

Option to restore:
- `dev/update_data.R` — Example script showing `update_rwb_data()` usage
- `dev/ANNUAL_UPDATE_PROCEDURE.md` — Updated documentation

This provides:
- A ready-to-run yearly script
- Clear user guidance
- Historical context (files are in git anyway)

### Step 3: Update NAMESPACE

Add new export:
```r
export(update_rwb_data)
```

### Step 4: Update Documentation

- `R/data.R`: Add note about yearly updates
- `AGENTS.md`: Update workflow section
- `README.md` (in pressfreedom package): Mention update frequency

### Step 5: Test Update Function

Create tests in `tests/testthat/`:
- `test-update-detection.R` — Verify `get_years_to_download()` logic
- `test-update-orchestration.R` — Verify function sequencing
- Mock scenarios (new year added, consolidation changed, etc.)

---

## 7. DECISION MATRIX

| Aspect | Current State | With Specialized Function | With {targets} |
|--------|---------------|--------------------------|----------------|
| **Ease of use** | ❌ Manual 5-step process | ✅ Single function call | ⚠️ Complex DAG |
| **Annual update time** | ⏱️ ~30 minutes (manual) | ⏱️ ~30 minutes (automated) | ⏱️ ~30 minutes (same) |
| **Code simplicity** | ❌ User must sequence | ✅ Straightforward R code | ❌ New framework to learn |
| **Dependencies** | ✅ None added | ✅ None added | ❌ {targets} + new syntax |
| **Caching benefit** | ⚠️ Manual via `get_years_to_download()` | ✅ Built-in via function logic | ✅ Built-in via DAG |
| **Error handling** | ❌ Manual error checking | ✅ Function handles errors | ⚠️ targets::tar_make() abstracts errors |
| **Flexibility** | ✅ Full control | ⚠️ Less control (pre-set phases) | ⚠️ Predefined DAG |
| **Maintenance burden** | ❌ High (remember all steps) | ✅ Low (single source of truth) | ⚠️ Medium (DAG to maintain) |

---

## 8. RECOMMENDATION

### For pressfreedom.data

**✅ Create `update_rwb_data()` function**

**Reasoning:**
- Restores original design philosophy (automated yearly updates)
- Simple, explicit, maintainable
- No new dependencies
- {targets} adds complexity without proportional benefit for a 5-step annual pipeline
- `consolidation_mapping.csv` already handles the "what if there's a new country consolidation?" case

### For pressfreedom (Shiny app)

**⚠️ No change needed**
- App is interactive, not pipeline-based
- Already integrates with pressfreedom.data cleanly
- No caching or orchestration issues

---

## 9. OPEN QUESTIONS FOR PETER

1. **Scope of `update_rwb_data()`:**
   - Should it validate downloaded CSVs before cleaning?
   - Should it create backup of previous standardized RDS?
   - Should it auto-commit to git or just report what changed?

2. **Consolidation handling:**
   - If `consolidation_mapping.csv` changes, should it auto-run Phase D?
   - Should it check git diff to detect mapping changes?
   - Or always run Phase D (fast operation anyway)?

3. **Error recovery:**
   - If download fails, should it resume from the last missing year or abort?
   - If cleaning fails for a specific year, should it skip that year or fail entire update?

4. **Restore dev/ folder:**
   - Restore `dev/update_data.R` and documentation?
   - Or just embed the example in function documentation?

---

## 10. NEXT STEPS (Upon Approval)

1. ✅ Create `R/update.R` with `update_rwb_data()`
2. ✅ Add comprehensive roxygen documentation
3. ✅ Create unit tests
4. ✅ Optionally restore `dev/` folder with example script
5. ✅ Update AGENTS.md memory file
6. ✅ Commit to git: "Add specialized yearly update function"
7. ✅ Test end-to-end workflow

---

## Conclusion

**Peter's original insight was correct:** A specialized yearly update function makes much more sense than {targets} for this workflow. The infrastructure was already well-designed via `get_years_to_download()` and the four-phase functions. The missing piece is a high-level orchestrator that brings them together with intelligent defaults.

With `update_rwb_data()`, the annual update becomes a one-liner:
```r
update_rwb_data()  # Downloads missing year(s), cleans, combines, standardizes, exports
```

No {targets} needed. No complexity. Just a well-designed R function that embodies the original design philosophy.

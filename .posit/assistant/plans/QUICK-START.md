# Quick Start: pressfreedom.data Documentation

## Start Here

**New to the project?** Read in this order:

1. `2026-07-28-workflow.md` — High-level overview of all four phases
2. Specific phase document (see below)
3. Code files in `R/` for implementation details

---

## Phase Reference

### Phase A: Download
- **Status:** ✅ Complete
- **Function:** `download_rwb_data()` in `R/download.R`
- **Output:** `data/raw/rwb*.csv` (24 files)
- **Doc:** See "Phase A" in `2026-07-28-workflow.md`

### Phase B: Normalize Columns
- **Status:** ✅ Complete (code enhanced)
- **Functions:** `clean_period_1/2/3()`, `clean_rwb_single()`, `clean_all_rwb_years()` in `R/clean.R`
- **Output:** `data/cleaned/period_X/rwb*_cleaned.rds` (25 files)
- **Doc:** `2026-07-28-phase-b-normalization.md`
- **What's New:** Direct handling of 2012 year_n and score_evolution decimals in code

### Phase C: Combine Periods
- **Status:** ✅ Complete
- **Function:** `combine_cleaned_periods()` in `R/combine.R`
- **Output:** `data/processed/rwb_combined.rds` (1 file, 4,200 rows)
- **Doc:** `2026-07-28-phase-c-combination.md`

### Phase D: Standardize Countries
- **Status:** 🔄 Ready to start
- **Function:** `standardize_rwb_countries()` (to create in `R/standardize.R`)
- **Input:** `data/processed/rwb_combined.rds`
- **Output:** `data/processed/rwb_standardized.rds`
- **Doc:** `2026-07-28-phase-d-standardization.md`
- **Next Steps:** Create function, run tests, validate output

---

## Documentation Files

### For Users
- `2026-07-28-workflow.md` — Complete workflow overview
- `README.md` — Which files to use and why

### For Developers
- `2026-07-28-phase-b-normalization.md` — Phase B implementation
- `2026-07-28-phase-c-combination.md` — Phase C specifications
- `2026-07-28-phase-d-standardization.md` — Phase D plan
- `2026-07-28-UPDATES.md` — What changed and why

### Project Memory
- `AGENTS.md` — Project overview, coding preferences, key decisions

---

## Key Points

### Unified 20-Column Structure (Output of Phase B)
```
year_n, iso, country_en, score, rank,
political_context, rank_pol, economic_context, rank_eco,
legal_context, rank_leg, social_context, rank_soc,
safety, rank_saf, zone, rank_n_1, rank_evolution,
score_n_1, score_evolution
```

### Data Coverage
- **Years:** 2002–2026 (24 years; 2011 missing)
- **Countries:** 207 unique entries
- **Total Rows (Phase C):** 4,200
- **File Size (Phase C):** ~74 KB

### Data Availability by Period
| Period | Years | Dimensions | score_evolution |
|--------|-------|-----------|---|
| **1** | 2002–2012 | All NA | All NA |
| **2** | 2013–2021 | All NA | All NA |
| **3** | 2022–2026 | ✅ Populated | NA for 2022; ✅ 2023+ |

---

## Recent Changes

**July 28, 2026 Update:**
- Phase B1 renamed to Phase B
- Phase B2 renamed to Phase D
- Code enhanced: 2012 year_n handling, score_evolution decimal conversion
- Documentation streamlined: removed historical observations
- AGENTS.md updated with project overview

See `2026-07-28-UPDATES.md` for detailed change log.

---

## Next Steps

**To proceed with Phase D:**

1. Review `2026-07-28-phase-d-standardization.md`
2. Create `R/standardize.R` with `standardize_rwb_countries()` function
3. Implement country name normalization and ISO code assignment
4. Test against `data/processed/rwb_combined.rds`
5. Create `data/processed/rwb_standardized.rds`

---

## File Locations

| What | Where |
|------|-------|
| Documentation | `.posit/assistant/plans/` |
| R Functions | `R/` |
| Raw Data | `data/raw/` |
| Phase B Output | `data/cleaned/period_X/` |
| Phase C Output | `data/processed/` |
| Phase D Output | `data/processed/` |
| Project Config | `AGENTS.md` |

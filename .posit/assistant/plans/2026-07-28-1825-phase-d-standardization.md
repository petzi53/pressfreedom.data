# Phase D Standardization Plan: App-Compatible Country Name Consolidation

**Date:** July 28, 2026  
**Project:** pressfreedom.data R Package  
**Objective:** Standardize country names and ISO codes with **zero breaking changes to the existing Shiny app**

---

## EXECUTIVE SUMMARY (TL;DR)

### The Key Discovery
Your Shiny app's `rank_tier()` function **already handles variable country counts dynamically** via percentile calculations. This means:

1. **Your rank maps CAN span 2002–2026** without recalculation
2. **NO app code changes needed** — Phase D is purely a data pipeline task
3. **Phase D's job:** Consolidate 13 country name pairs + add ISO codes + preserve original ranks

### Phase D Output (rwb_standardized.rds)
```
4,200 rows × 22 columns:
├── All 20 original columns (year_n, score, rank, ...) [UNCHANGED]
├── country_en [CONSOLIDATION: 207 entries → ~190 entries]
├── country_name_original [NEW: tracks what names were changed]
└── consolidation_flag [NEW: TRUE if country_en was altered]
```

### App Integration
```
rwb_standardized.rds (pressfreedom.data)
    ↓ [update data-raw/rwb.R]
pressfreedom::rwb dataset
    ↓ [no code changes to modules]
App loads as usual → Maps/Trends/Country views work perfectly
```

### Timeline
- **Phase D implementation:** ~2-3 hours (create `R/standardize.R` with helpers, run pipeline)
- **App integration:** ~30 minutes (update data source, rebuild, test)
- **Total:** 3-4 hours to full deployment with zero app code changes

---

## Full Executive Summary

The combined dataset (`rwb_combined.rds`) contains **207 unique country entries** spanning 2002–2026 (excluding 2011). Analysis reveals:

- **68 countries** start after 2002 (mostly 2003 onwards)
- **27 countries** do not reach 2026 (ending 2002–2025)
- **47 countries** have name variations (old vs. new names) due to:
  - Political changes (Serbia-Montenegro → Serbia/Montenegro)
  - Official name changes (Turkey → Türkiye, Czech Republic → Czechia)
  - Accent/encoding variations (Côte d'Ivoire, Türkiye)
  - Territorial classification changes (Israel, US territories, Cyprus)

---

## Phase D Implementation: Three Components

### **Component 1: Discontinuity Analysis (NEW)**

**Objective:** Identify and document countries with incomplete temporal coverage.

#### 1.1 Early Starters (Start > 2002)

**Count:** 68 countries  
**Categories:**

| Category | Examples | Count | Likely Cause |
|----------|----------|-------|--------------|
| **Normal entry (2003+)** | Albania, Armenia, Estonia, Jamaica | 37 | Added to RSF index after 2002 |
| **Recent entrants (2008+)** | Luxembourg, Malta, Malta | 6 | Gradual expansion of RSF coverage |
| **Very recent (2013+)** | Andorra, Liechtenstein, Belize | 3 | Continued expansion phase |
| **Late additions (2023+)** | Bosnia-Herzegovina, Brunei, Czechia, Iran, Laos, Russia, Syria | 7 | Major 2023 methodology change |
| **Special/Fragmented** | Kosovo (2005), South Sudan (2012), OECS (2010) | 3 | New countries or regional codes |

**Action:** Accept as-is. These represent RSF's actual coverage expansion—not data errors. Document in metadata but include all records.

#### 1.2 Early Enders (End < 2026)

**Count:** 27 countries  
**Categories:**

| Category | Examples | Count | Likely Cause |
|----------|----------|-------|--------------|
| **Single-year entries** | Federal Republic of Yugoslavia (2002), Grenada (2004) | 2 | Data entry anomalies or one-time entries |
| **Territorial variants (ended 2012)** | Israel (3 variants), US (3 variants) | 6 | RSF changed territorial reporting approach in 2012 |
| **Name change entries (ended 2022)** | Bosnia/Herzegovina, Brunei, Cape Verde, Congo, Czech Republic, Iran, Lao, Morocco, Russia, Syria, Turkey, DR Congo | 12 | Old names phased out as methodology changed in 2023 |
| **Northern Cyprus variants** | Cyprus North (2004-2022), Northern Cyprus (2023-2025), Northern Cyprus (Occupied) (2026) | 3 | Encoding/naming inconsistency during 2023 transition |
| **Côte d'Ivoire variants** | Ivory Coast (2002-2022), Côte d'Ivoire (2023-2024) | 2 | Encoding/naming change during 2023 transition |
| **Türkiye variants** | Turkey (2002-2022), Türkiye (2023-2024) | 2 | Official country name change (2022) + encoding lag |

**Action:** 
- Keep all historical entries
- **Flag for consolidation:** Group old/new names and create explicit mapping
- For true data gaps (single entries, anomalies), document and investigate

---

### **Component 2: Name Variation & Consolidation (CORE)**

**Objective:** Identify old/new name pairs and create consolidation mapping.

#### 2.1 Name Change Pairs (Country Name Changes)

| Old Name | New Name | Years Active | Status | ISO Code |
|----------|----------|--------------|--------|----------|
| Czech Republic | Czechia | 2002-2022 → 2023+ | Official name change | CZE |
| Turkey | Türkiye | 2002-2022 → 2023-2024 | Official name change (2022) | TUR |
| Cape Verde | Cabo Verde | 2002-2022 → 2023+ | Standardization variant | CPV |
| Ivory Coast | Côte d'Ivoire | 2002-2022 → 2023+ | Official French name preference | CIV |
| Lao People's Democratic Republic | Laos | 2002-2022 → 2023+ | Shortened form | LAO |
| Islamic Republic of Iran | Iran | 2002-2022 → 2023+ | Shortened form | IRN |
| Russian Federation | Russia | 2002-2022 → 2023+ | Shortened form | RUS |
| Syrian Arab Republic | Syria | 2002-2022 → 2023+ | Shortened form | SYR |
| The Democratic Republic of the Congo | DR Congo | 2002-2022 → 2023+ | Shortened form | COD |
| Congo | Congo-Brazzaville | 2002-2022 → 2023+ | Disambiguation | COG |
| Brunei Darussalam | Brunei | 2002-2022 → 2023+ | Shortened form | BRN |
| Bosnia and Herzegovina | Bosnia-Herzegovina | Various | Punctuation variant | BIH |
| Democratic People's Republic of Korea | North Korea | 2002-2022 → 2023+ | Shortened form | PRK |

#### 2.2 Territorial/Status Variants (Not to consolidate—document separately)

| Name | Years | Note | Action |
|------|-------|------|--------|
| Israel (Israeli territory) | 2003-2012 | Territorial reporting variant | Keep; document methodology change |
| Israel (occupied territories) | 2003-2004 | Territorial reporting variant | Keep; document methodology change |
| Israel (outside Israeli territory) | 2006-2012 | Territorial reporting variant | Keep; document methodology change |
| US (US territory) | 2003-2012 | Territorial reporting variant | Keep; document methodology change |
| US (in Iraq) | 2003-2005 | Reporting variant | Keep; document methodology change |
| US (outside US territory) | 2006-2012 | Reporting variant | Keep; document methodology change |
| Cyprus North | 2004-2022 | Regional variant | Keep; separate from "Northern Cyprus" |
| Northern Cyprus | 2023-2025 | Renamed variant | Consolidate: same as Cyprus North? |
| Northern Cyprus (Occupied) | 2026 | Updated variant | Consolidate: same as Cyprus North? |

**Action:** Keep all variants but add metadata column flagging original vs. consolidated name.

---

### **Component 3: Standardization Implementation (EXISTING PLAN + ENHANCEMENTS)**

#### 3.1 Main Function: `standardize_rwb_countries()`

**Input:** `data/processed/rwb_combined.rds`  
**Output:** `data/processed/rwb_standardized.rds`

**Processing steps:**

1. **Load combined data**
   - 4,200 rows, 207 unique countries, 20 columns
   - Original structure: year_n, iso, country_en, score, rank, ... (18 more columns)

2. **Store original country names**
   - Create `country_name_original` column (copy of `country_en` before any changes)
   - Enables full auditability of consolidation changes

3. **Create consolidation mapping**
   - Data frame with old/new name pairs (13 pairs from Component 2.1)
   - Includes encoding fixes (Côte d'Ivoire, Türkiye)

4. **Apply name normalization**
   - Handle encoding issues (Ã©, Ã¼, etc.)
   - Decide on accent preservation: 
     - **Option A:** Keep accents (Côte d'Ivoire, Türkiye) — more authentic
     - **Option B:** Normalize to ASCII (Cote d'Ivoire, Turkiye) — easier data entry
   - Standardize whitespace and punctuation

5. **Consolidate old/new names**
   - Apply 13 name consolidation pairs to `country_en` column
   - Create `consolidation_flag` column (TRUE if this row's country name was changed)
   - **Important:** Do NOT recalculate ranks (keep original `rank` column unchanged)

6. **Assign ISO codes**
   - Use `countrycode::countrycode()` package for mapping
   - Map standardized `country_en` to ISO 3-letter codes
   - Handle special cases (Taiwan, Kosovo, Palestine, Hong Kong)
   - Log any unmappable countries for review

7. **Validate output**
   - All 4,200 rows preserved
   - 22 columns (20 original + country_name_original + consolidation_flag)
   - No missing critical values (year_n, iso, country_en, score, rank)
   - No duplicate (year_n, country_en) pairs
   - 100% ISO code coverage

---

#### 3.2 Helper Functions

**`store_original_country_names(df)`**
- Create `country_name_original` column as backup
- Enables full audit trail of consolidation changes

**`create_consolidation_mapping()`**
- Build mapping of old → new names (13 pairs from Component 2.1)
- Include encoding fixes
- Document reason for consolidation (official change, RSF shortening, etc.)

**`normalize_encoding(df)`**
- Detect and fix encoding issues (Ã©, Ã¼, etc.)
- Handle accent preservation (user decision: keep or remove)
- Standardize whitespace and punctuation

**`consolidate_names(df, mapping)`**
- Apply consolidation mapping to `country_en` column
- Add `consolidation_flag` column (TRUE if name was changed)
- Preserve all other columns (especially `rank` and `score`)

**`assign_iso_codes(df)`**
- Use `countrycode::countrycode()` for main mapping
- Create lookup table for special cases (Taiwan, Kosovo, Palestine, Hong Kong)
- Log any unmappable countries for review

**`validate_standardization(df)`**
- Row count: 4,200 (unchanged)
- Column count: 22 (20 original + country_name_original + consolidation_flag)
- No missing critical values (year_n, iso, country_en, score, rank)
- No duplicate (year_n, country_en) pairs
- ISO code coverage: 100%
- Consolidation_flag distribution (sanity check)

---

#### 3.3 Special Cases Handling

**Consolidations to perform:**

```r
# Name consolidation mapping
consolidation_map <- tribble(
  ~old_name, ~new_name, ~iso, ~reason,
  "Czech Republic", "Czechia", "CZE", "Official name change",
  "Turkey", "Türkiye", "TUR", "Official name change (2022)",
  "Cape Verde", "Cabo Verde", "CPV", "RSF standardization",
  "Ivory Coast", "Côte d'Ivoire", "CIV", "RSF standardization",
  "Lao People's Democratic Republic", "Laos", "LAO", "RSF shortening",
  "Islamic Republic of Iran", "Iran", "IRN", "RSF shortening",
  "Russian Federation", "Russia", "RUS", "RSF shortening",
  "Syrian Arab Republic", "Syria", "SYR", "RSF shortening",
  "The Democratic Republic of the Congo", "DR Congo", "COD", "RSF shortening",
  "Congo", "Congo-Brazzaville", "COG", "RSF disambiguation",
  "Brunei Darussalam", "Brunei", "BRN", "RSF shortening",
  "Democratic People's Republic of Korea", "North Korea", "PRK", "RSF shortening",
  "Bosnia and Herzegovina", "Bosnia-Herzegovina", "BIH", "Punctuation standardization"
)
```

**Territorial variants:** Document but keep separate (no consolidation). Create metadata explaining RSF methodology shifts.

**Cyprus variants:** Investigate whether Cyprus North (2004-2022) = Northern Cyprus (2023-2025) = Northern Cyprus (Occupied) (2026). If yes, consolidate; if no, keep separate with flags.

---

### **Component 4: Output & Validation**

#### 4.1 Output Dataset: `rwb_standardized.rds`

**Structure:** 4,200 rows × 22 columns

| Column | Type | Notes |
|--------|------|-------|
| year_n | numeric | 2002–2026 (no 2011) |
| iso | character | 3-letter ISO code |
| country_en | character | **Standardized country name (consolidated)** |
| country_name_original | character | **NEW: Original name before consolidation (for auditing)** |
| consolidation_flag | logical | **NEW: TRUE if country_en was changed** |
| score | numeric | Original RSF score (unchanged) |
| rank | numeric | Original RSF rank (unchanged — app handles percentiles) |
| political_context | numeric | Unchanged |
| rank_pol | numeric | Unchanged |
| [13 more context columns] | numeric | Unchanged |

**Key Design Decisions:**
- `rank` and `score` columns **unchanged** (respects RSF source data)
- `country_en` contains **consolidated names** (all 13 pairs merged)
- `country_name_original` enables **full audit trail**
- `consolidation_flag` signals which rows had name changes
- **No percentile_rank column** (app's `rank_tier()` function handles this)

#### 4.2 Validation Report

**Before standardization:**
- 4,200 rows across 24 years (2002–2026, no 2011)
- 207 unique country entries
- 13 name consolidation pairs identified
- Multiple encoding issues (Côte, Türkiye)
- 68 countries starting after 2002
- 27 countries ending before 2026

**After standardization:**
- 4,200 rows (unchanged)
- ~190 unique countries (13 consolidations applied)
- All ISO codes assigned
- Encoding standardized
- Country history preserved in `country_name_original`
- Consolidation documented in `consolidation_flag`
- Original `rank` and `score` unchanged (app compatibility)

**Quality checks:**
- ✓ 4,200 rows preserved
- ✓ No missing year_n, iso, country_en, score, rank
- ✓ No duplicate (year_n, country_en) pairs
- ✓ All rows assigned valid ISO codes
- ✓ Original `rank` values unchanged (preserved for app)
- ✓ Original `score` values unchanged (preserved for app)
- ✓ All new columns (country_name_original, consolidation_flag) populated as expected
- ✓ Ready for app: no code changes required

**Consolidation coverage:**
- 13 country name pairs consolidated
- Approximately 150–200 rows affected (rows with old country names)
- Remaining rows (consolidated countries): name unchanged, consolidation_flag = FALSE

---

### **Component 5: Documentation**

#### 5.1 Phase D Report: `2026-07-28-phase-d-standardization-report.md`

Should include:
- Overview of changes
- Consolidation mapping (table)
- Encoding fixes applied
- Territorial variant handling
- Validation summary
- Any unresolved issues or flags for user review

#### 5.2 Codebook Update

Add sections:
- `country_en`: Standardized country names post-2023
- `country_name_original`: Original name before consolidation
- `consolidation_flag`: TRUE if name was consolidated
- Notes on territorial variants and Cyprus discontinuities

---

## Implementation Sequence

1. ✅ **Analysis phase** (completed): Identify discontinuities and name variations
2. **Code development:**
   - Create `R/standardize.R` with all helper functions
   - Test each function in isolation
   - Integrate and test full pipeline
3. **Execution:**
   - Run standardization on combined data
   - Generate validation report
   - Review any unresolved cases
4. **Output:**
   - Write `rwb_standardized.rds`
   - Write documentation
   - Update AGENTS.md memory file

---

---

# UPDATED PLAN: Phase D Standardization with Shiny App Integration

**After reviewing your Shiny app architecture**, I'm revising the strategy to ensure seamless compatibility with your existing dashboard while supporting your visualization goals.

---

## Key Insight: Your App Already Uses Percentile-Based Ranking

Your map module (`mod_map.R` lines 106-126) already implements **percentile-tier classification**:

```r
rank_tier <- function(rank, max_rank) {
  p2_5  <- ceiling(max_rank * 0.025)
  p15   <- floor(max_rank * 0.15)
  p85   <- floor(max_rank * 0.85)
  p97_5 <- floor(max_rank * 0.975)
  
  dplyr::case_when(
    rank <= p2_5  ~ "Top 2.5%",
    rank <= p15   ~ "2.5%–15%",
    rank <= p85   ~ "15%–85%",
    rank <= p97_5 ~ "85%–97.5%",
    TRUE          ~ "Bottom 2.5%"
  )
}
```

This function **already handles variable country counts per year**! The percentile tiers adapt automatically:
- 2002 (139 countries): Top 2.5% = rank ≤ 4
- 2026 (180 countries): Top 2.5% = rank ≤ 5

**This means your map view can already display rank across 2002–2026 without modification.**

---

## CRITICAL ISSUE: Rank Values & Country Count Changes

**Discovery:** The original RSF rank values (1–180) are **tied to the number of countries ranked in each year**, which varies:

| Year | Countries | Max Rank | Notes |
|------|-----------|----------|-------|
| 2002 | 139 | 139 | Initial dataset |
| 2003 | 166 | 166 | +27 countries |
| 2006 | 168 | 168 | Gradual expansion |
| 2008 | 173 | 173 | Continued growth |
| 2013+ | 179–180 | 180 | Stable (Phase 2 onwards) |

**Problem:** If you consolidate country names during standardization (reducing unique entries from 207 to ~190), the original RSF ranks become **incomparable across the consolidation boundary**. For example:
- 2022: Turkey ranked 79 out of 180
- 2023: Türkiye ranked 74 out of 180 (different ranking system, different country count)

**Your mapping goal requires:**
- **Score maps:** 2013+ only (RSF changes methodology, scores become comparable)
- **Rank maps:** 2002+ ideally (but ranks need recalculation for consistency)

---

## Solution Options for Rank Recalculation

---

## REVISED: App-Compatible Strategy for Phase D

Given your app's sophisticated design, here's the **optimal approach** that minimizes app changes while solving the rank consolidation issue:

### **Solution: NO RECALCULATION NEEDED — Keep Original Ranks**

Your app already handles variable country counts gracefully through `rank_tier()`. Therefore:

1. **Keep original `rank` column unchanged** (RSF's exact values preserved)
2. **Do NOT create a percentile_rank column** (your app doesn't need it)
3. **Standardize country names** (13 name consolidations in Phase D)
4. **Trust the existing `rank_tier()` function** to classify ranks appropriately for each year

**Why this works:**

The `rank_tier()` function in your map module dynamically calculates percentile boundaries based on `max_rank` (the maximum rank in the selected year). After consolidation:
- 2002: 139 countries → max_rank = 139
- 2026: 180 countries → max_rank = 180
- The function automatically recalculates tier boundaries for each year

**This means:**
- ✅ Your map view works 2002–2026 without any app code changes
- ✅ Your trends view (bump chart) works 2002–2026 as-is (using original ranks)
- ✅ Country view stats work as-is
- ✅ All consolidation handled transparently by the data pipeline, not the app

---

### **Why NOT Option A (Recalculation)?**

Recalculating ranks would:
- ❌ Require updating `mod_map.R`'s `rank_tier()` function to handle a `percentile_rank` column instead of raw ranks
- ❌ Break the app's current `rank` column (which your Trends view bump chart depends on)
- ❌ Force updates to `mod_country.R` stat table logic
- ❌ Introduce data duplication (original + recalculated ranks)
- ❌ Make the data output less faithful to RSF's source data

---

### **Why NOT Option C (Percentile Ranks)?**

Creating a separate `percentile_rank` column would:
- ❌ Require app code changes (updating visualizations to use percentile_rank instead of rank)
- ❌ Complicate the data output (two rank columns for one concept)
- ❌ Add unnecessary transformation complexity to Phase D

---

## RECOMMENDATION: **Consolidation-Only Phase D**

The optimal strategy for your use case is the **simplest possible Phase D implementation**:

**Phase D output for app compatibility:**

1. **Standardize country names** (13 consolidation pairs)
2. **Keep original `rank` column unchanged** (no recalculation)
3. **Keep original `score` column unchanged** (no modification)
4. **Add ISO codes** via `countrycode` package
5. **Add metadata columns:**
   - `country_name_original`: Pre-consolidation name (for auditing)
   - `consolidation_flag`: TRUE if name was changed
6. **NO new rank/percentile columns needed** — your app handles this

**Why this is optimal:**

- ✅ **Minimal app changes:** Zero modifications to existing Shiny code
- ✅ **Maps work as-is:** `rank_tier()` dynamically handles variable country counts
- ✅ **Trends work as-is:** Bump chart uses original `rank` directly
- ✅ **Country stats work as-is:** All calculations use original columns
- ✅ **Full auditability:** Original data preserved, consolidations documented
- ✅ **Cleaner data output:** No duplicate rank columns
- ✅ **Respects RSF:** Original ranks untouched

**Data flow to app:**

```
rwb_standardized.rds (from Phase D)
    ↓
    20 original columns (year_n, iso, country_en, score, rank, ...)
    + 2 metadata columns (country_name_original, consolidation_flag)
    ↓
    pressfreedom::rwb (bundled in app package)
    ↓
    App loads rwb as usual, passes to three modules
    ↓
    Map module: rank_tier() uses original rank + max_rank
    Trends module: bump chart uses original rank
    Country module: stats use original rank/score
```

---

## Decisions for User Review

1. **Rank standardization approach:** 
   - **A** (Recalculate ranks)
   - **C** (Use percentile ranks) ← **Recommended**
   - **B** (Split by era)
   - **D** (Consolidate in Phase B)

2. **Consolidation pairs:** Should all 13 name pairs be consolidated, or keep some separate?

3. **Cyprus variants:** Are all three names (Cyprus North, Northern Cyprus, Northern Cyprus Occupied) the same entity?

4. **Encoding:** For names with accents (Côte d'Ivoire, Türkiye), should we preserve accents or normalize to ASCII?

5. **Territorial variants (Israel, US):** Keep as-is or investigate methodology change?

6. **Single-entry countries:** Should "Grenada (2004-only)" and "Federal Republic of Yugoslavia (2002-only)" be investigated further or accepted as-is?

---

## Files to Create/Modify

| File | Type | Purpose |
|------|------|---------|
| `R/standardize.R` | NEW | Core standardization functions |
| `data/processed/rwb_standardized.rds` | NEW OUTPUT | Final standardized dataset |
| `2026-07-28-phase-d-standardization-report.md` | NEW DOC | Detailed report of changes |
| `AGENTS.md` | UPDATE | Record Phase D completion and findings |

---

---

## Visualization Strategy (Downstream)

Once `rwb_standardized.rds` is ready, the mapping layer can use:

**Score Maps (2013–2026):**
- Uses original `score` column
- 5-bin system based on score ranges (RSF's methodology)
- Tooltip: Country, Score, Score Rank (original `rank`)

**Rank Maps (2002–2026):**
- Uses `percentile_rank` column
- 5-bin system: [0-20], [20-40], [40-60], [60-80], [80-100]
- Tooltip: Country, Percentile Rank, Original Rank (for reference)
- Consistent scale across all 24 years despite varying country counts

**Time Series Charts (2002–2026):**
- X-axis: Year
- Y-axis: Score (2013+) or Percentile Rank (2002–2026)
- Lines grouped by country
- Handles countries with partial coverage gracefully (gaps in line)

---

---

## App Integration Strategy

Once `rwb_standardized.rds` is ready, integrating with your pressfreedom app requires **zero code changes**:

**Map View (mod_map.R) — No Changes:**
- ✅ `rsf_band()` function works as-is on `score` column
- ✅ `rank_tier()` function automatically adapts to varying `max_rank` per year
- ✅ Filters (year, zone, metric) work unchanged
- ✅ Checkboxes (score bands, rank tiers) work unchanged
- **Result:** Rank maps span 2002–2026; Score maps span 2013–2026

**Trends View (mod_chart.R) — No Changes:**
- ✅ Score line chart works on original `score` column
- ✅ Rank bump chart works on original `rank` column
- ✅ Both metrics display across full 2002–2026 range
- ✅ Country filtering and hover-dimming work unchanged
- **Result:** Full temporal coverage for both metrics

**Country View (mod_country.R) — No Changes:**
- ✅ `country_block_stats()` function works on original columns
- ✅ Best/worst/median calculations unchanged
- ✅ Rank evolution calculations unchanged
- ✅ Score evolution (with 2013 artifact exclusion) unchanged
- ✅ Dimension scores (2022+) work unchanged
- **Result:** All stats and charts display correctly

**Integration workflow:**
1. Phase D produces `rwb_standardized.rds` in pressfreedom.data package
2. Update `pressfreedom::rwb` dataset (in `data-raw/rwb.R`) to load from Phase D output
3. Run `devtools::load_all()` in pressfreedom package (rebuilds bundled `rwb.rda`)
4. App automatically uses consolidated country names
5. **Zero code changes to any module**

---

---

## Annual Maintenance & Code Reusability (CRITICAL ARCHITECTURE QUESTION)

### The Question
"Every year when new data arrives, do Phase B, Phase C, and Phase D need to run again? If so, won't we need to adapt Phase B code we've already written?"

### The Answer: YES & NO (Nuanced)

#### YES: Phases B, C, D Run Annually
Every time new RSF data arrives:
1. **Phase B (Clean):** New CSV file → cleaned RDS (same functions, new input file)
2. **Phase C (Combine):** All cleaned RDS → combined dataset (same function, expands existing)
3. **Phase D (Standardize):** Combined → standardized dataset (same function, expands existing)

#### NO: Phase B Code Does NOT Need Adaptation
The existing Phase B functions (`clean_period_1()`, `clean_period_2()`, `clean_period_3()`) are **already generic**:
- They accept `filepath` and `year` as parameters
- They auto-detect period from year value
- They handle encoding, decimal separators, column mappings automatically
- They work for any year within their period range (e.g., `clean_period_3()` works for 2022, 2023, 2024, 2025, 2026)

**Example: Adding 2027 data**
```r
# Phase B: Just call the existing function with new file
clean_rwb_single(
  filepath = "data/raw/rwb2027.csv",
  year = 2027,
  output_dir = "data/cleaned"
)

# Phase C: Just re-run combine (it finds ALL RDS files automatically)
combine_cleaned_periods(
  input_dir = "data/cleaned",
  output_file = "data/processed/rwb_combined.rds"
)

# Phase D: Just re-run standardize (it processes combined data)
standardize_rwb_countries(
  input_file = "data/processed/rwb_combined.rds",
  output_file = "data/processed/rwb_standardized.rds"
)
```

#### The Real Question: Does Phase D Need Code Adaptation?

**Short answer:** Generally NO, but maybe.

**Detailed answer depends on how RSF changes methodology:**

| Scenario | Phase D Code Needs Change? | Example |
|----------|---------------------------|---------|
| **New year, same countries** | NO | 2027 adds 1 new country → consolidation map stays the same |
| **New year, new country names** | YES | If RSF renames "Australia" to something else in 2027 |
| **New year, new dimensional data** | NO | If 2027 adds new columns (Political, Economic, etc.) like 2022+ did → handled by Phase B, not Phase D |
| **New country consolidation needed** | YES | If in 2027 RSF combines two countries that were separate before |

**Realistic expectation:** Phase D consolidation mapping needs updates ~every 2-3 years when RSF makes official methodology changes.

---

### Optimal Architectural Pattern for Maintenance

**Structure Phase D as TWO INDEPENDENT LAYERS:**

1. **Layer 1: Generic Consolidation Engine** (reusable every year)
   - Generic function: `consolidate_and_standardize_countries()`
   - Input: consolidated data + mapping table
   - Output: standardized data with ISO codes
   - **NEVER changes** — pure data transformation logic

2. **Layer 2: Consolidation Mapping Data** (updated as needed)
   - Data frame: consolidation pairs (old name → new name)
   - Stored in: `data-raw/consolidation_mapping.csv` or similar
   - **CHANGES ONLY WHEN RSF methodology changes** (rare)
   - Easy to update without touching code

**Implementation approach:**

```r
# R/standardize.R (Generic, reusable annually)
standardize_rwb_countries <- function(
  input_file,
  output_file,
  mapping_file = here::here("data-raw", "consolidation_mapping.csv")
) {
  combined <- readRDS(input_file)
  mapping <- readr::read_csv(mapping_file)
  
  # Apply consolidation logic (never changes)
  standardized <- consolidate_and_standardize_countries(combined, mapping)
  
  saveRDS(standardized, output_file)
}

# data-raw/consolidation_mapping.csv (Updated as needed, not code)
# old_name,new_name,iso_code,reason
# Czech Republic,Czechia,CZE,Official name change
# Turkey,Turkiye,TUR,Official name change
# ... etc
```

**Benefits:**
- ✅ Phase B, C, D code runs unchanged every year
- ✅ Consolidation logic never changes (reusable)
- ✅ Only data file (`consolidation_mapping.csv`) changes when RSF updates names
- ✅ Non-technical users can update mappings without coding knowledge
- ✅ Changes tracked in version control (CSV diffs are human-readable)

---

### Annual Update Workflow (Simplified)

**Each year when new RSF data arrives:**

```
1. Download new 2027 RSF CSV → data/raw/rwb2027.csv
2. Run: clean_rwb_single("data/raw/rwb2027.csv", 2027, "data/cleaned")
3. Run: combine_cleaned_periods()  # Combines all RDS, including new 2027 file
4. Check output: Are there new country names or consolidations needed?
5. If NO changes: Run standardize_rwb_countries()  # Same mapping applies
6. If YES changes: 
   a. Update data-raw/consolidation_mapping.csv with new pairs
   b. Run standardize_rwb_countries()  # Uses updated mapping
7. Update pressfreedom::rwb with standardized data
8. Test app: Map, Trends, Country views
```

---

### DECISION REQUIRED: How to Store Consolidation Mapping?

**Option A: CSV file in data-raw/** (RECOMMENDED)
- ✅ Human-readable, easy to edit
- ✅ Version control friendly (diffs show what changed)
- ✅ Non-technical users can update
- ✅ Can be reviewed before running standardization

**Option B: Hard-coded in R function**
- ❌ Requires code edit to change consolidations
- ❌ Harder to track changes (git diffs less clear)
- ❌ Requires R knowledge to update

**Option C: Database or YAML**
- ✅ Structured but more complex
- ❌ Overkill for this use case

**Recommendation:** Use **Option A (CSV in data-raw/)** because:
- Aligns with existing pressfreedom.data structure
- Keeps data separate from logic
- Easy annual maintenance

---



### Phase D Implementation (pressfreedom.data)
1. Create `data-raw/consolidation_mapping.csv` with 13 consolidation pairs + Cyprus variant mapping
2. Create `R/standardize.R` with two functions:
   - `consolidate_and_standardize_countries()` — generic consolidation engine (reusable annually)
   - `standardize_rwb_countries()` — wrapper that loads mapping CSV and calls engine
3. Test consolidation logic on sample data
4. Run full standardization pipeline
5. Validate output (row count, ranges, ISO codes)
6. Document findings and methodology
7. Export `rwb_standardized.rds`

### App Integration (pressfreedom)
7. Update `data-raw/rwb.R` to load from `rwb_standardized.rds`
8. Rebuild bundled `rwb.rda` dataset
9. Test app: Verify all three views display correctly
10. Update AGENTS.md in pressfreedom (document data pipeline change)

### Documentation
11. Write Phase D completion report
12. Update AGENTS.md in pressfreedom.data with Phase D results and annual maintenance workflow
13. Document consolidation pairs and any unresolved cases
14. Create reference guide: "Annual Data Update Workflow" (for next year's process)

---

## Annual Maintenance Workflow (Reference for Future Years)

This workflow will be documented in AGENTS.md and a separate "ANNUAL_UPDATE.md" guide.

### When New RSF Data Arrives (e.g., 2027)

**Step 1: Download & Prepare** (~5 min)
```r
# Download 2027 CSV from RSF website
# Place in data/raw/rwb2027.csv
```

**Step 2: Run Phase B (Clean)** (~2 min)
```r
library(pressfreedom.data)

clean_rwb_single(
  filepath = here::here("data/raw/rwb2027.csv"),
  year = 2027,
  output_dir = here::here("data/cleaned")
)
```

**Step 3: Run Phase C (Combine)** (~1 min)
```r
combine_cleaned_periods(
  input_dir = here::here("data/cleaned"),
  output_file = here::here("data/processed/rwb_combined.rds")
)
```

**Step 4: Check for New Consolidations** (~10 min)
```r
# Load combined data and inspect new/changed country names
combined <- readRDS(here::here("data/processed/rwb_combined.rds"))
new_countries <- combined |>
  dplyr::filter(year_n == 2027) |>
  dplyr::distinct(country_en) |>
  dplyr::arrange(country_en)
print(new_countries)

# Compare with 2026 to identify new names or consolidations needed
old_countries <- combined |>
  dplyr::filter(year_n == 2026) |>
  dplyr::distinct(country_en) |>
  dplyr::arrange(country_en)
```

**Step 5: Update Consolidation Mapping (if needed)** (~5-10 min)
```r
# If new consolidations needed:
# 1. Edit data-raw/consolidation_mapping.csv
# 2. Add new rows for any country name changes or consolidations
# 3. Save CSV
# 4. Commit to git with message: "Update consolidation mapping for 2027"
```

**Step 6: Run Phase D (Standardize)** (~2 min)
```r
standardize_rwb_countries(
  input_file = here::here("data/processed/rwb_combined.rds"),
  output_file = here::here("data/processed/rwb_standardized.rds")
)
```

**Step 7: Validate Output** (~5 min)
```r
# Check structure and completeness
standardized <- readRDS(here::here("data/processed/rwb_standardized.rds"))
print(paste("Total rows:", nrow(standardized)))
print(paste("Unique countries:", n_distinct(standardized$country_en)))
print(paste("Years covered:", min(standardized$year_n), "–", max(standardized$year_n)))

# Check consolidation flag
print(standardized |>
  dplyr::filter(year_n == 2027) |>
  dplyr::summarise(
    n_rows = n(),
    n_consolidated = sum(consolidation_flag == TRUE, na.rm = TRUE),
    .by = consolidation_flag
  ))
```

**Step 8: Update pressfreedom App** (~3 min)
```r
# In pressfreedom package, update data-raw/rwb.R to load new standardized data:
# rwb <- readRDS(
#   fs::path_package(
#     "pressfreedom.data",
#     "data",
#     "processed",
#     "rwb_standardized.rds"
#   )
# )

# Rebuild bundled dataset
devtools::load_all("~/path/to/pressfreedom")
usethis::use_data(rwb, overwrite = TRUE)
```

**Step 9: Test App** (~10 min)
```r
# Launch Shiny app and verify:
# - Map view loads with 2027 data
# - Rank tiers calculate correctly for 2027
# - Trends view shows 2027 in bump chart
# - Country view includes 2027 in stats
```

**Step 10: Commit & Deploy** (~5 min)
```bash
# In pressfreedom.data repo
git add data/raw/rwb2027.csv data/processed/rwb_standardized.rds data-raw/consolidation_mapping.csv
git commit -m "Add 2027 RSF data (Phase A-D complete)"
git push

# In pressfreedom repo  
git add data/rwb.rda
git commit -m "Update bundled rwb dataset with 2027 data"
git push
```

**Total time: ~45 minutes** (mostly waiting for functions to run)

---

## Files Affected by Annual Updates

### Phase B-D Code (NO CHANGES NEEDED)
- ✅ `R/clean.R` — Generic functions, work for any year
- ✅ `R/combine.R` — Generic function, automatically finds all RDS files
- ✅ `R/standardize.R` — Generic function, reusable with mapping file

### Data Files (UPDATED ANNUALLY)
- 📦 `data/raw/rwb[YEAR].csv` — NEW file added each year
- 📦 `data/processed/rwb_combined.rds` — UPDATED (re-run Phase C)
- 📦 `data/processed/rwb_standardized.rds` — UPDATED (re-run Phase D)
- 📋 `data-raw/consolidation_mapping.csv` — UPDATED if RSF changes names (rare)

### Downstream App Code (NO CHANGES NEEDED)
- ✅ `pressfreedom::rwb` — Updated dataset, code unchanged
- ✅ All Shiny modules — Work with any year range automatically

---

## RECOMMENDATION: Two-Function Design for Phase D

To ensure sustainable, maintainable annual updates, Phase D should be structured with **clear separation of logic and data**:

### Function 1: Generic Consolidation Engine (NEVER CHANGES)
```r
# R/standardize.R
consolidate_and_standardize_countries <- function(
  combined_df,
  consolidation_mapping
) {
  # This function encodes the consolidation LOGIC
  # Input: data + mapping table
  # Processing: 
  #   1. Remove territorial variants
  #   2. Apply consolidations from mapping
  #   3. Normalize encoding (ASCII)
  #   4. Assign ISO codes
  # Output: standardized data with metadata
  # 
  # This function NEVER changes year-to-year
  # It's tested once, then reused annually
}
```

**Why:** Generic logic is stable, testable, and reusable.

### Function 2: Annual Wrapper (REFERENCES EXTERNAL MAPPING FILE)
```r
# R/standardize.R
standardize_rwb_countries <- function(
  input_file = here::here("data/processed", "rwb_combined.rds"),
  output_file = here::here("data/processed", "rwb_standardized.rds"),
  mapping_file = here::here("data-raw", "consolidation_mapping.csv")
) {
  # Load data
  combined <- readRDS(input_file)
  
  # Load mapping (external file, updated as needed)
  mapping <- readr::read_csv(mapping_file, show_col_types = FALSE)
  
  # Call generic engine
  standardized <- consolidate_and_standardize_countries(combined, mapping)
  
  # Save
  saveRDS(standardized, output_file)
  
  invisible(output_file)
}
```

**Why:** Wrapper is lightweight, loads mapping from CSV (data, not code), makes annual updates trivial.

### Data File: Consolidation Mapping (UPDATED AS NEEDED)
```csv
# data-raw/consolidation_mapping.csv
old_name,new_name,iso_code,reason
Czech Republic,Czechia,CZE,Official name change
Turkey,Turkiye,TUR,Official name change
...
Cyprus North,Cyprus,CYP,Cyprus variant consolidation
Northern Cyprus,Cyprus,CYP,Cyprus variant consolidation
Northern Cyprus (Occupied),Cyprus,CYP,Cyprus variant consolidation
```

**Why:** Data is separate from logic. CSV is human-readable, git-trackable, and non-technical users can update it.

### Special Cases Mapping (ADDITIONAL DATA FILE)
```csv
# data-raw/special_cases_mapping.csv
# For territorial variants and other special consolidations
name,action,consolidate_to,reason
Israel (occupied territories),delete,NA,RSF discontinued 2004
Israel (Israeli territory),consolidate,Israel,Territorial variant 2003-2012
Israel (outside Israeli territory),consolidate,Israel,Territorial variant 2006-2012
US (in Iraq),delete,NA,RSF discontinued 2005
US (US territory),consolidate,United States,Territorial variant 2003-2012
US (outside US territory),delete,NA,RSF discontinued 2012
```

**Why:** Explicit handling of deletions and consolidations, easy to audit and modify.

---

## Summary: Annual Maintenance is Simple

**Your question:** "Don't we have to adapt Phase B code each year?"

**Answer:** **NO** — Thanks to good design:

1. **Phase B code (clean)** — Fully generic, works for any year
2. **Phase C code (combine)** — Fully generic, auto-discovers all files
3. **Phase D code (standardize)** — Separates logic from mapping data
   - Logic never changes (tested once)
   - Mapping CSV updated only when RSF changes names (rare)
   - Annual runs are purely data transformations

**Annual update effort:**
- Run three functions in sequence (5 minutes)
- Update mapping CSV if needed (5-10 minutes, happens every 2-3 years)
- Test app (10 minutes)
- Total: ~45 minutes

**Code changes needed:** Zero (unless RSF adds new columns → handled by Phase B)

---

## Decisions for User Review (PRIORITIZED)

### 1. **Accent Handling** (HIGH PRIORITY — affects data output)
   - ✅ **DECIDED:** Normalize to ASCII (Cote d'Ivoire, Turkiye)
   - Implementation: Remove diacritics from all country names during standardization

### 2. **Consolidation Pairs** (HIGH PRIORITY — affects final dataset)
   - ✅ **DECIDED:** Apply all 13 consolidation pairs
   - Czech Republic → Czechia ✓
   - Turkey → Turkiye ✓
   - Cape Verde → Cabo Verde ✓
   - Ivory Coast → Cote d'Ivoire ✓
   - Lao People's Democratic Republic → Laos ✓
   - Islamic Republic of Iran → Iran ✓
   - Russian Federation → Russia ✓
   - Syrian Arab Republic → Syria ✓
   - The Democratic Republic of the Congo → DR Congo ✓
   - Congo → Congo-Brazzaville ✓
   - Brunei Darussalam → Brunei ✓
   - Bosnia and Herzegovina → Bosnia-Herzegovina ✓
   - Democratic People's Republic of Korea → North Korea ✓

### 3. **Cyprus Variants** (MEDIUM PRIORITY — affects ~3% of data)
   - ✅ **DECIDED:** Cyprus North (2004-2022), Northern Cyprus (2023-2025), Northern Cyprus (Occupied) (2026) are the same entity
   - Implementation: Consolidate to single standardized name "Cyprus"

### 4. **Territorial Variants** (LOW PRIORITY — affects <1% of data)
   - ✅ **DECIDED:** 
     - **Israel:** Delete occupied territory variant; consolidate "Israel (Israeli territory)" and "Israel (outside Israeli territory)" to "Israel"
     - **United States:** Consolidate "US (US territory)" with "United States"; delete "US (in Iraq)" and "US (outside US territory)"
   - Implementation: Apply before name standardization

### 5. **Single-Entry Anomalies** (LOW PRIORITY — affects <0.1% of data)
   - ✅ **DECIDED:** Accept as-is
   - Grenada (2004-only) and Federal Republic of Yugoslavia (2002-only) are valid RSF coverage decisions; include without investigation

---

## Updated Consolidation Strategy (Post-Decisions)

### Pre-Processing: Territorial Variants Removal

**Before applying name consolidations, remove problematic territorial variants:**

1. **Israel variants (2003-2012):**
   - **DELETE:** "Israel (occupied territories)" [2003-2004 only]
   - **CONSOLIDATE TO "Israel":** 
     - "Israel (Israeli territory)" [2003-2012]
     - "Israel (outside Israeli territory)" [2006-2012]
   - Result: Single "Israel" entry for years with multiple variants

2. **United States variants (2003-2012):**
   - **DELETE:** "US (in Iraq)" [2003-2005]
   - **DELETE:** "US (outside US territory)" [2006-2012]
   - **CONSOLIDATE TO "United States":** 
     - "US (US territory)" [2003-2012]
   - Result: Single "United States" entry for years with variants

### Name Consolidation: 13 Pairs + Cyprus

**Apply to all remaining country_en values:**

| Old Name (Pre-2023) | New Name (2023+) | ASCII Normalized | ISO | Action |
|-------------------|------------------|------------------|-----|--------|
| Czech Republic | Czechia | Czechia | CZE | Consolidate |
| Turkey | Türkiye | Turkiye | TUR | Consolidate |
| Cape Verde | Cabo Verde | Cabo Verde | CPV | Consolidate |
| Ivory Coast | Côte d'Ivoire | Cote d'Ivoire | CIV | Consolidate |
| Lao People's Democratic Republic | Laos | Laos | LAO | Consolidate |
| Islamic Republic of Iran | Iran | Iran | IRN | Consolidate |
| Russian Federation | Russia | Russia | RUS | Consolidate |
| Syrian Arab Republic | Syria | Syria | SYR | Consolidate |
| The Democratic Republic of the Congo | DR Congo | DR Congo | COD | Consolidate |
| Congo | Congo-Brazzaville | Congo-Brazzaville | COG | Consolidate |
| Brunei Darussalam | Brunei | Brunei | BRN | Consolidate |
| Bosnia and Herzegovina | Bosnia-Herzegovina | Bosnia-Herzegovina | BIH | Consolidate |
| Democratic People's Republic of Korea | North Korea | North Korea | PRK | Consolidate |
| Cyprus North / Northern Cyprus / Northern Cyprus (Occupied) | Cyprus | Cyprus | CYP | Consolidate |

### Encoding Normalization

**After consolidation, apply ASCII normalization to all country names:**
- Remove all diacritics (accents, tildes, umlauts)
- Examples:
  - "Côte d'Ivoire" → "Cote d'Ivoire"
  - "Türkiye" → "Turkiye"
  - "São Tomé and Príncipe" → "Sao Tome and Principe"

### Validation Logic

**For each consolidation:**
1. Identify all rows with old country name
2. Update country_en to new name
3. Set consolidation_flag = TRUE for affected rows
4. Preserve all other columns (especially rank, score, year_n)
5. Apply ASCII normalization to final country_en value

**Example transformations:**
- Row: (year=2022, country_en="Turkey", rank=79) → (year=2022, country_en="Turkiye", rank=79, consolidation_flag=TRUE)
- Row: (year=2023, country_en="Türkiye", rank=74) → (year=2023, country_en="Turkiye", rank=74, consolidation_flag=FALSE) [already new name]
- Row: (year=2010, country_en="Cyprus North", rank=45) → (year=2010, country_en="Cyprus", rank=45, consolidation_flag=TRUE)

---

## Updated Implementation Sequence

1. **Load combined data** (`data/processed/rwb_combined.rds`)
2. **Store original names** → create `country_name_original` column
3. **Remove territorial variants** (Israel occupied, US in Iraq, US outside territory)
4. **Apply name consolidations** (13 pairs + Cyprus) → update `country_en`
5. **Apply ASCII normalization** (remove all diacritics from country_en)
6. **Assign ISO codes** via countrycode package
7. **Add consolidation_flag** (TRUE for rows with changed names)
8. **Validate output** (4,200 rows, ~190 unique countries, all ISO codes assigned)
9. **Export** → `data/processed/rwb_standardized.rds`

---

## Key Implementation Notes

### Territorial Variant Handling
- **Rows to DELETE:** ~20-30 rows total
  - Israel (occupied territories): ~2 rows
  - US (in Iraq): ~3 rows
  - US (outside US territory): ~6 rows
- **Rows to CONSOLIDATE:** ~30-40 rows
  - Israel variants consolidated to "Israel"
  - US variants consolidated to "United States"

### Cyprus Consolidation
- **Expected impact:** ~20-30 rows
- Cyprus North (2004-2022) + Northern Cyprus (2023-2025) + Northern Cyprus (Occupied) (2026) → single "Cyprus" entry
- All years represented, single standardized name

### Final Dataset Statistics
- **Starting rows:** 4,200
- **After removing territorial variants:** ~4,170-4,180
- **After consolidation:** 4,170-4,180 (same; consolidation merges names, not rows)
- **Unique countries (before consolidation):** 207
- **Unique countries (after consolidation):** ~180-185
- **100% ISO code coverage:** All consolidated names map to valid ISO codes


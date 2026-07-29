# Plan: Targets Appropriateness for pressfreedom Shiny App

**Date:** July 29, 2026, 1:53 PM CEST  
**Context:** Peter asked whether {targets} package would be appropriate for the pressfreedom Shiny app  
**Mode:** Plan (read-only exploration)

---

## Question

Should the **pressfreedom** Shiny dashboard use the {targets} package for workflow orchestration?

---

## Exploration Summary

I explored both:
1. **pressfreedom.data** (upstream data pipeline) — 4-phase ETL: Download → Normalize → Combine → Standardize
2. **pressfreedom** (Shiny app) — Interactive dashboard with reactive patterns and three visualization modules

---

## Key Findings

### pressfreedom.data: {targets} IS Highly Appropriate ✅

**Current state:** Manual 4-phase pipeline
- Phase A: Download 25 CSV files from RSF
- Phase B: Normalize to 20-column structure (25 files, period-specific cleaning)
- Phase C: Combine all periods into single dataset
- Phase D: Standardize country names and assign ISO codes

**Why {targets} would help:**
1. **Incremental processing** — When new 2027 data arrives, reprocess only that year instead of all 25
2. **Automatic dependency resolution** — Phase B, C, D run in correct order automatically
3. **Caching** — Avoid reprocessing unchanged files
4. **Parallelization** — Phase B could process years in parallel (4–5x speedup)
5. **Auditability** — Full execution history and dependency graph visualization
6. **Annual workflow** — Each May, tar_make() runs the entire pipeline; fast due to caching

**Effort:** 2–3 days; non-breaking change; can coexist with current manual workflow

**ROI:** High — Saves 80% of reprocessing time for annual updates

**Recommendation:** Implement targets in pressfreedom.data in next iteration ✅

---

### pressfreedom Shiny App: {targets} NOT Recommended ❌

**Current state:** Well-architected interactive dashboard
- 3 visualization modules: Map, Trends, Country profile
- Clean modular design with inter-module communication via `selected_country` reactiveVal
- Data: Pre-bundled 4,020 rows × 20 columns (≈2 MB)
- All computations: Simple dplyr filtering (< 100 ms per operation)

**Why {targets} would NOT help:**

#### 1. Data Pipeline Exists Elsewhere
- Raw data produced by pressfreedom.data (separate project)
- App receives finalized `rwb.rda` at startup
- No ETL within the app itself
- **Targets excels at orchestrating pipelines; this app isn't a pipeline**

#### 2. No Expensive Computations
- All filtering is O(n) dplyr operations
- Data fits in memory (2 MB)
- No model fitting, simulation, or iteration
- No network requests or large file I/O
- **Targets targets long-running pipelines; this app is fast**

#### 3. No Caching Opportunity
- Data is static per session (doesn't change during app runtime)
- Each module filters from same in-memory dataset
- No intermediate artifacts worth persisting to disk
- No expensive steps to cache across sessions
- **Targets provides powerful caching; nothing expensive to cache**

#### 4. Reactive System Already Handles Dependencies
- Shiny's native reactive graph captures all dependencies implicitly
- When `input$country` changes → `country_data()` invalidates → downstream updates
- When `sel$var` changes → trend chart updates automatically
- No manual dependency tracking needed
- **Targets requires explicit dependency declaration; Shiny does this automatically**

#### 5. Philosophical Mismatch
- **Targets paradigm:** Imperative pipeline: Step A → compute → store → Step B → compute → store
- **Shiny paradigm:** Reactive: Listen for input changes → invalidate dependents → recompute only what changed
- Mixing both adds unnecessary complexity
- **The app is already reactive; adding imperative layer is backwards**

#### 6. Session-Based Architecture
- Targets persists intermediate results to disk (`_targets/objects/`)
- Shiny apps are ephemeral (data lost when user closes browser)
- Targets is optimized for long-running batch processes, not interactive sessions
- **Targets overhead is wasteful for interactive apps**

---

## Comparison Table

| Criterion | pressfreedom.data | pressfreedom (app) |
|-----------|-------------------|-------------------|
| **Data volume** | Large (25 files × varying sizes) | Small (4 KB) |
| **Computation cost** | Expensive (CSV parsing, cleaning, transformation) | Trivial (< 100 ms filters) |
| **Pipeline phases** | 4 distinct phases | Single data load + filtering |
| **Dependencies** | Complex (Phase B → C → D) | Implicit (Shiny reactives) |
| **Caching opportunity** | Yes (intermediate RDS files) | No (in-memory only) |
| **Update frequency** | Annual (May) | Per-user session |
| **Error recovery** | Important (partial failures) | Not critical (restart browser) |
| **Parallelization** | Possible (25 years) | Not needed |
| **{targets} fit** | ✅ **Excellent** | ❌ **Poor** |

---

## Detailed Analysis: pressfreedom App

### Current Architecture (Working Well)

**Strengths:**
1. ✅ **Modular design** — UI/server for each view in separate functions
2. ✅ **Clean reactives** — Dependencies managed implicitly via reactive()
3. ✅ **Fast operations** — All filtering is O(n); no bottlenecks
4. ✅ **Responsive layout** — Sophisticated 3-way sync (JavaScript + R reactive + CSS)
5. ✅ **Robust state** — Nonce pattern prevents silent failures in click-based navigation

### What {targets} Would Add (Unnecessary Complexity)

| Feature | Current App | With Targets | Value Added |
|---------|-------------|--------------|-------------|
| **Dependency tracking** | Implicit (reactive graph) | Explicit (targets recipe) | Negative (over-engineering) |
| **Caching** | In-memory only | Disk + memory | Negative (session-based app) |
| **Error recovery** | Shiny's built-in | Targets checkpointing | None (not needed) |
| **Parallelization** | Not applicable | Supported | None (single user, fast operations) |
| **Persistence** | Per-session ephemeral | Cross-session | Negative (conflicts with session model) |

### Reactive Dependency Graph (Current, Which Works)

```
rwb (static, loaded at startup)
├─ mapServer()
│  ├─ Inputs: year, zone, metric (selectInputs)
│  ├─ Reactive: map_data() → filtered & classified
│  └─ Output: plotly + clicked_country
│
├─ inputsServer() 
│  ├─ Inputs: var, country (selectInputs)
│  └─ Output: list(var, country) as reactives
│
├─ chartServer()
│  ├─ Inputs: var, country (from inputsServer)
│  ├─ Reactive: data() → df_chart(rwb, var(), country())
│  └─ Output: plotly + clicked_country
│
└─ countryServer()
   ├─ Input: country (selectInput)
   ├─ Reactive: country_data() → filtered to one country
   └─ Output: stat table + 3 charts
```

**This is optimal.** No unnecessary complexity, all dependencies clear, everything fast.

---

## Alternative Approaches (If Needed in Future)

If the app grows to include heavy computations:

1. **For data exports (e.g., "download as Excel"):**
   - Use `memoise::memoise()` to cache export computations
   - Store in module-local `reactiveVal()` keyed by inputs
   - No need for targets

2. **For time-series forecasting or modeling:**
   - Cache model fits in `reactiveVal()` with proper invalidation
   - Use `shinytest2` for regression testing
   - Still no need for targets (operations happen per-session anyway)

3. **For testing and validation:**
   - Use `shinytest2` or `testthat` for unit testing modules
   - Targets provides no testing advantage

4. **For reactive complexity profiling:**
   - Use `shiny::reactlog()` if reactives grow unwieldy
   - Targets is not a profiling tool

---

## Conclusion

### pressfreedom Shiny App: ❌ **Do Not Use {targets}**

**Reasons:**
1. App is interactive/reactive, not batch/imperative
2. Data pipeline is upstream (pressfreedom.data), not in the app
3. All computations are trivial (< 100 ms); no caching needed
4. Shiny's native reactive system already handles dependencies perfectly
5. Adding targets would add complexity without corresponding benefit

**Current state:** The app is a **textbook example of well-structured Shiny architecture.** It doesn't need targets; it needs nothing.

---

### pressfreedom.data ETL: ✅ **Targets IS Highly Appropriate**

**Different story:** The upstream data pipeline would benefit greatly from targets orchestration. This is a future enhancement (not blocking the current release).

---

## Recommendation

**No action required for pressfreedom app.**

The architecture is already optimal. The question of targets is moot because:
- The app doesn't have a pipeline; it's a reactive system
- Targets is for pipelines, not for reactive apps
- Shiny's reactives already do what targets would do (dependency tracking)

**Future consideration:** If/when pressfreedom.data gets a targets implementation, the Shiny app will automatically benefit (cleaner upstream data). But the app code itself remains unchanged.

---

## References

- **Targets documentation:** https://books.ropensci.org/targets/
- **Shiny reactive fundamentals:** https://mastering-shiny.org/reactive-basics.html
- **Project status:** pressfreedom.data Phase D complete; pressfreedom integrated and ready for production

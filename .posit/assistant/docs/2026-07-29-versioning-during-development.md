# R Package Versioning During Development

**Date:** 2026-07-29  
**Context:** Decision on whether to bump pressfreedom package version when integrating pressfreedom.data

---

## The Question

Is a version bump necessary if the package hasn't been publicly released?

---

## Short Answer

**Yes.** Version bumps are valuable during development, not just at release time.

---

## Why Version Bumps Matter Even in Pre-release

1. **Documentation trail** — Each version bump documents a significant change (data schema update, breaking changes, new features)
2. **Dependency management** — If pressfreedom depends on pressfreedom.data, you need version constraints to ensure compatibility
3. **Future CRAN submission** — When you eventually publish, your version history shows the maturity and evolution of the project
4. **Team/Collaborator communication** — Semantic versioning signals breaking changes: 0.0.0 → 0.1.0 is "data schema change"

---

## Semantic Versioning for Pre-release

Standard: `MAJOR.MINOR.PATCH`

| Change | Pre-release | Post-release |
|--------|-----------|------------|
| Bug fix (backwards compatible) | 0.0.0 → 0.0.1 | 1.0.0 → 1.0.1 |
| New feature (backwards compatible) | 0.0.0 → 0.1.0 | 1.0.0 → 1.1.0 |
| **Breaking change** (not backwards compatible) | 0.0.0 → 0.1.0 or 1.0.0 | 1.0.0 → 2.0.0 |

---

## Your Situation: Integration of pressfreedom.data

This is a **breaking change** because:
- Row count changes: 4,020 → 4,192
- Country names change: "Russia" → "Russian Federation"
- New columns added (in RDS): `country_name_original`, `consolidation_flag`
- Data source changes: rwb-book → pressfreedom.data
- Data corrections removed: Russia name, 2022 zone corrections (moved to pressfreedom.data)
- Existing scripts referencing specific row counts will break

---

## Recommended Versioning

**pressfreedom.data:**
- Current: 0.1.0 (after Phase 0-1 completion)
- Keep at: 0.1.0 (exporting data is API-stable within Phase D output)

**pressfreedom:**
- Current: 0.0.0.9001 (development version)
- **Bump to: 0.1.0** (marks data source integration milestone)
  - Signals: "Breaking changes; major restructuring of data pipeline"
  - Still pre-release (0.x.x before 1.0.0)
  - Version history documents the integration when you eventually release publicly

---

## Benefits of Version Bumping

✅ Documents the pressfreedom.data integration as a significant milestone  
✅ Signals breaking changes (row count, country names, data source)  
✅ Establishes dependency constraint: pressfreedom 0.1.0 requires pressfreedom.data 0.1.0+  
✅ Cleaner version history when you eventually release publicly (0.1.0, 0.2.0, 1.0.0...)  
✅ Professional development practice even for unreleased projects  

---

## How to Bump Version in pressfreedom

Option 1 (Interactive):
```r
usethis::use_version()
# Choose: patch, minor, or major
# Minor recommended: 0.0.0.9001 → 0.1.0
```

Option 2 (Manual):
- Edit `DESCRIPTION`: Change `Version: 0.0.0.9001` → `Version: 0.1.0`
- Edit `pressfreedom.Rproj` if version is listed there

---

## Decision Made

**Version bump: YES**  
**New version: 0.1.0**  
**Why: Documents data pipeline restructuring and breaking changes**

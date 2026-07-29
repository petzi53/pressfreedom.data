# Plans Directory — Historical Planning and Decision Documents

This directory contains **historical planning documents, decision points, and early-stage plans** for the pressfreedom.data project.

## Organization

This directory contains:
- **Historical plans** that informed the current implementation
- **Decision documents** showing the reasoning behind chosen approaches
- **Quick reference guides** for new contributors
- **Archived early-stage planning** (now superseded by completed work)

**For completed implementation details and workflow documentation, see the adjacent [`docs/`](../docs) directory.**

---

## File Descriptions

### Quick Reference
- **`QUICK-START.md`** — New to the project? Start here. Explains the four-phase workflow at a glance.

### Historical Planning Documents
These documents represent the planning phases and decision-making process. They are preserved for context but have been superseded by the implementation:

- **`2026-07-25-download.md`** — Original Phase A (Download) planning document
- **`2026-07-26-revised-download.md`** — Revised Phase A plan separating download from cleaning
- **`2026-07-27-B1-normalization.md`** — Historical Phase B planning with discovered issues
- **`2026-07-28-1703-plan.md`** — Decision point: sequencing of B1 → C → B2
- **`2026-07-28-1825-plan.md`** — Phase D planning focusing on app compatibility

All of these have been incorporated into the final workflow and implementation documented in [`../docs/`](../docs).

---

## Four-Phase Workflow

The pressfreedom.data project uses a sequential pipeline:

| Phase | Name | Task | Status |
|-------|------|------|--------|
| **A** | Download | Fetch raw CSV files from RSF | ✅ Complete |
| **B** | Normalize | Normalize column names, structure, types | ✅ Complete |
| **C** | Combine | Merge all periods into single dataset | ✅ Complete |
| **D** | Standardize | Standardize country names and ISO codes | ✅ Complete |
| **Integration** | Integrate with pressfreedom app | Connect pressfreedom.data to pressfreedom package | ✅ Complete |

---

## Related Documentation

**Implementation & Completion Reports:**
See [`../docs/`](../docs) for:
- Phase-specific implementation details
- Completion reports with results and validation
- Workflow overview and architecture
- Integration summary with pressfreedom app

**Project Memory:**
See project root [AGENTS.md](../../AGENTS.md) for:
- Project overview and context
- Key design decisions
- Annual update workflow

---

## Why Plans and Docs are Separated

**`plans/` — Strategy & Decision-Making**
- Shows the thinking process
- Documents alternative approaches considered
- Preserves historical context for future reference
- Useful for understanding *why* decisions were made

**`docs/` — Implementation & Reference**
- Documents the final implementation
- Provides detailed technical specifications
- Includes validation and test results
- Serves as the primary reference for future work

This separation helps distinguish between "how we decided to do it" vs. "how we actually did it".

---

## Contributing

When adding to this directory:
1. New **implementation plans** should go here (marked with future date or "TODO" status)
2. **Completed work** should move to `docs/` with a completion note
3. Keep descriptive filenames with dates (YYYY-MM-DD format)
4. Reference other documents clearly

When work is complete:
- Move implementation docs to `docs/`
- Update relevant sections in parent project (AGENTS.md)
- Archive superseded plans here with a note pointing to the replacement


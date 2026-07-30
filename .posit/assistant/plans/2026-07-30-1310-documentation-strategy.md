# Documentation Strategy for pressfreedom.data

**Date:** 2026-07-30  
**Context:** Planning comprehensive documentation before CRAN submission  
**User:** Peter Baumgartner  
**Status:** Planning Phase

---

## Executive Summary

You're creating a multi-level documentation architecture that serves different audiences at different depths:

1. **Vignette (Package-Level)** — How to use the package: quick-start, data, functions, workflows
2. **pkgdown Website (Official Public Docs)** — Polished, searchable reference site for CRAN users
3. **Quarto Book (Learning & Development)** — Deep-dive on design decisions, failures, problem-solving, and Posit Assistant's role
4. **Blog Posts (Public Interest)** — Standalone articles on selected topics (press freedom data, data pipelines, AI-assisted development)

### Recommended Approach

**Start with vignette → pkgdown → Quarto book → blog posts (parallel)**

This sequencing maximizes efficiency:
- Vignette provides the foundation for pkgdown
- Vignette + pkgdown prepare you for the book's deeper analysis
- Blog topics can be extracted from the book as writing progresses
- All four products can coexist and reference each other

---

## 1. Package Vignette

### What It Is

A long-form guide bundled with the package (appears in CRAN, RStudio Help, `browseVignettes()`). Complements the README by diving deeper into usage patterns and workflows.

### Purpose & Audience

- **Purpose:** Show package users how to use pressfreedom.data in practice
- **Audience:** R users, researchers, data analysts who've installed the package
- **Not for:** Technical design decisions, development history, or AI assistance details

### Content Structure (Recommended)

```
1. Introduction & motivation (2-3 min read)
   - What is press freedom data?
   - Why use this package?
   - Quick link to live data

2. Installation & quick start (3-5 min)
   - Installation instructions
   - Load the dataset
   - First 3-4 exploratory code examples

3. Understanding the data (5-7 min)
   - Column reference (copy from README)
   - Data quality notes (2011 missing, consolidations, ISO codes)
   - Methodological periods (3 periods, how to filter)
   - Temporal considerations (gaps, evolution columns)

4. Common usage patterns (8-10 min)
   - Track country trends over time
   - Compare countries in a year
   - Aggregate by zone (when available)
   - Work with dimensional data (Political, Economic, Legal, Social, Safety)

5. Annual updates (3-5 min)
   - When/how new data arrives
   - Using update_rwb_data()
   - Manual control over phases

6. Working with analysis packages
   - Combining with other datasets (WJP Rule of Law Index, V-Dem, etc.)
   - Suggested visualization approaches
   - Integration with tidymodels for modeling

7. FAQ & troubleshooting (2-3 min)
   - "Why is 2011 missing?"
   - "Why is Turkey called Turkiye?"
   - "How do I report a data issue?"
```

**Estimated length:** ~2,500-3,500 words / 15-20 minute read

### Technical Details

- **File location:** `vignettes/pressfreedom-introduction.Rmd` (R Markdown, not Quarto)
  - R Markdown is standard for CRAN vignettes
  - Rendered automatically when package is installed
  
- **Metadata (YAML front matter):**
  ```yaml
  ---
  title: "Getting Started with pressfreedom.data"
  author: "Peter Baumgartner"
  date: "`r Sys.Date()`"
  output: rmarkdown::html_vignette
  vignette: >
    %\VignetteIndexEntry{Getting Started with pressfreedom.data}
    %\VignetteEngine{knitr::rmarkdown}
    %\VignetteEncoding{UTF-8}
  ---
  ```

- **Key considerations:**
  - Use `library()` calls explicitly so users see what to load
  - Keep code examples copy-paste ready (avoid absolute paths)
  - All code should be executable (no placeholders)
  - Test vignette locally before submission: `devtools::build_vignettes()`

---

## 2. pkgdown Website

### What It Is

An automated, searchable documentation site generated from your README, vignettes, function docs, and optional articles. Hosted on GitHub Pages or Netlify. This becomes your official public-facing documentation.

### Purpose & Audience

- **Purpose:** Professional, polished documentation for end users
- **Audience:** CRAN users, GitHub visitors, researchers, practitioners
- **Not for:** Development process, failures, or design rationale

### What Gets Generated Automatically

- Landing page (from README)
- Function reference (from roxygen2 docs)
- News/Changelog
- Vignettes (as "Guides")
- License

### Custom Articles You'll Add

pkgdown lets you add optional "articles" beyond vignettes. Suggested articles:

1. **Data Quality & Consolidation** — Detailed reference on country consolidation rules, territorial variants, ISO coding
2. **Methodological Periods** — Explanation of the three RSF periods and their differences
3. **Building with pressfreedom.data** — Examples of downstream analysis, visualization, and integration

### Technical Details

- **File location:** `pkgdown/_pkgdown.yml` (configuration)
  ```yaml
  url: https://petzi53.github.io/pressfreedom.data
  template:
    bootstrap: 5
  navbar:
    structure:
      left:  [home, intro, reference, articles, news]
      right: [github]
  ```

- **Article location:** `vignettes/` or `pkgdown/articles/` (markdown or Rmd)

- **Build & preview locally:**
  ```r
  pkgdown::build_site()  # Generates site/ directory
  pkgdown::preview_site() # Serves locally
  ```

- **Deploy to GitHub Pages:**
  - Add to `.github/workflows/pkgdown.yaml` (GitHub Actions)
  - Or deploy manually after `pkgdown::build_site()`

### Timeline

- **Minimal viable site:** Just README + function reference (automatic)
- **Full site:** Add 1-2 custom articles + polish styling

---

## 3. Quarto Book: "Building pressfreedom.data"

### What It Is

A comprehensive learning document that combines narrative, code, and reflection. This is your **learning journal** about the project and your collaboration with Posit Assistant.

### Purpose & Audience

- **Purpose:** Document design decisions, failures, problem-solving strategies, and your understanding of what Posit Assistant did
- **Audience:** Yourself, other developers, data engineers, AI enthusiasts
- **For:** Deep learning, reproducibility, methodology, design rationale

### Content Structure (Suggested)

```
I. Introduction & Context
  1.1 Why build this package?
  1.2 The data source (RSF)
  1.3 The challenge: 24 years of evolving methodology
  1.4 Overview of the solution

II. Phase A: Download (Data Acquisition)
  2.1 Problem: Where is the data? (RSF URLs, CSV locations)
  2.2 Implementation: download_rwb_data()
  2.3 Challenges solved
      - Encoding issues (Latin-1 vs UTF-8)
      - URL discovery
  2.4 Testing strategy

III. Phase B: Normalize (Column Standardization)
  3.1 Problem: Three periods, three different schemas
  3.2 Period analysis (2002-2012, 2013-2021, 2022-2026)
  3.3 Implementation: clean_period_1/2/3()
  3.4 Failures & iterations
      - Initial approach (manual column mapping)
      - Issue: Decimal separators (comma vs period)
      - Issue: Factor vs character columns
      - Solution: Systematic normalization functions
  3.5 Design decision: 20-column unified structure (why this number?)

IV. Phase C: Combine (Period Integration)
  4.1 Problem: Merge three periods into one dataset
  4.2 Implementation: combine_cleaned_periods()
  4.3 Evolution columns: How to calculate year-over-year changes?
  4.4 Challenges
      - 2011 gap: No interpolation (design decision)
      - Rank evolution calculation

V. Phase D: Standardize (Country & ISO Codes)
  5.1 Problem: Duplicate/variant country names across datasets
  5.2 Country consolidation rules (14 pairs)
      - Official name changes (Turkiye, Czechia)
      - Territorial issues (Israel, US, Cyprus)
      - Why keep some variants? (Cyprus/Northern Cyprus)
  5.3 ISO coding strategy
  5.4 Implementation: standardize_rwb_countries()
  5.5 Failures
      - Initial countrycode mapping (70% coverage)
      - Manual consolidation vs automated approach
      - Solution: Hybrid with maintainable CSV

VI. The update_rwb_data() Orchestration Function
  6.1 Problem: How to make yearly updates repeatable?
  6.2 Design decision: Why not targets or Make?
      - Pros/cons of workflow tools
      - Simplicity argument
  6.3 Implementation strategy (5-step workflow)
  6.4 Edge cases handled
  6.5 Testing the orchestration

VII. Development Workflow & Posit Assistant
  7.1 How Posit Assistant was used
      - Code generation patterns
      - Problem-solving approach
      - Design iteration cycles
  7.2 What worked well
      - Rapid prototyping
      - Refactoring & cleanup
      - Documentation generation
  7.3 What was challenging
      - Clarifying ambiguous requirements
      - Maintaining consistency across phases
      - R CMD check fixes (non-ASCII issues)
  7.4 Key lessons learned
      - Importance of early testing
      - Value of comprehensive documentation
      - Collaboration patterns with AI

VIII. Quality Assurance & Validation
  8.1 Strategy for ensuring data quality
  8.2 Tests performed
  8.3 Checks built into update_rwb_data()
  8.4 How to catch regressions

IX. Appendix: Code Artifacts
  9.1 Key functions reference (with annotations)
  9.2 Data flow diagrams
  9.3 Complete session logs (select important sessions)

X. Epilogue: Reflections & Next Steps
  10.1 What you learned about data pipeline design
  10.2 What you learned about AI-assisted development
  10.3 Future improvements (6-month roadmap)
```

### Technical Structure

- **Format:** Quarto book (`.qmd` files)
- **Location:** `pressfreedom.data-book/` (separate directory, not in package)
  ```
  pressfreedom.data-book/
  ├── _quarto.yml
  ├── index.qmd
  ├── intro.qmd
  ├── phase-a.qmd
  ├── phase-b.qmd
  ├── phase-c.qmd
  ├── phase-d.qmd
  ├── orchestration.qmd
  ├── posit-assistant.qmd
  ├── qa-validation.qmd
  └── _output/
  ```

- **Publishing:**
  - Quarto publish to GitHub Pages: `quarto publish gh-pages`
  - Or host on Quarto Pub (https://quartopub.com)
  - Or keep as local PDF/HTML for yourself

- **Build locally:** `quarto render` in book directory

### Why Separate from Package?

- Book is for **learning**, package is for **using**
- Helps readers focus on what they need
- Keeps package source clean (vignette is sufficient)
- You can update the book independently of CRAN releases

---

## 4. Blog Posts

### What They Are

Standalone articles on topics extracted from your work, published on a blog or Medium/Dev.to.

### Suggested Topics (Extract from Book)

1. **"Building a Data Pipeline for 24 Years of Evolving Data"**
   - Focus: challenges of handling multiple methodological periods
   - Link to pressfreedom.data
   - No AI component required

2. **"How I Used AI to Build a Production R Package"**
   - Focus: collaboration patterns with Posit Assistant
   - Design decisions made together
   - Failures and how they were solved
   - Lessons on AI-assisted development

3. **"Consolidating 200+ Country Names: The Data Cleaning Problem"**
   - Focus: ISO coding, territorial variants, official changes
   - Could be generic (not package-specific)

4. **"Press Freedom Data Trends 2002-2026: A First Look"**
   - Focus: Initial analysis using pressfreedom.data
   - Purely analytical, shows package use

### Publishing Options

- **Own blog** (Jekyll on GitHub Pages, Quarto site, etc.)
- **Dev.to** (free, developer audience, good for process posts)
- **Medium** (larger audience, good for general interest topics)
- **R Bloggers** (community site, good for R package posts)

### Why Last?

Blog posts are the easiest to extract and update. Write them **after** you've written the book chapter on that topic. The book provides the raw material.

---

## Timeline & Sequencing

### Recommended Order (Critical Path)

```
Week 1 (July 30 - Aug 6)
├─ Vignette (3-4 hours)
│  └─ Write pressfreedom-introduction.Rmd
│  └─ Test with devtools::build_vignettes()
│  └─ CHECKPOINT: Vignette complete
│
└─ pkgdown setup (1-2 hours parallel)
   ├─ Create _pkgdown.yml configuration
   ├─ Decide on 1-2 custom articles
   ├─ Local preview
   └─ CHECKPOINT: pkgdown ready for deployment

Week 2 (Aug 6-13)
├─ Quarto book setup (1 hour)
│  └─ Create directory structure, _quarto.yml
│  └─ Write outline sections (no content yet)
│
└─ Book chapter 1: Introduction (2-3 hours)
   └─ Why build this? The problem statement.

Week 3-4 (Aug 13-27) [Can run parallel with CRAN submission]
├─ Book chapters 2-5: Phases A-D (8-10 hours)
│  └─ Write phase-by-phase, iterating from code
│
└─ Blog post 1: "Building a Data Pipeline..." (1-2 hours)
   └─ Extract from Phase chapters

Week 5 (Aug 27-Sept 3)
├─ Book chapters 6-8: Orchestration, Posit Assistant, QA (6-8 hours)
│
└─ Blog post 2: "How I Used AI to Build..." (2-3 hours)
```

### Can These Run in Parallel?

**Yes, but with caveat:** Start vignette + pkgdown first (they're smaller, unblock other work). Then:

- **Parallel track 1:** CRAN submission process (separate from documentation)
- **Parallel track 2:** Quarto book chapters (write at your own pace)
- **Parallel track 3:** Blog posts (extract from book chapters as they're done)

---

## Product Names & Artifacts

### 1. Vignette
- **Artifact:** `pressfreedom-introduction.Rmd` (in package)
- **Title:** "Getting Started with pressfreedom.data"
- **Audience:** Package users

### 2. pkgdown Site
- **Artifact:** `pkgdown/_pkgdown.yml` + `site/` (generated)
- **URL:** `https://petzi53.github.io/pressfreedom.data`
- **Audience:** CRAN users, public

### 3. Quarto Book
- **Artifact:** `pressfreedom.data-book/` (new directory)
- **Title:** "Building pressfreedom.data: A Data Engineering Story with Posit Assistant"
- **URL:** `https://petzi53.github.io/pressfreedom.data-book` (GitHub Pages)
  - OR `https://quartopub.com/...` (Quarto Pub)
- **Audience:** Developers, data engineers, AI enthusiasts

### 4. Blog Posts
- **Platform:** Dev.to, Medium, or your blog
- **Topics:** See section 4 above
- **Audience:** General tech/data community

---

## Organization & Project Structure

### Updated Directory Layout

```
pressfreedom.data/                           [CRAN package]
├── vignettes/
│   └── pressfreedom-introduction.Rmd       [NEW]
├── pkgdown/
│   └── _pkgdown.yml                        [NEW]
├── R/, data/, man/                         [Existing]
├── README.md                               [Existing]
└── .github/workflows/
    └── pkgdown.yaml                        [NEW - auto-deploy]

../pressfreedom.data-book/                   [NEW - separate repo or dir]
├── _quarto.yml
├── index.qmd
├── intro.qmd
├── phase-a.qmd
├── phase-b.qmd
├── phase-c.qmd
├── phase-d.qmd
├── orchestration.qmd
├── posit-assistant.qmd
├── qa-validation.qmd
└── epilogue.qmd
```

### Git Strategy

- **Vignette + pkgdown:** Commit to pressfreedom.data repo
- **Quarto book:** Option A: Separate GitHub repo (pressfreedom.data-book)
  - Option B: Subdirectory in pressfreedom.data
  - Advantage of separate: Book and package have independent release cycles
  - Advantage of subdirectory: Everything in one place

**Recommendation:** Separate repo (`pressfreedom.data-book`) — cleaner separation of concerns, book can evolve independently.

---

## What NOT to Include

- ❌ Posit Assistant transcripts in package docs
- ❌ Failures/debugging logs in public documentation (vignette, pkgdown)
- ❌ Design rationale in README (that's for the book)
- ❌ Blog posts before the book chapter is written (book is reference)

The book is your "behind the scenes" - it can be candid about struggles. The vignette & pkgdown are public-facing - they focus on *how to use*.

---

## Success Criteria

Each product is "done" when:

1. **Vignette**
   - [x] Rendered without errors
   - [x] All code examples are executable
   - [x] Covers installation, quick start, common patterns
   - [x] Tested with `devtools::build_vignettes()`

2. **pkgdown**
   - [x] Site builds locally without errors
   - [x] All function docs are present and readable
   - [x] README appears as home page
   - [x] Vignette appears as guide
   - [x] Mobile-friendly
   - [x] Deployed to GitHub Pages

3. **Quarto Book**
   - [x] All chapters rendered without errors
   - [x] Cross-references work (chapters link to each other)
   - [x] Code examples are executable (or clearly marked as conceptual)
   - [x] ~15,000-20,000 words total
   - [x] Deployed or available as PDF

4. **Blog Posts**
   - [x] ~1,500-2,500 words each
   - [x] Standalone (readable without context)
   - [x] Links to pressfreedom.data docs
   - [x] Posted and indexed (Dev.to, Medium, etc.)

---

## Summary: Recommended Action Plan

**APPROVE THIS PLAN, then proceed as follows:**

1. **This week:** Vignette (pressfreedom-introduction.Rmd)
2. **Next:** pkgdown setup + 1-2 articles
3. **Parallel:** Quarto book structure + Chapter 1
4. **Ongoing:** Book chapters 2-8 (write at pace)
5. **Extract:** Blog posts from book chapters as they complete
6. **Separate:** Quarto book in its own GitHub repo (pressfreedom.data-book)

This keeps CRAN submission on track while building deep documentation in parallel.

---

## Questions for Approval

Before you approve, consider:

1. **Book location:** Same repo as package, or separate GitHub repo?
   - **Recommendation:** Separate (cleaner, independent release cycles)

2. **Book publishing:** Quarto Pub vs GitHub Pages?
   - **Recommendation:** GitHub Pages (under your control, free)

3. **Blog platform:** Dev.to, Medium, your own blog?
   - **Recommendation:** Dev.to for AI post, your blog or Medium for others

4. **Book scope:** Should it include full session transcripts?
   - **Recommendation:** Summaries + key decisions, not full transcripts (too verbose)


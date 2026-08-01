# Plan: pkgdown Website for pressfreedom.data

## Context

- Package repo: `petzi53/pressfreedom.data` on GitHub, `main` branch, remote already configured.
- `pkgdown` 2.2.1 is installed locally.
- No `_pkgdown.yml`, no `pkgdown/` directory, no `.github/workflows/` yet — this is a from-scratch setup.
- Two vignettes exist: `vignettes/getting-started.Rmd` and `vignettes/visualizing-trends.Rmd` (both already
  in `Suggests`/`VignetteBuilder: knitr`).
- `README.md` is comprehensive and will serve as the pkgdown homepage automatically.
- `man/` has 29 `.Rd` files (many internal/helper functions alongside exported ones) — reference index will
  need curating so the site doesn't dump every internal helper onto one long page.
- Memory file (AGENTS.md) already references a planned `pkgdown/_pkgdown.yml` and a future footer link to a
  companion "Quarto book" once that's live — plan should leave room for that but not implement it now.
- `.Rbuildignore` / `.gitignore` will need a `pkgdown/` doc-output entry (rendered `docs/` folder should be
  ignored by `.Rbuildignore` but tracked or deployed via GitHub Actions, not committed manually).

## Goal

Stand up a working pkgdown site (config + reference organization + GitHub Actions auto-deploy to GitHub
Pages) that serves as the public homepage/documentation for the package, per the four-level docs strategy
already recorded in AGENTS.md (Phase 2 of that plan).

## Proposed Steps

1. **Scaffold pkgdown config**
   - Run `usethis::use_pkgdown()` (creates `_pkgdown.yml` at repo root, adds `^_pkgdown\.yml$` and
     `^docs$` to `.Rbuildignore`).
   - Edit `_pkgdown.yml`:
     - `template: bootstrap: 5`, matching the sandstone-ish aesthetic used in the Quarto site if desired
       (confirm a specific bootswatch theme with you, e.g. `sandstone` to match Quarto conventions).
     - `url: https://petzi53.github.io/pressfreedom.data`
     - Navbar: Home (README), Get Started (getting-started vignette), Articles (visualizing-trends),
       Reference, News (NEWS.md), GitHub icon link.

2. **Curate the Reference index**
DO ONLY REFERENCE DATA `rwb_standarized`! All the other functions are internal and should not have a public API
   - Group `man/*.Rd` topics into logical sections in `_pkgdown.yml` `reference:`, e.g.:
     - **Data**: `rwb_standardized`
     - **Pipeline: Download**: `download_rwb_data`, `get_years_to_download`
     - **Pipeline: Clean**: `clean_all_rwb_years`, `clean_period_1/2/3`, `clean_rwb_single`,
       `normalize_column_names`, `detect_csv_encoding`, `detect_score_column`,
       `standardize_decimal_separators`, `resolve_percent_scaling`, `convert_factors_to_character`,
       `get_period`, `get_period_encoding`, `get_period_mapping`, `period_1/2/3_mapping`,
       `target_columns`
     - **Pipeline: Combine & Standardize**: `combine_cleaned_periods`,
       `consolidate_and_standardize_countries`, `standardize_rwb_countries`,
       `validate_standardization`, `repair_and_asciify`
     - **Update Automation**: `update_rwb_data`, `print.rwb_update`
     - Decide whether internal-only helpers (e.g. `.commit_update`, `.validate_update` — the
       `dot-*.Rd` files) should be excluded from the reference index entirely (common pkgdown practice)
       or included under an "Internal" section. **Will confirm with you.**

3. **Enable vignettes as Articles**
   - pkgdown auto-detects `vignettes/*.Rmd`; confirm both appear correctly under "Articles" (or promote
     `getting-started.Rmd` to a top-level navbar tab per common pkgdown convention, with
     `visualizing-trends.Rmd` under "Articles" dropdown).

4. **News/changelog**
   - `NEWS.md` exists — pkgdown will auto-render this as a "Changelog" tab.

5. **Home page**
   - Confirm `README.md` renders acceptably as-is for pkgdown's homepage (check badges, relative links,
     code chunks all resolve; pkgdown reuses README.md by default, no copy needed).

6. **Local build & smoke test**
   - Run `pkgdown::build_site()` locally, review rendered output in `docs/` (or a temp dir), fix any
     broken links/warnings (e.g. missing topics, dead cross-references).
   - Add `docs/` handling: for local test builds, `docs/` should NOT be committed if deploying via GitHub
     Actions (Actions builds fresh on each push); confirm `.gitignore` also ignores `docs/` at the repo
     root (currently only `.Rbuildignore` will after `use_pkgdown()` — need to check `.gitignore` too
     since `docs/` here also collides with the *Quarto* project's own `docs/` output mentioned in
     AGENTS.md ("Quarto website -> `docs/` -> GitHub Pages"). **This needs clarification: does this repo
     already use `docs/` for a Quarto site?** If so, pkgdown's default `docs/` output will conflict, and
     we should point pkgdown's `destination:` elsewhere (e.g. `pkgdown/pkg-site` or use a separate
     `gh-pages` branch instead of `docs/`) or confirm there's no existing Quarto `docs/` in *this* repo
     (that convention may apply to a different repo/site).

7. **GitHub Actions deployment**
   - Add `.github/workflows/pkgdown.yaml` via `usethis::use_github_action("pkgdown")` (or manually,
     since `usethis::use_pkgdown()` doesn't add the workflow by default) — builds on push to `main` and
     deploys to GitHub Pages (gh-pages branch or Pages "deploy from branch" action).
   - Confirm GitHub Pages settings (branch/folder) on your end — I can't configure repo settings via
     Actions alone; you'll need to enable Pages once the first workflow run completes (I'll note this
     as a manual follow-up step).

8. **Footer / branding touches**
   - Add package logo if one exists (check `man/figures/logo.png`); if none exists, skip (no logo
     creation in this pass — out of scope for pkgdown wiring).
   - Leave a placeholder comment noting the future footer link to the companion Quarto book, per AGENTS.md
     Phase 2 note, without adding a broken link now.

9. **Commit**
   - Stage `_pkgdown.yml`, `.github/workflows/pkgdown.yaml`, updated `.Rbuildignore`/`.gitignore`.
   - Do NOT commit the rendered `docs/` output (built by CI).
   - Update AGENTS.md memory file to mark "pkgdown Website setup" as complete, matching the existing
     documentation-strategy tracking style already in that file.

## Open Questions (need your input before/while implementing)

1. **`docs/` collision**: Does this repo currently produce a Quarto-based `docs/` site, or was that
   AGENTS.md note describing general convention/a different repo? This determines whether pkgdown can use
   the default `docs/` destination or needs a different output path/branch.
   **ANSWER:** No, this repo currently does not produce a Quarto-based `docs/` site
2. **Bootswatch theme**: Any preference for pkgdown's Bootstrap theme (e.g. `sandstone` to match your
   Quarto convention, or pkgdown's default)?
   **ANSWER:** take pkgdown's default theme
3. **Internal helpers in reference index**: exclude dot-prefixed internal functions (`.commit_update`,
   `.validate_update`) from the reference index entirely, or list them under an "Internal" section?
   **ANSWER:** Do not reference any functions. All functions are internal, just for me, the maintainer. Reference only the data: `rwb_standarized`.
4. **Package logo**: do you have one, or should the site launch without a logo for now? 
**ANSWER:** My logo is at man/figures/logo.png
5. **GitHub Pages hosting mechanism**: deploy via the standard `usethis::use_github_action("pkgdown")`
   workflow (pushes rendered site to `gh-pages` branch, Pages serves from there) — confirm this matches
   what you want, given the note about a future GitHub Pages URL for the site
   (`https://petzi53.github.io/pressfreedom.data`).
**ANSWER:** deploy via the standard `usethis::use_github_action("pkgdown")`
   workflow

# Plan: Two-Package Logo Strategy (pressfreedom.data + pressfreedom)

## Context

`pressfreedom.data` now has a finished hex logo (`man/figures/logo.png`):
gold hex border, blue-grey background, white "pressfreedom.data" text, a
microphone glyph, and a choropleth world map rendered in the rocket/viridis
palette.

Peter is building a second, more user-facing package, `pressfreedom`, a
Shiny app that lets users interactively build charts (including maps) from
this data. It also needs a logo, and the two packages' branding needs to be
resolved together instead of independently.

## Decisions already made (via AskUser)

1. **Family branding, shared palette.** Both logos will share the same hex
   sticker structure: gold border, blue-grey background, same font/text
   style. Only the central icon changes between packages. This reinforces
   that they're part of one ecosystem while keeping each icon distinct.
2. **Icon reassignment.**
   - The **existing** map + microphone design moves to `pressfreedom` (the
     Shiny app) -- the microphone (broadcasting/interactivity) and the map
     (its chart-building output) fit that package better than the data
     package.
   - `pressfreedom.data` gets a **new** central icon: an "R data object"
     concept -- a tibble/data-frame glyph (a small rows-x-columns grid)
     paired with an R-flavored mark, signaling "this is the underlying R
     data package."

## Open design details to settle before generating candidates

These are small enough to decide inline while building candidates, but
flagging them here so nothing is assumed silently:

- **Grid glyph style:** a literal small table (visible cell borders, maybe
  3x4) vs. a more abstract "rows of dashes" tibble-print motif (closer to
  how `tibble::print()` renders, or to the classic dplyr/tibble hex
  aesthetic) vs. a stylized spreadsheet icon.
- **"R-flavored mark":** could be the literal R logo circle (trademark
  considerations -- the R logo has usage guidelines), a monospace `R`
  letterform, or simply keeping typography consistent with existing
  tidyverse-style hex stickers (which tends to avoid reusing the R logo
  itself). Recommend avoiding the official R logo mark and instead using a
  simple grid/table glyph alone, or a grid glyph with a small download/arrow
  accent (nodding to "this package produces the data") -- will propose 2-3
  concrete candidates for Peter to pick from rather than deciding this
  unilaterally.
- **Color of the grid glyph:** match the current microphone's white/outline
  style so it reads consistently against the blue-grey background, or use
  a small amount of the map's rocket palette (e.g., grid cells colored like
  a mini score gradient) to visually nod at "this data package feeds the
  score data."

## Implementation steps

1. **Generate 2-3 candidate icons** for the tibble/data-grid glyph
   (R/ggplot2 + `hexSticker`/`magick`, consistent with how the current logo
   was built) at the standard hex sticker canvas size, using the existing
   gold/blue-grey palette.
2. **Render full candidate logos** by compositing each candidate icon onto
   the existing hex template (same border, background, and
   "pressfreedom.data" text) so Peter can compare apples-to-apples against
   the current design.
3. **Review with Peter** (image previews in-session) and iterate on
   whichever candidate he leans toward -- adjust glyph size, stroke weight,
   position, or color as needed.
4. **Finalize `pressfreedom.data` logo:**
   - Overwrite `man/figures/logo.png` in this repo with the approved new
     design.
   - Confirm `usethis::use_logo()` / README badge / pkgdown config (if any)
     still point to the right file and render correctly.
5. **Hand off the original map+microphone logo** for reuse in the
   `pressfreedom` Shiny app repo:
   - Since that's a separate repository (not part of this workspace),
     export the current `man/figures/logo.png` (and/or the source
     R/magick code that generated it, if easily recoverable from the
     session) to a location Peter can copy into the `pressfreedom` repo
     himself (this plan does not modify a repo outside this workspace).
   - Note in this repo's docs/memory (`AGENTS.md`) that the map+microphone
     logo design "belongs" conceptually to `pressfreedom` now, so future
     sessions don't regenerate or reuse it for `pressfreedom.data` by
     mistake.
6. **Update `NEWS.md`** noting the logo change (breaking-visual-identity
   change worth recording, consistent with how the zone-translation change
   was documented).

## Out of scope

- No changes to the `pressfreedom` Shiny app repo itself (outside this
  workspace) -- only preparing/exporting the asset for Peter to place there
  himself.
- No R logo trademark usage without explicit confirmation from Peter.

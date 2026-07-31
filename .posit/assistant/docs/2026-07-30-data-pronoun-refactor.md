# Refactor: `.data` Pronoun Instead of `globalVariables()`

**Date:** 2026-07-30
**Status:** Complete & verified
**Files changed:** `R/combine.R`, `R/standardize.R`, `R/utils.R`
**Verification:** `devtools::check()` -> 0 errors/warnings/notes; `devtools::test()` -> 52/52
pass; regenerated `rwb_combined.rds` and `rwb_standardized.rds` are byte-identical
(`all.equal()`) to the pre-refactor versions.

## The problem `globalVariables()` was patching over

`dplyr` (and other tidyverse packages) use **non-standard evaluation (NSE)**: inside
verbs like `mutate()`, `filter()`, `arrange()`, or `case_when()`, you write bare column
names (`year_n`, `country_en`) as if they were ordinary R variables:

```r
combined_data |> dplyr::arrange(year_n, country_en)
```

At runtime this works because `dplyr` captures the expression unevaluated and resolves
`year_n`/`country_en` against the data frame's columns (a "data mask"), not against the
R environment. But `R CMD check`'s static analyzer (`codetools`) doesn't know about data
masking. It just sees `year_n` and `country_en` used as if they were free variables in
the function body, can't find them defined anywhere (no `<-`, not a formal argument, not
a `library()`-attached object), and emits:

```
checking R code for possible problems ... NOTE
combine_cleaned_periods: no visible binding for global variable 'year_n'
```

The previous fix, `utils::globalVariables(c("year_n", "country_en", ...))`, silences the
NOTE by telling `codetools` "treat these names as known globals, trust me." It works,
but it's a blunt instrument:

- It's a **package-wide, unstructured list** that has no connection to where each name
  is actually used — reading it tells you nothing about *which* function needs *which*
  variable, or why.
- It **grows forever**: every new NSE column reference in any function means editing
  this list again, and the list only gets longer as the package grows.
- It provides **no compile-time or runtime safety** — a typo in the list or in the code
  is invisible; `globalVariables()` just makes the checker stop looking.
- It's often applied as a **reflex fix** without understanding why the NOTE fired,
  which is exactly the "obscure but standard" flavor of pattern debt this refactor is
  meant to strip out.

## The recommended fix: the `.data` pronoun

`rlang` (which `dplyr` is built on) exports a pronoun object called `.data`. Instead of
writing a bare column name, you write `.data$colname`:

```r
# Before (triggers "no visible binding" NOTE)
combined_data |> dplyr::arrange(year_n, country_en)

# After (no NOTE — .data is a real, importable object)
combined_data |> dplyr::arrange(.data$year_n, .data$country_en)
```

`.data$colname` still resolves against the data mask at evaluation time (identical
runtime behavior), but syntactically it's now a reference to a real object (`.data`)
that R's static checker can find, *if* the package properly imports it. That's the whole
fix: `.data` needs exactly one `NAMESPACE` entry,

```r
#' @importFrom rlang .data
```

and from then on every `.data$colname` reference in the package is check-clean — with
**no list to maintain**. This is why the tidyverse team recommends `.data$x` over bare
`x` inside package code (see the ["Data mask
ambiguity"](https://rlang.r-lib.org/reference/dot-data.html) and [Programming with
dplyr](https://dplyr.tidyverse.org/articles/programming.html) vignettes) — it turns a
class of NOTEs that would otherwise require ongoing bookkeeping into something that's
simply correct by construction.

### Where `.data$` was and wasn't applied

`.data$` is for **data-masking** verbs — the ones that evaluate bare column names as
expressions against the data frame: `mutate()`, `filter()`, `arrange()`, `group_by()`,
`case_when()`, `if_else()`, `summarise()`. All of these were updated, e.g. in
`R/standardize.R`:

```r
dplyr::filter(!is.na(.data$country_en_clean))
dplyr::group_by(.data$year_n, .data$country_en_clean)
dplyr::case_when(.data$country_en == "Cyprus" ~ "CYP", ...)
```

**Tidyselect** verbs — `select()`, `rename()`, `relocate()`, `distinct()`, `pull()` —
work differently: they match columns *by name* rather than evaluating expressions in a
data mask, so `.data$` isn't the idiom there. Instead, a plain **string** is the
recommended check-safe form (also more explicit that you mean "the column named X", not
"the value of variable X"):

```r
# Before
dplyr::select(-keep_row, -was_consolidated_territorial)
dplyr::relocate(iso, .after = year_n)
dplyr::pull(country_en)

# After
dplyr::select(-"keep_row", -"was_consolidated_territorial")
dplyr::relocate("iso", .after = "year_n")
dplyr::pull("country_en")
```

## The `:=` case specifically

`R/utils.R`'s `normalize_column_names()` renames columns dynamically (target/source
names come from a lookup table, not literal code), which requires **tidy eval's "walrus"
operator**, `:=`, instead of plain `=`:

```r
df <- df |> dplyr::rename(!!target_col := !!rlang::sym(raw_col))
```

Ordinary `name = value` syntax doesn't work here because `name` would be a literal
identifier, not the *value currently stored in* the `target_col` variable. `:=` lets you
inject (`!!`, "unquote") a computed name on the left-hand side of an `=`-like assignment
inside a tidy eval context. This is a **completely different problem from `.data`**:
`:=` isn't a column-name-resolution issue, it's that `:=` is a genuine function exported
by `rlang` (re-exported by `dplyr`) that the package's `NAMESPACE` never declared using.
`codetools` reports it as:

```
normalize_column_names: no visible global function definition for ':='
```

The fix is the same shape as for `.data` — declare the import once — but note it's a
different tag (`@importFrom`, not a bare listing) because `:=` is an actual function,
not a pronoun:

```r
#' @importFrom rlang :=
```

Both import tags now live together in `R/utils.R`, attached to a `NULL` — a common
roxygen convention for package-wide imports that don't belong to any single documented
function:

```r
#' @importFrom rlang .data
#' @importFrom rlang :=
NULL
```

Running `devtools::document()` turns these into two lines in `NAMESPACE`:

```
importFrom(rlang,":=")
importFrom(rlang,.data)
```

## Is `#' @importFrom` an exception to "always use `pkg::fn()`"?

It looks like it contradicts the project's "no bare/unqualified calls, always
`pkg::fn()`" rule, but it's a different category of thing:

- The **qualified-calls rule** is about readability and avoiding ambiguity when *calling
  functions* in script/function bodies — e.g. writing `dplyr::mutate()` instead of
  attaching `library(dplyr)` and calling bare `mutate()`.
- `@importFrom` is a **NAMESPACE declaration**, conceptually the same category as listing
  a package under `Imports:` in `DESCRIPTION` — it's metadata about the package's
  dependency graph, not a stylistic choice about how a function call reads in the
  source code. It doesn't attach a whole namespace to the search path (unlike
  `library()`), and it doesn't make any *other* function from `rlang` callable
  unqualified — only the one symbol named.
- `.data` and `:=` are also special in that they can't be meaningfully written as
  `rlang::.data` / `` rlang::`:=` `` in the exact syntactic positions `dplyr` expects
  them (`:=` in particular must appear as a genuine infix operator token for R's parser
  to accept `!!target := value` syntax at all) — so a `NAMESPACE` import is really the
  *only* mechanism available, not a stylistic shortcut taken instead of qualification.

So the two conventions coexist without conflict: every *function call* in the codebase
remains `pkg::fn()`-qualified, and the two unavoidable non-call tidy-eval symbols get a
one-line, auditable, minimal-scope import each.

## Summary

| Symbol type | Example | Old fix | New fix |
|---|---|---|---|
| Data-masking column name | `year_n` in `filter()`/`mutate()`/`arrange()` | `globalVariables("year_n")` | `.data$year_n` |
| Tidyselect column name | `keep_row` in `select()`/`pull()` | `globalVariables("keep_row")` | `"keep_row"` (string) |
| Tidy-eval operator | `:=` in dynamic `rename()` | `globalVariables(":=")` | `#' @importFrom rlang :=` |

Net effect: the `globalVariables()` block (an 8-item list that would only grow) is gone
entirely, replaced by two permanent, one-line `NAMESPACE` imports plus check-correct
syntax at each call site. No behavior changed — verified via regenerating both processed
datasets and confirming byte-for-byte equality with the pre-refactor output.

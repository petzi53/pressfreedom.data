# Download RSF Press Freedom Index Data

Downloads press freedom index CSV files from Reporters Without Borders
(RSF) for specified years. Files are saved as-is (unmodified) with
consistent naming (`rwb<year>.csv`).

## Usage

``` r
download_rwb_data(
  years = 2002:2026,
  output_dir = "inst/extdata",
  skip_missing = TRUE
)
```

## Arguments

- years:

  Integer vector. Years to download. Defaults to `2002:2026`.

- output_dir:

  Character. Directory path where CSV files will be saved. Defaults to
  `"inst/extdata"`. Directory is created if it doesn't exist.

- skip_missing:

  Logical. If `TRUE`, automatically skips year 2011 (no official RSF
  data published). Defaults to `TRUE`.

## Value

Invisibly returns a named list where names are years and values indicate
success/failure status. Called for side effects (downloading files).

## Details

RSF publishes press freedom index data at a per-year URL, e.g. for 2024:
<https://rsf.org/sites/default/files/import_classement/2024.csv>
Substitute the target year for `2024` to get other years' data.

\*\*Encoding Handling:\*\* Files are downloaded as raw bytes
(`utils::download.file(mode = "wb")`) and written to disk unmodified. No
parsing, re-encoding, or re-serialization happens at download time, so
whatever bytes RSF serves (RSF has used both UTF-8 and
ISO-8859-1/Latin-1 depending on the year, without warning) are preserved
exactly as-is. Encoding is detected later, per file, when the data is
cleaned (see
[`detect_csv_encoding()`](https://www.peter-baumgartner.net/pressfreedom.data/reference/detect_csv_encoding.md)).

An earlier version of this function read each file with
[`readr::read_delim()`](https://readr.tidyverse.org/reference/read_delim.html)
using a period-based encoding guess and then re-wrote it with
[`readr::write_delim()`](https://readr.tidyverse.org/reference/write_delim.html).
That round-trip silently corrupted the 2002-2021 files (which are
actually UTF-8, not ISO-8859-1 as assumed): text was double-encoded and
numeric columns like `Score N` were mis-parsed (commas treated as
thousands separators, e.g. "92,48" became 9248). Downloading raw bytes
avoids this class of bug entirely.

Year 2011 is not available; no imputation is performed. If
`skip_missing = TRUE`, the function automatically filters out 2011
before downloading.

Error Handling: - Connection failures are logged but don't stop the
function - HTTP 404 errors (missing years) are logged as warnings - File
write permission errors are caught and reported

## Examples

``` r
if (FALSE) { # \dontrun{
# Download all years (excluding 2011) to default directory
download_rwb_data()

# Download specific years to custom directory
download_rwb_data(years = 2020:2026, output_dir = "inst/extdata")
} # }
```

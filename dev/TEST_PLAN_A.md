# Testing Plan A: Download Phase Implementation

## Quick Start

Run one of these commands to test the implementation:

### Option 1: Run via Rscript (Terminal)
```bash
cd ~/Documents/Meine-Repos/pressfreedom.data
Rscript test_plan_a.R
```

### Option 2: Run in RStudio Console
```r
source("test_plan_a.R")
```

### Option 3: Manual Testing in Console
```r
# Load the package
devtools::load_all()

# Test period detection
get_period(2005)     # "period_1"
get_period(2015)     # "period_2"
get_period(2023)     # "period_3"
get_period(2011)     # NA

# Test encoding detection
get_period_encoding(2005)     # "ISO-8859-1"
get_period_encoding(2023)     # "UTF-8"

# Check which years are missing
get_years_to_download()

# Download a single year (e.g., 2003)
download_rwb_data(years = 2003)

# Download a range
download_rwb_data(years = 2004:2006)

# List downloaded files
list.files(here::here("data", "raw"), pattern = "^rwb\\d{4}\\.csv$")
```

## Expected Results

After running the test script, you should see:
- ✓ Period detection for years 2005, 2013, 2022, 2026, 2011
- ✓ Encoding detection (ISO-8859-1 for 2005/2013, UTF-8 for 2022)
- ✓ File reading verification for rwb2002.csv, rwb2013.csv, rwb2022.csv
- ✓ Year detection showing which years are missing from `data/raw/`
- Summary showing all helpers work correctly

## Next Steps

Once testing is complete:

1. **View downloaded files:**
   ```r
   list.files(here::here("data", "raw"))
   ```

2. **Inspect a file to prepare for Plan B (Cleaning):**
   ```r
   # Read first few rows
   rwb2002 <- readr::read_delim(
     here::here("data", "raw", "rwb2002.csv"),
     delim = ";",
     locale = readr::locale(encoding = "ISO-8859-1"),
     show_col_types = FALSE
   )
   head(rwb2002)
   ```

3. **Commit raw files to git:**
   ```bash
   cd ~/Documents/Meine-Repos/pressfreedom.data
   git add data/raw/*.csv
   git commit -m "Add raw RSF CSV files for 2002, 2013, 2022, 2026 (Plan A)"
   ```

## What Was Implemented (Plan A)

### New Functions
- `get_period(year)` — Detects which period a year belongs to
- `get_period_encoding(year)` — Returns appropriate encoding per period

### Updated Functions
- `download_rwb_data()` — Now uses period-aware encoding when downloading
- `get_years_to_download()` — Already existed, unchanged

### Key Features
- ✅ Handles three data periods with different structures and encodings
- ✅ Period 1–2 (2002–2021): ISO-8859-1 encoding
- ✅ Period 3 (2022–2026): UTF-8 encoding
- ✅ Files stored as-is (unmodified) in `data/raw/`
- ✅ Automatic skipping of year 2011 (no official data)
- ✅ Error handling for network and permission issues

## Troubleshooting

### Error: "package or namespace load failed"
```r
# Make sure you're in the project directory
setwd("~/Documents/Meine-Repos/pressfreedom.data")
devtools::load_all()
```

### Error: "could not find function 'get_period'"
```r
# Ensure you ran devtools::load_all() first
devtools::load_all()
```

### Files downloaded but with encoding issues
- Check that the correct encoding was detected: `get_period_encoding(year)`
- For Plan B (cleaning phase), encoding normalization will handle this

---

**Ready to proceed to Plan B (Data Cleaning)?** 
Contact when you want to start the cleaning phase implementation.

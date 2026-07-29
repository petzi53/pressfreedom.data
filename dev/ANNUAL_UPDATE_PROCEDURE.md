# Annual Data Update Procedure

**Project:** pressfreedom.data  
**Purpose:** Update the RSF Press Freedom Index dataset when new data is published annually  
**Frequency:** Once per year (typically July, when RSF releases new data)  
**Time Required:** ~5 minutes  
**Prerequisites:** Git, R/RStudio, internet connection

---

## Overview

Each year, Reporters Without Borders (RSF) publishes a new press freedom index. This document explains how to:

1. Download the new year's data
2. Update your local repository
3. Commit changes to Git
4. Prepare the data for cleaning (Plan B)

---

## Step 1: Run the Update Script

Open R/RStudio and run the update script:

```r
source("dev/update_data.R")
```

### What This Does

The script automatically:
- **Detects missing years** using `get_years_to_download()`
- **Downloads only new years** (e.g., if 2027 is missing, it downloads only 2027)
- **Preserves existing files** (no re-downloads, no overwrites)
- **Reports the result** with the current year range

### Example Output

**First run (initial setup):**
```
Downloading missing years: 2002, 2003, 2004, ...
[OK] Downloaded: /path/to/inst/extdata/rwb2002.csv
[OK] Downloaded: /path/to/inst/extdata/rwb2003.csv
...

Success! Dataset now contains years: 2002-2026 ( 24 files, excluding 2011 )
```

**Subsequent annual runs (new year available):**
```
Downloading missing years: 2027
[OK] Downloaded: /path/to/inst/extdata/rwb2027.csv

Success! Dataset now contains years: 2002-2027 ( 25 files, excluding 2011 )
```

**When no new data is available:**
```
All years already present: 2002-2026 ( 24 files, excluding 2011 )
```

---

## Step 2: Verify the Download

Check that the new CSV file(s) were created:

```bash
# List all downloaded files
ls -lh inst/extdata/rwb*.csv

# Count how many years you have
ls inst/extdata/rwb*.csv | wc -l
```

---

## Step 3: Commit to Git

Once verified, commit the new data:

```bash
git add inst/extdata/
git commit -m "Add RSF Press Freedom Index data for [YEAR]

Downloaded: rwb[YEAR].csv
Now contains years: [MIN_YEAR]-[MAX_YEAR] (skipping 2011)"
```

### Example

For 2027:
```bash
git commit -m "Add RSF Press Freedom Index data for 2027

Downloaded: rwb2027.csv
Now contains years: 2002-2027 (skipping 2011)"
```

---

## Step 4: Prepare for Data Cleaning (Plan B)

The raw CSV file is now in `inst/extdata/rwb[YEAR].csv`. 

**Next step:** Proceed to **Plan B (Data Cleaning Phase)**, which will:

1. Detect the period of the new year (Period 1, 2, or 3)
2. Apply period-appropriate cleaning rules
3. Normalize encoding, column names, and data types
4. Store cleaned data in `data/cleaned/`

For now, the raw file is preserved as-is for auditability.

---

## File Structure

```
pressfreedom.data/
├── inst/extdata/          ← Raw CSV files live here
│   ├── rwb2002.csv
│   ├── rwb2003.csv
│   ...
│   ├── rwb2026.csv
│   └── rwb2027.csv        ← New file added here (yearly)
├── dev/
│   └── update_data.R      ← Script to run (never edit for year changes)
├── R/
│   ├── download.R
│   └── utils.R
└── ...
```

---

## Troubleshooting

### "All years already present" but I expected a new year to download

**Cause:** RSF hasn't published the new year's data yet.

**Solution:** Wait a few days and try again. RSF typically publishes in July, but exact dates vary.

### Download fails with a network error

**Cause:** Network connectivity issue or RSF server temporarily unavailable.

**Solution:** 
1. Wait a few minutes
2. Run `source("dev/update_data.R")` again
3. The script will detect which years are still missing and re-attempt download

### Downloaded file looks wrong (wrong size, can't read it)

**Cause:** Rare—RSF server issue or encoding problem.

**Solution:**
1. Delete the problematic file: `rm inst/extdata/rwbYEAR.csv`
2. Run `source("dev/update_data.R")` again to re-download

---

## Key Points to Remember

✅ **Automated detection** — The script automatically finds missing years; no hard-coded ranges  
✅ **Incremental downloads** — Only new years are downloaded; existing files are never re-downloaded  
✅ **No code changes needed** — Run the same script every year without modifications  
✅ **Preserves raw data** — Files are stored as-is for auditability; cleaning happens later (Plan B)  
✅ **Git-friendly** — Easy to commit new files and track history

---

## When to Run This

- **First time setup:** Now (downloads all 24 years, 2002–2026)
- **Annually:** Once per year when RSF publishes new data (typically July)
- **After failure:** If a download fails, re-run to resume from the last missing year

---

## Next Steps After Update

1. ✅ Run update script → Download new year
2. ✅ Commit to Git → Record data in version control
3. ⏳ **Plan B (cleaning)** → Normalize and standardize the data
4. ⏳ **Plan C (combination)** → Merge all years into one unified dataset

For now, your data is safely stored in raw form. Plan B will be implemented when ready.

---

## Quick Reference: Annual Update Checklist

- [ ] Run `source("dev/update_data.R")`
- [ ] Verify new file(s) in `inst/extdata/`
- [ ] Run `git add inst/extdata/` and `git commit -m "..."`
- [ ] Done! Raw data is backed up in Git

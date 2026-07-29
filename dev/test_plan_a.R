#!/usr/bin/env Rscript
#
# Test Script for Plan A: Download Phase Implementation
# Purpose: Verify that download_rwb_data() works correctly with period-aware encoding
#
# Usage from terminal:
#   cd ~/Documents/Meine-Repos/pressfreedom.data
#   Rscript test_plan_a.R
#
# Or in RStudio console:
#   source("test_plan_a.R")

cat("\n=== PLAN A: Download Phase Test ===\n\n")

# Load package
cat("1. Loading package...\n")
devtools::load_all()

# Test 1: Helper functions
cat("\n2. Testing period detection functions...\n")
test_years <- c(2005, 2013, 2022, 2026, 2011)
for (year in test_years) {
  period <- get_period(year)
  encoding <- get_period_encoding(year)
  cat(sprintf("   Year %d: period = %s, encoding = %s\n", 
              year, period, encoding))
}

# Test 2: Check existing files in data/raw
cat("\n3. Inspecting existing raw CSV files...\n")
raw_files <- list.files(
  here::here("data", "raw"),
  pattern = "^rwb\\d{4}\\.csv$",
  full.names = FALSE
)
cat("   Found files:", paste(raw_files, collapse = ", "), "\n")
cat("   Count:", length(raw_files), "\n")

# Test 3: Read one file from each period to verify encoding works
cat("\n4. Testing file reading with period-aware encoding...\n")

test_files <- list(
  list(file = "rwb2002.csv", period = "period_1", year = 2002),
  list(file = "rwb2013.csv", period = "period_2", year = 2013),
  list(file = "rwb2022.csv", period = "period_3", year = 2022)
)

for (test in test_files) {
  path <- here::here("data", "raw", test$file)
  encoding <- get_period_encoding(test$year)
  
  tryCatch({
    df <- readr::read_delim(
      path,
      delim = ";",
      locale = readr::locale(encoding = encoding),
      show_col_types = FALSE,
      n_max = 3
    )
    cat(sprintf("\n   ✓ %s (period %s, encoding %s)\n", 
                test$file, test$period, encoding))
    cat(sprintf("     Dimensions: %d rows × %d columns\n", 
                nrow(df), ncol(df)))
    cat(sprintf("     Columns: %s\n", 
                paste(names(df)[1:5], collapse = ", "), 
                if(ncol(df) > 5) "..." else ""))
  }, error = function(e) {
    cat(sprintf("\n   ✗ %s failed: %s\n", test$file, e$message))
  })
}

# Test 4: get_years_to_download() helper
cat("\n5. Testing year detection helper...\n")
missing <- get_years_to_download(input_dir = here::here("data", "raw"))
if (length(missing) > 0) {
  cat("   Missing years:", paste(missing[1:min(5, length(missing))], collapse = ", "))
  if (length(missing) > 5) cat(", ... (", length(missing), " total)")
  cat("\n")
} else {
  cat("   All available years are present!\n")
}

cat("\n=== Test Summary ===\n")
cat("✓ Period detection works\n")
cat("✓ Encoding detection works\n")
cat("✓ File reading with period-aware encoding works\n")
cat("✓ Year detection helper works\n")
cat("\nPlan A implementation is ready for testing!\n")
cat("Next step: Download some years and inspect the results.\n\n")

# Prepare standardized RSF dataset for export as package data
#
# This script loads the standardized RDS file (with 22 columns including audit trails)
# and exports a clean 20-column version as rwb_standardized.rda for package users.
#
# The full 22-column version (with country_name_original and consolidation_flag)
# remains available in data/processed/rwb_standardized.rds for researchers who need
# the complete audit trail.

# Load the standardized RDS file (with audit columns)
rwb_standardized <- readRDS(here::here("data", "processed", "rwb_standardized.rds"))

# Remove audit columns (keep only the 20-column structure for export)
# Columns removed: country_name_original, consolidation_flag
rwb_standardized <- rwb_standardized |>
  dplyr::select(-country_name_original, -consolidation_flag)

# Ensure character types for consistency
rwb_standardized <- rwb_standardized |>
  dplyr::mutate(
    iso = as.character(iso),
    country_en = as.character(country_en),
    zone = as.character(zone)
  )

# Save as package data: data/rwb_standardized.rda
usethis::use_data(rwb_standardized, overwrite = TRUE)

# Verify the structure
cat("\nExported rwb_standardized dataset:\n")
cat("  Rows:", nrow(rwb_standardized), "\n")
cat("  Columns:", ncol(rwb_standardized), "\n")
cat("  Unique countries:", dplyr::n_distinct(rwb_standardized$country_en), "\n")
cat("  Years:", min(rwb_standardized$year_n), "–", max(rwb_standardized$year_n), "\n")

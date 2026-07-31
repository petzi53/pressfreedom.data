# Maintainer runbook: annual RSF data update
#
# Run once per year when RSF publishes new Press Freedom Index data
# (typically in spring). Requires a full development checkout of this
# package (devtools::load_all() gives access to the unexported
# download/clean/combine/standardize functions used below); this script
# cannot be run against an installed copy of the package.
#
# The functions called here are internal (unexported) on purpose: they
# hard-code here::here() paths that only resolve inside this checkout, and
# update_rwb_data() performs a git commit as part of its workflow -- neither
# is appropriate for a package consumer or the downstream Shiny app.

devtools::load_all()

# Auto-detects missing years, downloads, cleans, combines, and standardizes
result <- update_rwb_data()
print(result)

# For fine-grained control (e.g. re-running only Phase C/D without a new
# download), see ?update_rwb_data for all arguments and return values.

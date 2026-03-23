# ============================================================================
# 00_MAIN.R
# ============================================================================
#
# DHS Clean Cooking Analysis Pipeline
#
# Usage:
#   1. Edit config/config.R with your survey-specific settings
#   2. Open this script in RStudio and Source it
#
# Always run by sourcing 00_main.R — file paths are relative to its location.
#
# ============================================================================

start_time <- Sys.time()

# ----------------------------------------------------------------------------
# PROJECT DIRECTORY (Clean Version)
# ----------------------------------------------------------------------------
# We assume the user has opened the .Rproj file or is using a runner.
# We do NOT use setwd() here to avoid breaking the parent runner.
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
PROJECT_DIR <- here::here()
cat("Project directory anchored at:", PROJECT_DIR, "\n")


# ----------------------------------------------------------------------------
# SOURCE CONFIGURATION
# ----------------------------------------------------------------------------
cat("Loading configuration...\n")
if (!exists("CONFIG_PATH")) {
  stop(
    "CONFIG_PATH not set. Set it before sourcing 00_main.R e.g.:\n",
    '  CONFIG_PATH <- "Zambia 2024 R/config.R"\n',
    '  source("pipeline/00_main.R")'
  )
}
source(CONFIG_PATH)
cat("Config:", CONFIG_PATH, "\n")
# ----------------------------------------------------------------------------
# SOURCE HELPER FUNCTIONS
# ----------------------------------------------------------------------------

cat("Loading helper functions...\n")
source(here::here("utils", "variable_helpers.R"))
source(here::here("utils", "regression_helpers.R"))
source(here::here("utils", "crosstab_helpers.R"))
source(here::here("utils", "collinearity_helpers.R"))
source(here::here("utils", "export_helpers.R"))
source(here::here("utils", "sample_tracking_helpers.R"))

# Initialize pipeline log — appended to across all pipeline scripts
pipeline_log <- init_pipeline_log()

# ----------------------------------------------------------------------------
# SOURCE ANALYSIS MODULES
# ----------------------------------------------------------------------------

cat("Loading analysis modules...\n")
source(here::here("modules", "collinearity_module.R"))
source(here::here("modules", "regression_module.R"))
source(here::here("modules", "crosstab_module.R"))
source(here::here("modules", "univariable_module.R"))
source(here::here("modules", "sensitivity_module.R"))

# ----------------------------------------------------------------------------
# RUN PIPELINE
# ----------------------------------------------------------------------------
source(here::here("pipeline", "01_setup.R"))
source(here::here("pipeline", "02_load_data.R"))
source(here::here("pipeline", "03_merge_data.R"))
source(here::here("pipeline", "04_create_variables.R"))
source(here::here("pipeline", "05_analysis.R"))
source(here::here("pipeline", "06_export.R"))

# ----------------------------------------------------------------------------
# COMPLETION
# ----------------------------------------------------------------------------

end_time <- Sys.time()
elapsed  <- round(difftime(end_time, start_time, units = "secs"), 1)

cat("\n")
cat("================================================================================\n")
cat("                         PIPELINE COMPLETE                                      \n")
cat("================================================================================\n")
cat("Survey:       ", SURVEY_NAME, "\n")
cat("Completed:    ", format(end_time, "%Y-%m-%d %H:%M:%S"), "\n")
cat("Elapsed time: ", elapsed, " seconds\n")
cat("================================================================================\n")
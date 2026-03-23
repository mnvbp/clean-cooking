# ============================================================================
# 00_MAIN.R - Master Script -- Zambia 2024
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
# SET PROJECT DIRECTORY
# ----------------------------------------------------------------------------
if (interactive()) {
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    doc_path <- rstudioapi::getActiveDocumentContext()$path
    if (!is.null(doc_path) && nchar(doc_path) > 0) {
      PROJECT_DIR <- dirname(doc_path)
    } else {
      PROJECT_DIR <- getwd()
    }
  } else {
    PROJECT_DIR <- getwd()
  }
} else {
  PROJECT_DIR <- getSrcDirectory(function(x) {x})
  if (length(PROJECT_DIR) == 0 || PROJECT_DIR == "") PROJECT_DIR <- getwd()
}

# Go one level up from pipeline/ to the survey root where config.R lives
PROJECT_DIR <- dirname(PROJECT_DIR)

if (!dir.exists(PROJECT_DIR)) {
  stop("Could not determine project directory. Please open 00_main.R in RStudio and source it directly.")
}
setwd(PROJECT_DIR)
cat("Project directory:", PROJECT_DIR, "\n")

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
source("utils/variable_helpers.R")
source("utils/regression_helpers.R")
source("utils/crosstab_helpers.R")
source("utils/collinearity_helpers.R")
source("utils/export_helpers.R")
source("utils/sample_tracking_helpers.R")

# Initialize pipeline log — appended to across all pipeline scripts
pipeline_log <- init_pipeline_log()

# ----------------------------------------------------------------------------
# SOURCE ANALYSIS MODULES
# ----------------------------------------------------------------------------

cat("Loading analysis modules...\n")
source("modules/collinearity_module.R")
source("modules/regression_module.R")
source("modules/crosstab_module.R")
source("modules/univariable_module.R")
source("modules/sensitivity_module.R")

# ----------------------------------------------------------------------------
# RUN PIPELINE
# ----------------------------------------------------------------------------

source("pipeline/01_setup.R")
source("pipeline/02_load_data.R")
source("pipeline/03_merge_data.R")
source("pipeline/04_create_variables.R")
source("pipeline/05_analysis.R")
source("pipeline/06_export.R")

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
# ============================================================================
# 01_SETUP.R - Package Loading and Environment Setup
# ============================================================================

cat("
================================================================================
                    DHS CLEAN COOKING ANALYSIS
================================================================================
")
cat("Survey: ", SURVEY_NAME, "\n")
cat("Loading packages...\n")

if (!require("pacman")) install.packages("pacman")

pacman::p_load(
  haven,      # Read Stata .dta files
  dplyr,      # Data manipulation
  tidyr,      # Data tidying
  openxlsx,   # Excel output
  broom,      # Tidy model outputs
  survey,     # Survey-weighted analyses
  tidylog,    # Logged dplyr operations
  car,        # VIF and regression diagnostics
  future,     # Parallel execution backend
  furrr,       # Parallel map functions (future-backed purrr)
  ggplot2,
  scales
)

select <- dplyr::select

options(survey.lonely.psu = SURVEY_LONELY_PSU)

# ----------------------------------------------------------------------------
# PARALLEL EXECUTION PLAN
# ----------------------------------------------------------------------------
# Uses multicore (fork) on Mac/Linux — zero worker startup overhead.
# Falls back to multisession on Windows — compatible but slightly slower.
# N_CORES set in config.R. NULL = all cores minus one.

n_cores <- if (exists("N_CORES") && !is.null(N_CORES)) {
  min(N_CORES, parallel::detectCores() - 1)
} else {
  max(1, parallel::detectCores() - 1)
}

if (.Platform$OS.type == "unix") {
  future::plan(future::multicore, workers = n_cores)
  cat("Parallel plan: multicore (fork) —", n_cores, "workers\n")
} else {
  future::plan(future::multisession, workers = n_cores)
  cat("Parallel plan: multisession —", n_cores, "workers\n")
}

# ----------------------------------------------------------------------------
# OUTPUT DIRECTORY
# ----------------------------------------------------------------------------

if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
  cat("Created output directory:", OUTPUT_DIR, "\n")
}

cat("Setup complete.\n")
cat("Data directory:  ", BASE_DIR, "\n")
cat("Output directory:", OUTPUT_DIR, "\n")
cat("================================================================================\n\n")
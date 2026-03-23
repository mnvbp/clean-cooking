# ============================================================================
# RUN_ALL_SURVEYS.R
# ============================================================================
#
# Meta-runner: iterates through multiple survey configs and runs the full
# pipeline for each one. Place this file at the repo root alongside
# clean-cooking.Rproj.
#
# Usage:
#   Open clean-cooking.Rproj in RStudio, then source this file.
#   Or from the console: source("run_all_surveys.R")
#
# To add a new survey:
#   1. Create a new folder e.g. Kenya-2022/
#   2. Add a config.R inside it
#   3. Add the config path to SURVEY_CONFIGS below
#
# ============================================================================


# ============================================================================
# SURVEY REGISTRY
# ============================================================================
# Add or remove surveys here. Order determines run order.
# Set enabled = FALSE to skip a survey without removing it.

SURVEY_CONFIGS <- list(
  
  list(
    name    = "Zambia 2018",
    config  = "Zambia-2018/config.R",
    enabled = TRUE
  ),
  
  list(
    name    = "Zambia 2024",
    config  = "Zambia-2024/config.R",
    enabled = TRUE
  )
  
  # ---- Add new surveys below this line ------------------------------------
  #
  # list(
  #   name    = "Kenya 2022",
  #   config  = "Kenya-2022/config.R",
  #   enabled = TRUE
  # ),
  #
  # list(
  #   name    = "Ghana 2019",
  #   config  = "Ghana-2019/config.R",
  #   enabled = FALSE   # skipped
  # )
  # -------------------------------------------------------------------------
)


# ============================================================================
# OPTIONS
# ============================================================================

# If TRUE, a failed survey stops everything. If FALSE, errors are caught and
# the runner continues to the next survey, reporting failures at the end.
STOP_ON_ERROR <- FALSE

# Print a timestamped separator between surveys in the console
VERBOSE <- TRUE


# ============================================================================
# RUNNER  (no edits needed below this line)
# ============================================================================

run_start <- Sys.time()

# Resolve repo root from this file's location
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  REPO_ROOT <- dirname(rstudioapi::getActiveDocumentContext()$path)
  if (nchar(REPO_ROOT) == 0) REPO_ROOT <- getwd()
} else {
  REPO_ROOT <- getwd()
}
setwd(REPO_ROOT)

# Filter to enabled surveys only
enabled_surveys <- Filter(function(s) isTRUE(s$enabled), SURVEY_CONFIGS)

if (length(enabled_surveys) == 0) {
  stop("No surveys are enabled in SURVEY_CONFIGS. Set enabled = TRUE for at least one.")
}

cat("\n")
cat("================================================================================\n")
cat("  MULTI-SURVEY RUNNER\n")
cat("================================================================================\n")
cat(sprintf("  Surveys queued : %d\n", length(enabled_surveys)))
cat(sprintf("  Repo root      : %s\n", REPO_ROOT))
cat(sprintf("  Stop on error  : %s\n", STOP_ON_ERROR))
cat("================================================================================\n\n")

# Collect results
results <- vector("list", length(enabled_surveys))

for (i in seq_along(enabled_surveys)) {
  
  survey <- enabled_surveys[[i]]
  
  if (VERBOSE) {
    cat(sprintf(
      "\n[%d/%d] ── %s ──────────────────────────────────────────────\n",
      i, length(enabled_surveys), survey$name
    ))
    cat(sprintf("  Config : %s\n", survey$config))
    cat(sprintf("  Started: %s\n\n", format(Sys.time(), "%H:%M:%S")))
  }
  
  # Validate config path exists before attempting to run
  if (!file.exists(survey$config)) {
    msg <- sprintf("Config not found: %s", survey$config)
    if (STOP_ON_ERROR) stop(msg)
    warning(msg)
    results[[i]] <- list(name = survey$name, status = "SKIPPED", message = msg, elapsed = NA)
    next
  }
  
  t0 <- proc.time()
  
  tryCatch({
    
    # Set CONFIG_PATH then source the pipeline entrypoint
    CONFIG_PATH <<- survey$config
    source("pipeline/00_main.R")
    
    elapsed <- round((proc.time() - t0)[["elapsed"]], 1)
    results[[i]] <- list(name = survey$name, status = "OK", message = "", elapsed = elapsed)
    cat(sprintf("\n  ✓ %s completed in %s seconds\n", survey$name, elapsed))
    
  }, error = function(e) {
    
    elapsed <- round((proc.time() - t0)[["elapsed"]], 1)
    msg     <- conditionMessage(e)
    results[[i]] <<- list(name = survey$name, status = "ERROR", message = msg, elapsed = elapsed)
    
    cat(sprintf("\n  ✗ %s FAILED after %s seconds\n", survey$name, elapsed))
    cat(sprintf("    Error: %s\n", msg))
    
    if (STOP_ON_ERROR) stop(e)
  })
}


# ============================================================================
# SUMMARY
# ============================================================================

run_end     <- Sys.time()
total_elapsed <- round(difftime(run_end, run_start, units = "secs"), 1)

cat("\n")
cat("================================================================================\n")
cat("  MULTI-SURVEY SUMMARY\n")
cat("================================================================================\n")

n_ok      <- sum(sapply(results, function(r) r$status == "OK"))
n_error   <- sum(sapply(results, function(r) r$status == "ERROR"))
n_skipped <- sum(sapply(results, function(r) r$status == "SKIPPED"))

for (r in results) {
  if (is.null(r)) next
  icon    <- switch(r$status, OK = "✓", ERROR = "✗", SKIPPED = "–")
  elapsed <- if (!is.na(r$elapsed)) sprintf("(%ss)", r$elapsed) else ""
  cat(sprintf("  %s  %-30s %s  %s\n", icon, r$name, r$status, elapsed))
  if (r$status == "ERROR") cat(sprintf("       └─ %s\n", r$message))
}

cat("--------------------------------------------------------------------------------\n")
cat(sprintf("  %d succeeded  |  %d failed  |  %d skipped  |  total: %ss\n",
            n_ok, n_error, n_skipped, total_elapsed))
cat("================================================================================\n\n")

if (n_error > 0) {
  warning(sprintf("%d survey(s) failed. See summary above.", n_error))
}
# ============================================================================
# RUN_ALL_SURVEYS.R
# ============================================================================
# Meta-runner: iterates through multiple survey configs.
# Place this at repo root alongside clean-cooking.Rproj.
# ============================================================================

# ============================================================================
# INITIALIZE PATHS
# ============================================================================
if (!require("here")) install.packages("here")
library(here)

# Establish the root once and for all
REPO_ROOT <- here::here()

# Safety Check: Verify we are in the right place
if (!file.exists(here::here("run_all_surveys.R"))) {
  stop("Root Error: run_all_surveys.R not found in the identified project root: ", REPO_ROOT)
}

# ============================================================================
# SURVEY REGISTRY
# ============================================================================
SURVEY_CONFIGS <- list(
  list(
    name    = "Zambia 2018",
    config  = "Zambia-2018/config.R",
    enabled = FALSE
  ),
  list(
    name    = "Zambia 2024",
    config  = "Zambia-2024/config.R",
    enabled = TRUE
  )
)

# ============================================================================
# OPTIONS
# ============================================================================
STOP_ON_ERROR <- FALSE
VERBOSE       <- TRUE

# ============================================================================
# RUNNER
# ============================================================================
run_start <- Sys.time()

# Filter to enabled surveys
enabled_surveys <- Filter(function(s) isTRUE(s$enabled), SURVEY_CONFIGS)

if (length(enabled_surveys) == 0) {
  stop("No surveys are enabled. Set enabled = TRUE for at least one.")
}

cat("\n================================================================================\n")
cat("  MULTI-SURVEY RUNNER\n")
cat("================================================================================\n")
cat(sprintf("  Surveys queued : %d\n", length(enabled_surveys)))
cat(sprintf("  Project Root   : %s\n", REPO_ROOT))
cat("================================================================================\n\n")

results <- vector("list", length(enabled_surveys))

for (i in seq_along(enabled_surveys)) {
  
  survey <- enabled_surveys[[i]]
  
  if (VERBOSE) {
    cat(sprintf("\n[%d/%d] ── %s ──────────────────────────────────────────────\n",
                i, length(enabled_surveys), survey$name))
  }
  
  # Resolve config path using here()
  full_config_path <- here::here(survey$config)
  
  if (!file.exists(full_config_path)) {
    msg <- sprintf("Config not found: %s", full_config_path)
    if (STOP_ON_ERROR) stop(msg)
    warning(msg)
    results[[i]] <- list(name = survey$name, status = "SKIPPED", message = msg, elapsed = NA)
    next
  }
  
  t0 <- proc.time()
  
  tryCatch({
    # Set the global CONFIG_PATH for 00_main.R to use
    CONFIG_PATH <<- full_config_path
    
    # Source 00_main.R using an absolute-style path from here()
    # We DO NOT use setwd() or chdir = TRUE anymore!
    source(here::here("pipeline", "00_main.R"))
    
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
run_end       <- Sys.time()
total_elapsed <- round(difftime(run_end, run_start, units = "secs"), 1)

cat("\n================================================================================\n")
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
  if (r$status == "ERROR") cat(sprintf("        └─ %s\n", r$message))
}

cat("--------------------------------------------------------------------------------\n")
cat(sprintf("  %d succeeded  |  %d failed  |  %d skipped  |  total: %ss\n",
            n_ok, n_error, n_skipped, total_elapsed))
cat("================================================================================\n\n")
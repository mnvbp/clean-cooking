# ============================================================================
# modules/regression_module.R
# ============================================================================
# Loops over POPULATIONS automatically.
# ============================================================================

REGRESSION_MODULE <- list(
  name    = "Regressions",
  enabled = function() RUN_REGRESSIONS,
  run     = function() {
    out <- list()
    for (pop_key in names(POPULATIONS)) {
      pop        <- POPULATIONS[[pop_key]]
      data       <- get(pop$data)
      outcomes   <- get(pop$outcomes)
      predictors <- get(pop$predictors)
      var_map    <- get(pop$var_map)
      out        <- c(out, run_regressions(outcomes, predictors, data, var_map, pop$label))
    }
    out
  }
)
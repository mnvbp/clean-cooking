# ============================================================================
# modules/regression_module.R
# ============================================================================
# Loops over POPULATIONS automatically.
# ============================================================================

REGRESSION_MODULE <- list(
  name    = "Regressions",
  needs_output_tables = FALSE,
  enabled = function() RUN_REGRESSIONS,
  export  = list(file = "regressions.xlsx", type = "xlsx"),
  run     = function() {
    out <- list()
    for (pop_key in names(POPULATIONS)) {
      pop        <- POPULATIONS[[pop_key]]
      data       <- pop$data
      outcomes   <- pop$outcomes
      predictors <- pop$predictors
      var_map    <- pop$var_map
      out        <- c(out, run_regressions(outcomes, predictors, data, var_map, pop$label))
    }
    out
  }
)
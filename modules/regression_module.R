# ============================================================================
# modules/regression_module.R
# ============================================================================
# Loops over POPULATIONS automatically.
# Each outcome uses its own predictor list from pop$models[[outcome]]$predictors.
# ============================================================================

REGRESSION_MODULE <- list(
  name    = "Regressions",
  needs_output_tables = FALSE,
  export = list(file = "regressions.xlsx", type = "xlsx"),
  enabled = function() RUN_REGRESSIONS,
  run     = function() {
    out <- list()
    for (pop_key in names(POPULATIONS)) {
      pop <- POPULATIONS[[pop_key]]
      out <- c(out, run_regressions(
        models      = pop$models,
        data        = pop$data,
        var_map     = pop$var_map,
        group_label = pop$label
      ))
    }
    out
  }
)
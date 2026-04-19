# ============================================================================
# modules/collinearity_module.R
# ============================================================================
# Run first — results feed into the auto-sensitivity module.
# Predictor names are derived from the schema (role == "predictor").
# ============================================================================

COLLINEARITY_MODULE <- list(
  name    = "Collinearity",
  needs_output_tables = FALSE,
  export = list(file = "diagnostics.xlsx", type = "xlsx"),
  enabled = function() RUN_CORRELATIONS,
  run     = function() {
    out <- list()
    for (pop_key in names(POPULATIONS)) {
      pop        <- POPULATIONS[[pop_key]]
      # Collect all unique predictor names across all outcomes for this population
      predictors <- unique(unlist(lapply(pop$models, function(m) m$predictors)))
      out        <- c(out, run_pairwise_correlations(predictors, pop$data, pop$label))
    }
    out
  }
)
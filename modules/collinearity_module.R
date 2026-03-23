# ============================================================================
# modules/collinearity_module.R
# ============================================================================
# Run first — results feed into the auto-sensitivity module.
# Loops over POPULATIONS automatically.
# ============================================================================

COLLINEARITY_MODULE <- list(
  name    = "Collinearity",
  enabled = function() RUN_CORRELATIONS,
  run     = function() {
    out <- list()
    for (pop_key in names(POPULATIONS)) {
      pop        <- POPULATIONS[[pop_key]]
      data       <- get(pop$data)
      predictors <- get(pop$predictors)
      out        <- c(out, run_pairwise_correlations(predictors, data, pop$label))
    }
    out
  }
)
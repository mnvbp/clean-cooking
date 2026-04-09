# modules/collinearity_module.R

# Run first — results feed into the auto-sensitivity module.
# Loops over POPULATIONS automatically.


COLLINEARITY_MODULE <- list(
  name    = "Collinearity",
  enabled = function() RUN_CORRELATIONS,
  export  = list(file = "diagnostics.xlsx", type = "xlsx"),
  run     = function() {
    out <- list()
    for (pop_key in names(POPULATIONS)) {
      pop        <- POPULATIONS[[pop_key]]
      data       <- pop$data
      predictors <- pop$predictors
      out        <- c(out, run_pairwise_correlations(predictors, data, pop$label))
    }
    out
  }
)
# ============================================================================
# modules/crosstab_module.R
# ============================================================================
# Loops over POPULATIONS automatically.
# ============================================================================

CROSSTAB_MODULE <- list(
  name    = "Crosstabs",
  enabled = function() RUN_CROSSTABS,
  run     = function() {
    out <- list()
    for (pop_key in names(POPULATIONS)) {
      pop         <- POPULATIONS[[pop_key]]
      data        <- get(pop$data)
      outcomes    <- get(pop$outcomes)
      var_map     <- get(pop$var_map)
      stratifiers <- get(pop$stratifiers)
      out         <- c(out, create_crosstabs(outcomes, stratifiers, data, var_map, pop$label))
    }
    out
  }
)

# modules/crosstab_module.R

# Loops over POPULATIONS automatically.


CROSSTAB_MODULE <- list(
  name    = "Crosstabs",
  enabled = function() RUN_CROSSTABS,
  export  = list(file = "crosstabs.xlsx", type = "xlsx"),
  run     = function() {
    out <- list()
    for (pop_key in names(POPULATIONS)) {
      pop         <- POPULATIONS[[pop_key]]
      data        <- pop$data
      outcomes    <- pop$outcomes
      var_map     <- pop$var_map
      stratifiers <- pop$stratifiers
      out         <- c(out, create_crosstabs(outcomes, stratifiers, data, var_map, pop$label))
    }
    out
  }
)
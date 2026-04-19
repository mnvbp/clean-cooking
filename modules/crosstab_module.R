# ============================================================================
# modules/crosstab_module.R
# ============================================================================
# Loops over POPULATIONS automatically.
# Stratifiers are derived from the schema (role == "stratifier").
# Outcomes are derived from pop$models.
# ============================================================================

CROSSTAB_MODULE <- list(
  name    = "Crosstabs",
  needs_output_tables = FALSE,
  export = list(file = "crosstabs.xlsx", type = "xlsx"),
  enabled = function() RUN_CROSSTABS,
  run     = function() {
    out <- list()
    for (pop_key in names(POPULATIONS)) {
      pop         <- POPULATIONS[[pop_key]]
      stratifiers <- get_names(pop$schema, role = "stratifier")
      out         <- c(out, create_crosstabs(
        models      = pop$models,
        stratifiers = stratifiers,
        data        = pop$data,
        var_map     = pop$var_map,
        group_label = pop$label
      ))
    }
    out
  }
)
# ============================================================================
# modules/univariable_module.R
# ============================================================================
# Runs unadjusted (single-predictor) regressions for IAP variables only.
# Loops over POPULATIONS automatically. Runs are parallelized across all
# predictor-population combinations.
#
# Table names: "<Group> - Univariable - <predictor>"
# Routes to diagnostics.xlsx via "- Univariable -" pattern.
# ============================================================================

UNIVARIABLE_MODULE <- list(
  name    = "Univariable",
  enabled = function() RUN_UNIVARIABLE,
  run     = function() {
    
    # Build flat job list — one per IAP predictor per population
    jobs <- unlist(lapply(names(POPULATIONS), function(pop_key) {
      pop        <- POPULATIONS[[pop_key]]
      data       <- get(pop$data)
      outcomes   <- get(pop$outcomes)
      var_map    <- get(pop$var_map)
      predictors <- get(pop$predictors)
      iap        <- intersect(predictors, IAP_PREDICTORS)
      
      lapply(iap, function(pred) {
        list(
          pred     = pred,
          label    = pop$label,
          outcomes = outcomes,
          data     = data,
          var_map  = var_map
        )
      })
    }), recursive = FALSE)
    
    # Run all jobs in parallel
    results <- furrr::future_map(jobs, function(job) {
      res     <- run_regressions(job$outcomes, job$pred, job$data,
                                 job$var_map, job$label)
      stacked <- dplyr::bind_rows(res, .id = "outcome_table")
      list(
        name  = paste0(job$label, " - Univariable - ", job$pred),
        table = stacked
      )
    }, .options = furrr::furrr_options(seed = TRUE))
    
    out <- list()
    for (r in results) out[[r$name]] <- r$table
    out
  }
)
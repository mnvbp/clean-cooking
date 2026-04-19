# ============================================================================
# modules/univariable_module.R
# ============================================================================
# Runs unadjusted (single-predictor) regressions for IAP variables only.
# IAP predictors are filtered from each outcome's predictor list.
# ============================================================================

UNIVARIABLE_MODULE <- list(
  name    = "Univariable",
  needs_output_tables = FALSE,
  export = list(file = "diagnostics.xlsx", type = "xlsx"),
  enabled = function() RUN_UNIVARIABLE,
  run     = function() {
    
    # Build flat job list — one per IAP predictor per population
    jobs <- unlist(lapply(names(POPULATIONS), function(pop_key) {
      pop <- POPULATIONS[[pop_key]]
      
      # Collect all predictors used across all outcomes, intersect with IAP list
      all_preds <- unique(unlist(lapply(pop$models, function(m) m$predictors)))
      iap       <- intersect(all_preds, IAP_PREDICTORS)
      
      lapply(iap, function(pred) {
        # Build a single-predictor models list for this IAP variable
        single_pred_models <- lapply(pop$models, function(m) {
          list(
            label           = m$label,
            weight_override = m$weight_override,
            predictors      = pred   # single predictor
          )
        })
        
        list(
          pred    = pred,
          label   = pop$label,
          models  = single_pred_models,
          data    = pop$data,
          var_map = pop$var_map
        )
      })
    }), recursive = FALSE)
    
    # Run all jobs in parallel
    results <- furrr::future_map(jobs, function(job) {
      res     <- run_regressions(job$models, job$data, job$var_map, job$label)
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
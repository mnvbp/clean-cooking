# ============================================================================
# modules/sensitivity_module.R
# ============================================================================
# Runs sensitivity analyses in two layers:
#
#   1. AUTO runs — derived from collinearity results in output_tables.
#      Uses the first population's collinearity matrix to flag pairs,
#      then generates runs for all populations.
#
#   2. MANUAL runs — from SENSITIVITY_ANALYSES in config.R.
#      Format:
#        my_run = list(
#          label      = "Description",
#          predictors = list(
#            women    = PREDICTORS_WOMEN[PREDICTORS_WOMEN != "urban"],
#            children = PREDICTORS_CHILDREN[PREDICTORS_CHILDREN != "urban"]
#          )
#        )
#      Population keys must match names in POPULATIONS.
#
# Loops over POPULATIONS automatically. Runs are parallelized across all
# run-population combinations.
#
# Table names: "<Group> - Sensitivity - <label>"
# Routes to diagnostics.xlsx via "- Sensitivity -" pattern.
# ============================================================================

SENSITIVITY_MODULE <- list(
  name    = "Sensitivity",
  enabled = function() RUN_SENSITIVITY,
  run     = function(output_tables) {
    
    # ------------------------------------------------------------------
    # Layer 1: Auto-generate from collinearity results
    # Use first population's collinearity matrix to flag pairs
    # ------------------------------------------------------------------
    auto_runs <- list()
    
    first_pop      <- POPULATIONS[[1]]
    first_cor_name <- paste(first_pop$label, "- Collinearity")
    
    if (RUN_CORRELATIONS && first_cor_name %in% names(output_tables)) {
      cor_df  <- output_tables[[first_cor_name]]
      flagged <- flag_collinear_pairs(cor_df, COLLINEARITY_THRESHOLD_R)
      
      if (nrow(flagged) > 0) {
        flagged_vars <- unique(c(flagged$var1, flagged$var2))
        cat("    Collinear variables flagged:", paste(flagged_vars, collapse = ", "), "\n")
        
        for (v in flagged_vars) {
          # Build predictor list for each population — drop flagged variable
          pred_list <- lapply(POPULATIONS, function(pop) {
            preds <- get(pop$predictors)
            preds[preds != v]
          })
          names(pred_list) <- names(POPULATIONS)
          
          auto_runs[[paste0("auto_drop_", v)]] <- list(
            label      = paste("Exclude", v, "(collinear)"),
            predictors = pred_list
          )
        }
      }
    }
    
    # ------------------------------------------------------------------
    # Layer 2: Manual runs from config
    # ------------------------------------------------------------------
    manual_runs <- if (exists("SENSITIVITY_ANALYSES")) SENSITIVITY_ANALYSES else list()
    
    all_runs <- c(auto_runs, manual_runs)
    all_runs <- all_runs[!duplicated(names(all_runs))]
    
    if (length(all_runs) == 0) {
      message("No sensitivity runs to execute.")
      return(list())
    }
    
    cat("    Sensitivity runs to execute:", length(all_runs), "\n")
    for (nm in names(all_runs)) cat("     -", all_runs[[nm]]$label, "\n")
    
    # ------------------------------------------------------------------
    # Build flat job list — one per run per population
    # ------------------------------------------------------------------
    jobs <- unlist(lapply(names(all_runs), function(run_key) {
      run_cfg <- all_runs[[run_key]]
      
      lapply(names(POPULATIONS), function(pop_key) {
        pop      <- POPULATIONS[[pop_key]]
        data     <- get(pop$data)
        outcomes <- get(pop$outcomes)
        var_map  <- get(pop$var_map)
        
        # Get predictors for this population from the run config
        predictors <- if (!is.null(run_cfg$predictors[[pop_key]])) {
          run_cfg$predictors[[pop_key]]
        } else {
          # Fallback: use full predictor list if this population not specified
          get(pop$predictors)
        }
        
        list(
          label      = run_cfg$label,
          group      = pop$label,
          outcomes   = outcomes,
          predictors = predictors,
          data       = data,
          var_map    = var_map
        )
      })
    }), recursive = FALSE)
    
    # ------------------------------------------------------------------
    # Run all jobs in parallel
    # ------------------------------------------------------------------
    results <- furrr::future_map(jobs, function(job) {
      res     <- run_regressions(job$outcomes, job$predictors, job$data,
                                 job$var_map, job$group)
      stacked <- dplyr::bind_rows(res, .id = "outcome_table")
      list(
        name  = paste0(job$group, " - Sensitivity - ", job$label),
        table = stacked
      )
    }, .options = furrr::furrr_options(seed = TRUE))
    
    out <- list()
    for (r in results) out[[r$name]] <- r$table
    out
  }
)
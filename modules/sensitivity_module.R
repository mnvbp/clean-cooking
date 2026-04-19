# ============================================================================
# modules/sensitivity_module.R
# ============================================================================
# Two layers:
#   1. AUTO — drops collinear variables from each outcome's predictor list
#   2. MANUAL — from SENSITIVITY_ANALYSES in config.R
#
# Manual run format (predictors now per-outcome, not per-population):
#
#   SENSITIVITY_ANALYSES <- list(
#     rural_only = list(
#       label  = "Rural households only",
#       filter = list(
#         women    = quote(urban == 0),
#         children = quote(urban == 0)
#       ),
#       drop_predictors = list(
#         women    = "urban",
#         children = "urban"
#       )
#     )
#   )
#
# drop_predictors removes a variable from every outcome's predictor list.
# filter subsets the data before running.
# ============================================================================

SENSITIVITY_MODULE <- list(
  name    = "Sensitivity",
  needs_output_tables = FALSE,
  export = list(file = "diagnostics.xlsx", type = "xlsx"),
  enabled = function() RUN_SENSITIVITY,
  run     = function(output_tables) {
    
    # ------------------------------------------------------------------
    # Layer 1: Auto-generate from collinearity results
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
          auto_runs[[paste0("auto_drop_", v)]] <- list(
            label           = paste("Exclude", v, "(collinear)"),
            filter          = NULL,
            drop_predictors = setNames(
              lapply(names(POPULATIONS), function(k) v),
              names(POPULATIONS)
            )
          )
        }
      }
    }
    
    # ------------------------------------------------------------------
    # Layer 2: Manual runs from config
    # ------------------------------------------------------------------
    manual_runs <- if (exists("SENSITIVITY_ANALYSES")) SENSITIVITY_ANALYSES else list()
    all_runs    <- c(auto_runs, manual_runs)
    all_runs    <- all_runs[!duplicated(names(all_runs))]
    
    if (length(all_runs) == 0) {
      message("No sensitivity runs to execute.")
      return(list())
    }
    
    cat("    Sensitivity runs:", length(all_runs), "\n")
    for (nm in names(all_runs)) cat("     -", all_runs[[nm]]$label, "\n")
    
    # ------------------------------------------------------------------
    # Build flat job list — one per run per population
    # ------------------------------------------------------------------
    jobs <- unlist(lapply(names(all_runs), function(run_key) {
      run_cfg <- all_runs[[run_key]]
      
      lapply(names(POPULATIONS), function(pop_key) {
        pop  <- POPULATIONS[[pop_key]]
        data <- pop$data
        
        # Apply data filter if specified for this population
        if (!is.null(run_cfg$filter[[pop_key]])) {
          data <- dplyr::filter(data, !!run_cfg$filter[[pop_key]])
        }
        
        # Drop variables from each outcome's predictor list
        drop <- run_cfg$drop_predictors[[pop_key]]
        models_adj <- if (!is.null(drop)) {
          lapply(pop$models, function(m) {
            m$predictors <- m$predictors[!m$predictors %in% drop]
            m
          })
        } else {
          pop$models
        }
        
        list(
          label   = run_cfg$label,
          group   = pop$label,
          models  = models_adj,
          data    = data,
          var_map = pop$var_map
        )
      })
    }), recursive = FALSE)
    
    # ------------------------------------------------------------------
    # Run all jobs in parallel
    # ------------------------------------------------------------------
    results <- furrr::future_map(jobs, function(job) {
      res     <- run_regressions(job$models, job$data, job$var_map, job$group)
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
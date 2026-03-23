# ============================================================================
# utils/regression_helpers.R - Regression Analysis Functions
# ============================================================================

#' Get weight variable for an outcome (default or override)
get_outcome_weight <- function(outcome_name, outcomes_config, default_weight) {
  if (!is.null(outcomes_config[[outcome_name]]$weight_override)) {
    return(outcomes_config[[outcome_name]]$weight_override)
  }
  return(default_weight)
}


#' Build survey design with specified weight variable
build_survey_design <- function(data, cluster_var, strata_var, weight_var) {
  weight_col <- paste0(weight_var, "_norm")
  if (!(weight_col %in% names(data))) {
    data[[weight_col]] <- data[[weight_var]] / 1e6
  }
  svydesign(
    id      = as.formula(paste0("~", cluster_var)),
    strata  = as.formula(paste0("~", strata_var)),
    weights = as.formula(paste0("~", weight_col)),
    data    = data,
    nest    = TRUE
  )
}


#' Run regressions for a single outcome — used internally by run_regressions()
#'
#' Self-contained so it can be called in parallel workers without relying
#' on the global environment. All inputs passed explicitly.
#'
#' @return List with $weighted and $unweighted tidy result dataframes
run_single_outcome <- function(outcome, outcomes_config, predictors, data,
                               default_weight, cluster_var, strata_var) {
  preds <- predictors[predictors %in% names(data)]
  
  if (!(outcome %in% names(data))) {
    warning(paste("Outcome", outcome, "not found in data. Skipping."))
    return(list(weighted = NULL, unweighted = NULL))
  }
  
  formula       <- as.formula(paste(outcome, "~", paste(preds, collapse = " + ")))
  outcome_cfg   <- outcomes_config[[outcome]]
  outcome_label <- if (!is.null(outcome_cfg$label)) outcome_cfg$label else outcome
  weight_var    <- get_outcome_weight(outcome, outcomes_config, default_weight)
  
  # Complete cases for THIS outcome only
  model_vars    <- c(outcome, preds)
  complete_rows <- complete.cases(data[, model_vars])
  data_complete <- data[complete_rows, ]
  n_complete    <- nrow(data_complete)
  
  result_unwgt <- NULL
  result_wgt   <- NULL
  
  # ----- Unweighted -----
  tryCatch({
    model       <- glm(formula, data = data_complete, family = binomial())
    result_unwgt <- broom::tidy(model, exponentiate = TRUE, conf.int = TRUE) %>%
      dplyr::mutate(
        stars = dplyr::case_when(
          p.value < 0.001 ~ "***",
          p.value < 0.01  ~ "**",
          p.value < 0.05  ~ "*",
          TRUE            ~ ""
        ),
        ci            = paste0("(", round(conf.low, 2), ", ", round(conf.high, 2), ")"),
        outcome       = outcome,
        outcome_label = outcome_label,
        n             = n_complete
      )
  }, error = function(e) {
    warning(paste("Unweighted regression failed for", outcome, ":", e$message))
  })
  
  # ----- Weighted -----
  tryCatch({
    design     <- build_survey_design(data_complete, cluster_var, strata_var, weight_var)
    n_obs      <- nrow(data_complete)
    n_wgt <- round(sum(weights(design)), 0)
    model_wgt  <- survey::svyglm(formula, design = design, family = quasibinomial())
    result_wgt <- broom::tidy(model_wgt, exponentiate = TRUE, conf.int = TRUE) %>%
      dplyr::mutate(
        stars = dplyr::case_when(
          p.value < 0.001 ~ "***",
          p.value < 0.01  ~ "**",
          p.value < 0.05  ~ "*",
          TRUE            ~ ""
        ),
        ci            = paste0("(", round(conf.low, 2), ", ", round(conf.high, 2), ")"),
        outcome       = outcome,
        outcome_label = outcome_label,
        weight_var    = weight_var,
        n             = n_obs,
        n_weighted    = n_wgt
      )
  }, error = function(e) {
    warning(paste("Weighted regression failed for", outcome, ":", e$message))
  })
  
  list(weighted = result_wgt, unweighted = result_unwgt)
}


#' Run unweighted and weighted logistic regressions for all outcomes
#'
#' Outcomes are processed in parallel using furrr::future_map() with the
#' plan set in 01_setup.R. Falls back to sequential if furrr is unavailable.
#'
#' @param outcomes_config List of outcome configurations
#' @param predictors Vector of predictor variable names
#' @param data Dataframe for analysis
#' @param var_map Variable mapping list
#' @param group_label Label for this population group e.g. "Women", "Children"
#' @return Named list of flat dataframes — one entry per outcome
run_regressions <- function(outcomes_config, predictors, data, var_map,
                            group_label = "Group") {
  default_weight <- var_map$weight_var
  cluster_var    <- var_map$cluster_var
  strata_var     <- var_map$strata_var
  
  outcome_names  <- names(outcomes_config)
  
  # Run outcomes in parallel — each worker gets all required inputs explicitly
  raw_results <- furrr::future_map(
    outcome_names,
    run_single_outcome,
    outcomes_config = outcomes_config,
    predictors      = predictors,
    data            = data,
    default_weight  = default_weight,
    cluster_var     = cluster_var,
    strata_var      = strata_var,
    .options        = furrr::furrr_options(seed = TRUE)
  )
  names(raw_results) <- outcome_names
  
  # Assemble into one entry per outcome — weighted stacked above unweighted
  out <- list()
  for (outcome in outcome_names) {
    label      <- if (!is.null(outcomes_config[[outcome]]$label)) outcomes_config[[outcome]]$label else outcome
    wgt_rows   <- raw_results[[outcome]]$weighted
    unwgt_rows <- raw_results[[outcome]]$unweighted
    
    if (!is.null(wgt_rows))   wgt_rows$section   <- "Weighted"
    if (!is.null(unwgt_rows)) unwgt_rows$section  <- "Unweighted"
    
    if (!is.null(wgt_rows) || !is.null(unwgt_rows)) {
      entry_name        <- paste0(group_label, " - Regressions - ", label)
      out[[entry_name]] <- dplyr::bind_rows(wgt_rows, unwgt_rows)
    }
  }
  
  out
}
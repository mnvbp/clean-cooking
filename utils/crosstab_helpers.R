# ============================================================================
# utils/crosstab_helpers.R - Crosstabulation Functions
# ============================================================================

#' Apply DHS suppression flag based on unweighted N
#'
#' @param n Unweighted count
#' @return Flag string: "*" if <25, "()" if 25-49, "" if >=50
dhs_suppression_flag <- function(n) {
  case_when(
    n < 25 ~ "*",
    n < 50 ~ "()",
    TRUE   ~ ""
  )
}


#' Format N with suppression flag
#'
#' @param n The count to display
#' @param flag The suppression flag ("*", "()", or "")
#' @return Formatted string: "18*", "(42)", or "120"
format_n_with_flag <- function(n, flag) {
  case_when(
    flag == "*"  ~ paste0(n, "*"),
    flag == "()" ~ paste0("(", n, ")"),
    TRUE         ~ as.character(n)
  )
}


#' Apply labels to stratifier values using embedded DHS labels
#'
#' @param data Dataframe containing the stratifier
#' @param strat Name of the stratifier variable
#' @return Vector with labeled values as a factor (preserving DHS order)
#'
#' @details
#' Uses haven::as_factor() to apply labels embedded in the DHS .DTA files.
#' This preserves the correct order (e.g., Poorest -> Richest for wealth)
#' without requiring manual label configuration.
#' Falls back to original values if no labels are embedded.
apply_stratifier_labels <- function(data, strat) {
  values <- data[[strat]]
  if (!is.null(attr(values, "labels"))) {
    return(haven::as_factor(values))
  }
  return(values)
}


#' Create unweighted and weighted crosstabulations with DHS suppression flags
#'
#' @param outcomes_config List of outcome configurations
#' @param stratifiers Vector of stratification variable names
#' @param data Dataframe for analysis
#' @param var_map Variable mapping list
#' @param group_label Label for this population group (e.g. "Women", "Children")
#'   Used to name the entries in the returned list.
#' @return Named list of flat dataframes, ready for export.
#'   Names follow the pattern: "<group_label> - Crosstabs - <outcome> by <stratifier>"
#'
#' @details
#' DHS suppression rules (based on UNWEIGHTED counts):
#' - < 25 cases: Flag with "*" (suppress in final reports)
#' - 25-49 cases: Flag with "()" (use with caution)
#' - >= 50 cases: No flag
#'
#' Labels are applied using embedded DHS labels via haven::as_factor(),
#' which preserves correct ordering (e.g., Poorest -> Richest).
create_crosstabs <- function(outcomes_config, stratifiers, data, var_map,
                             group_label = "Group") {
  out <- list()
  
  default_weight <- var_map$weight_var
  cluster_var    <- var_map$cluster_var
  strata_var     <- var_map$strata_var
  
  for (outcome in names(outcomes_config)) {
    weight_var   <- get_outcome_weight(outcome, outcomes_config, default_weight)
    design       <- build_survey_design(data, cluster_var, strata_var, weight_var)
    strat_tables <- list()
    
    for (strat in stratifiers) {
      if (!(strat %in% names(data)))        next
      if (all(is.na(data[[strat]])))        next
      
      # ----- Unweighted -----
      strat_labeled <- apply_stratifier_labels(data, strat)
      tab <- table(strat_labeled, data[[outcome]], useNA = "no")
      if (ncol(tab) < 2) next
      tab_pct <- prop.table(tab, margin = 1) * 100
      
      unwt_df <- data.frame(
        Variable      = rownames(tab),
        No_N_unwtd    = as.integer(tab[, 1]),
        No_Pct_unwtd  = round(tab_pct[, 1], 2),
        Yes_N_unwtd   = as.integer(tab[, 2]),
        Yes_Pct_unwtd = round(tab_pct[, 2], 2),
        Total_N_unwtd = as.integer(rowSums(tab)),
        stringsAsFactors = FALSE
      )
      
      totals_unwt  <- colSums(tab)
      total_n_unwt <- sum(totals_unwt)
      unwt_df <- rbind(unwt_df, data.frame(
        Variable      = "Total",
        No_N_unwtd    = as.integer(totals_unwt[1]),
        No_Pct_unwtd  = round(totals_unwt[1] / total_n_unwt * 100, 2),
        Yes_N_unwtd   = as.integer(totals_unwt[2]),
        Yes_Pct_unwtd = round(totals_unwt[2] / total_n_unwt * 100, 2),
        Total_N_unwtd = as.integer(total_n_unwt),
        stringsAsFactors = FALSE
      ))
      
      # ----- Weighted -----
      if (all(is.na(design$variables[[strat]]))) next
      
      design_sub <- subset(design,
                           !is.na(design$variables[[outcome]]) &
                             !is.na(design$variables[[strat]]))
      if (nrow(design_sub) == 0) next
      
      design_sub$variables[[strat]] <- apply_stratifier_labels(design_sub$variables, strat)
      
      formula_tab <- as.formula(paste("~", strat, "+", outcome))
      wtab        <- svytable(formula_tab, design = design_sub)
      if (ncol(wtab) < 2) next
      wtab_pct    <- prop.table(wtab, margin = 1) * 100
      
      unwt_tab <- table(design_sub$variables[[strat]],
                        design_sub$variables[[outcome]],
                        useNA = "no")
      
      wt_df <- data.frame(
        Variable     = rownames(wtab),
        No_N_wtd     = round(wtab[, 1], 0),
        No_Pct_wtd   = round(wtab_pct[, 1], 2),
        Yes_N_wtd    = round(wtab[, 2], 0),
        Yes_Pct_wtd  = round(wtab_pct[, 2], 2),
        Total_N_wtd  = round(rowSums(wtab), 0),
        .No_N_unwgt  = as.integer(unwt_tab[, 1]),
        .Yes_N_unwgt = as.integer(unwt_tab[, 2]),
        stringsAsFactors = FALSE
      )
      
      wtotals     <- colSums(wtab)
      unwt_totals <- colSums(unwt_tab)
      wtotal_n    <- sum(wtotals)
      
      wt_df <- rbind(wt_df, data.frame(
        Variable     = "Total",
        No_N_wtd     = round(wtotals[1], 0),
        No_Pct_wtd   = round(wtotals[1] / wtotal_n * 100, 2),
        Yes_N_wtd    = round(wtotals[2], 0),
        Yes_Pct_wtd  = round(wtotals[2] / wtotal_n * 100, 2),
        Total_N_wtd  = round(wtotal_n, 0),
        .No_N_unwgt  = as.integer(unwt_totals[1]),
        .Yes_N_unwgt = as.integer(unwt_totals[2]),
        stringsAsFactors = FALSE
      ))
      
      # ----- Combine and apply suppression flags -----
      combined <- left_join(unwt_df, wt_df, by = "Variable") %>%
        mutate(
          Yes_Flag        = dhs_suppression_flag(Yes_N_unwtd),
          Yes_N_unwtd_fmt = format_n_with_flag(Yes_N_unwtd, Yes_Flag),
          Yes_N_wtd_fmt   = format_n_with_flag(Yes_N_wtd,   Yes_Flag)
        ) %>%
        select(
          Variable,
          No_N_unwtd,  No_Pct_unwtd,
          Yes_N_unwtd  = Yes_N_unwtd_fmt, Yes_Pct_unwtd,
          No_N_wtd,    No_Pct_wtd,
          Yes_N_wtd    = Yes_N_wtd_fmt,   Yes_Pct_wtd,
          Total_N_unwtd, Total_N_wtd
        ) %>%
        mutate(Stratifier = strat, .before = Variable)
      
      strat_tables[[strat]] <- combined
    }
    
    # Stack all stratifiers into one table per outcome
    if (length(strat_tables) > 0) {
      entry_name        <- paste0(group_label, " - Crosstabs - ", outcome)
      out[[entry_name]] <- bind_rows(strat_tables)
    }
  }
  
  out
}
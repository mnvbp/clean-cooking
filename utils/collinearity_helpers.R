# ============================================================================
# utils/collinearity_helpers.R - Collinearity Diagnostics
# ============================================================================

#' Compute pairwise correlations between predictor variables
#'
#' @param predictors Vector of predictor variable names
#' @param data Dataframe containing predictor variables
#' @param group_label Label for this population group (e.g. "Women", "Children")
#'   Used to name the entry in the returned list.
#' @return Named list with one flat dataframe entry, ready for export.
#'   Name follows the pattern: "<group_label> - Collinearity"
#'
#' @details
#' Factors are converted to numeric before computing correlations.
#' NOTE: For wealth_factor, this treats quintiles as a 1-5 ordinal scale.
run_pairwise_correlations <- function(predictors, data, group_label = "Group") {
  preds     <- predictors[predictors %in% names(data)]
  pred_data <- data[, preds, drop = FALSE] %>%
    mutate(across(where(is.factor), as.numeric))
  
  pred_data  <- pred_data[complete.cases(pred_data), ]
  cor_matrix <- cor(pred_data, use = "pairwise.complete.obs")
  cor_matrix <- round(cor_matrix, 3)
  
  # Convert to dataframe with a Variable column for readability
  cor_df <- as.data.frame(cor_matrix)
  cor_df <- cbind(Variable = rownames(cor_df), cor_df)
  rownames(cor_df) <- NULL
  
  entry_name <- paste(group_label, "- Collinearity")
  list(entry_name = cor_df) |> setNames(entry_name)
}


#' Identify high-collinearity predictor pairs from a correlation dataframe
#'
#' @param cor_df Correlation dataframe as returned by run_pairwise_correlations()
#'   (must have a "Variable" column)
#' @param threshold Absolute correlation threshold above which a pair is flagged
#'   (default from config: COLLINEARITY_THRESHOLD_R)
#' @return Dataframe with columns: var1, var2, correlation
#'   Only includes pairs above the threshold, excluding self-correlations.
flag_collinear_pairs <- function(cor_df,
                                 threshold = COLLINEARITY_THRESHOLD_R) {
  vars    <- cor_df$Variable
  mat     <- as.matrix(cor_df[, -1])
  rownames(mat) <- vars
  
  # Extract upper triangle only to avoid duplicates
  pairs <- which(upper.tri(mat), arr.ind = TRUE)
  
  result <- data.frame(
    var1        = vars[pairs[, 1]],
    var2        = vars[pairs[, 2]],
    correlation = mat[pairs]
  )
  
  result[abs(result$correlation) >= threshold, ]
}
# ============================================================================
# utils/sample_tracking_helpers.R - Pipeline Sample Size Tracking
# ============================================================================
#
# Tracks N at each step of the data pipeline across all population groups.
# Works for any DHS study design — add log_step() calls anywhere in the
# pipeline to record what happened and how many observations remain.
#
# Usage:
#   pipeline_log <- init_pipeline_log()
#   pipeline_log <- log_step(pipeline_log, "Children", "De facto filter",
#                            nrow(data), variable = "hv103", condition = "== 1")
#
# ============================================================================


#' Initialize an empty pipeline log
#'
#' @return Empty dataframe with the correct columns
init_pipeline_log <- function() {
  data.frame(
    Pipeline  = character(),
    Step      = character(),
    Variable  = character(),
    Condition = character(),
    N         = integer(),
    Note      = character(),
    stringsAsFactors = FALSE
  )
}


#' Append one step to the pipeline log
#'
#' @param log      Current pipeline log dataframe
#' @param pipeline Population group label e.g. "Children", "Women", "Both"
#' @param step     Human-readable description of the step
#' @param n        Current N after this step
#' @param variable Optional — variable involved in filter/join (from config)
#' @param condition Optional — condition applied e.g. "== 1", "< 60"
#' @param note     Optional — any additional context
#' @return Updated pipeline log with one new row appended
log_step <- function(log, pipeline, step, n,
                     variable  = NULL,
                     condition = NULL,
                     note      = NULL) {
  new_row <- data.frame(
    Pipeline  = pipeline,
    Step      = step,
    Variable  = if (is.null(variable))  "" else variable,
    Condition = if (is.null(condition)) "" else condition,
    N         = as.integer(n),
    Note      = if (is.null(note))      "" else note,
    stringsAsFactors = FALSE
  )
  rbind(log, new_row)
}

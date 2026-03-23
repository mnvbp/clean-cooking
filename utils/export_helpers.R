# ============================================================================
# utils/export_helpers.R - Export Functions
# ============================================================================
#
# Three Excel files are produced:
#   crosstabs.xlsx    — one sheet per outcome, all stratifiers stacked
#   regressions.xlsx  — one sheet per outcome, weighted above unweighted
#   diagnostics.xlsx  — collinearity, sensitivity, univariable
#
# Plus results.rds for the full output_tables object.
#
# Table names in output_tables are used to route to the correct file:
#   "* - Crosstabs - *"    -> crosstabs.xlsx
#   "* - Regressions - *"  -> regressions.xlsx
#   "* - Collinearity"     -> diagnostics.xlsx
#   "* - Sensitivity - *"  -> diagnostics.xlsx
#   "* - Univariable - *"  -> diagnostics.xlsx
#
# To change routing, edit export_results() below.
# To change sheet formatting, edit the write_*_sheet() functions.
#
# ============================================================================


# ----------------------------------------------------------------------------
# UTILITIES
# ----------------------------------------------------------------------------

`%||%` <- function(x, y) if (is.null(x)) y else x


# ----------------------------------------------------------------------------
# SHEET NAME HELPER
# ----------------------------------------------------------------------------

#' Build a sheet name registry for a set of table names
#'
#' Generates short unique sheet names and a legend dataframe mapping
#' each sheet name back to the full table name.
#'
#' Sheet name format: "<G> <Type><N> <Outcome>"
#'   G       = W (Women) or C (Children)
#'   Type    = R (Regression), X (Crosstab), S (Sensitivity),
#'             U (Univariable), D (Collinearity)
#'   N       = index within that type+group combination
#'   Outcome = first 10 chars of outcome label
#'
#' @param names Character vector of full table names
#' @return List with $sheets (named vector: full name -> sheet name)
#'   and $legend (dataframe for the legend sheet)
build_sheet_registry <- function(names) {
  type_code <- function(name) {
    if (grepl("- Crosstabs -",   name)) return("X")
    if (grepl("- Regressions -", name)) return("R")
    if (grepl("- Sensitivity -", name)) return("S")
    if (grepl("- Univariable -", name)) return("U")
    if (grepl("Collinearity",    name)) return("D")
    return("T")
  }
  group_code <- function(name) {
    if (grepl("^Women",    name)) return("W")
    if (grepl("^Children", name)) return("C")
    return("X")
  }
  
  # Count per group+type combination for numbering
  counters <- list()
  sheets   <- character(length(names))
  
  for (i in seq_along(names)) {
    nm  <- names[i]
    g   <- group_code(nm)
    t   <- type_code(nm)
    key <- paste0(g, t)
    
    counters[[key]] <- (counters[[key]] %||% 0) + 1
    n <- counters[[key]]
    
    # Short outcome: strip group/type prefix, take first 12 chars
    short <- nm
    short <- gsub("^Women - |^Children - ", "", short)
    short <- gsub("^Regressions - |^Crosstabs - |^Sensitivity - [^-]+ - |^Univariable - [^-]+ - |^Collinearity", "", short)
    short <- trimws(short)
    short <- substr(short, 1, 12)
    # Remove invalid Excel chars
    for (ch in c("/", "\\", ":", "*", "?", "[", "]", "(", ")")) {
      short <- gsub(ch, "", short, fixed = TRUE)
    }
    short <- trimws(short)
    
    sheet_name    <- substr(paste0(g, t, n, " ", short), 1, 31)
    sheets[i]     <- sheet_name
  }
  
  names(sheets) <- names
  
  legend <- data.frame(
    Sheet      = sheets,
    Full_Name  = names,
    stringsAsFactors = FALSE
  )
  
  list(sheets = sheets, legend = legend)
}


# ----------------------------------------------------------------------------
# CROSSTABS WRITER
# ----------------------------------------------------------------------------

#' Write all crosstab tables to a single Excel workbook
#' One sheet per outcome, all stratifiers stacked with a Stratifier column
#' First sheet is a legend mapping short sheet names to full table names
export_crosstabs_xlsx <- function(tables, filepath) {
  wb       <- openxlsx::createWorkbook()
  registry <- build_sheet_registry(names(tables))
  
  openxlsx::addWorksheet(wb, "Legend")
  openxlsx::writeData(wb, "Legend", registry$legend, startRow = 1)
  
  for (name in names(tables)) {
    sheet <- registry$sheets[[name]]
    openxlsx::addWorksheet(wb, sheet)
    openxlsx::writeData(wb, sheet, tables[[name]], startRow = 1)
  }
  openxlsx::saveWorkbook(wb, filepath, overwrite = TRUE)
  cat("  Saved: crosstabs.xlsx\n")
}


# ----------------------------------------------------------------------------
# REGRESSIONS WRITER
# ----------------------------------------------------------------------------

#' Write all regression tables to a single Excel workbook
#' One sheet per outcome, weighted above unweighted with a section column
#' First sheet is a legend mapping short sheet names to full table names
export_regressions_xlsx <- function(tables, filepath) {
  wb       <- openxlsx::createWorkbook()
  registry <- build_sheet_registry(names(tables))
  
  openxlsx::addWorksheet(wb, "Legend")
  openxlsx::writeData(wb, "Legend", registry$legend, startRow = 1)
  
  for (name in names(tables)) {
    sheet <- registry$sheets[[name]]
    openxlsx::addWorksheet(wb, sheet)
    openxlsx::writeData(wb, sheet, tables[[name]], startRow = 1)
  }
  openxlsx::saveWorkbook(wb, filepath, overwrite = TRUE)
  cat("  Saved: regressions.xlsx\n")
}


# ----------------------------------------------------------------------------
# DIAGNOSTICS WRITER
# ----------------------------------------------------------------------------

#' Write all diagnostic tables to a single Excel workbook
#' Includes collinearity, sensitivity, and univariable — one sheet per table
#' First sheet is a legend mapping short sheet names to full table names
export_diagnostics_xlsx <- function(tables, filepath) {
  wb       <- openxlsx::createWorkbook()
  registry <- build_sheet_registry(names(tables))
  
  openxlsx::addWorksheet(wb, "Legend")
  openxlsx::writeData(wb, "Legend", registry$legend, startRow = 1)
  
  for (name in names(tables)) {
    sheet <- registry$sheets[[name]]
    openxlsx::addWorksheet(wb, sheet)
    openxlsx::writeData(wb, sheet, tables[[name]], startRow = 1)
  }
  openxlsx::saveWorkbook(wb, filepath, overwrite = TRUE)
  cat("  Saved: diagnostics.xlsx\n")
}


# ----------------------------------------------------------------------------
# MAIN EXPORT ROUTER
# ----------------------------------------------------------------------------

#' Export all results — routes each table to the correct Excel file
#' and saves results.rds for re-export without re-running analysis
export_results <- function(output_tables, output_dir) {
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  
  if (length(output_tables) == 0) {
    message("No tables to export.")
    return(invisible(NULL))
  }
  
  # Save full results object
  saveRDS(output_tables, file.path(output_dir, "results.rds"))
  cat("  Saved: results.rds\n")
  
  # Route by name pattern
  is_crosstab   <- grepl("- Crosstabs -",   names(output_tables))
  is_regression <- grepl("- Regressions -", names(output_tables))
  is_diagnostic <- grepl("Collinearity|- Sensitivity -|- Univariable -|Sample Sizes",
                         names(output_tables))
  
  if (any(is_crosstab))
    export_crosstabs_xlsx(output_tables[is_crosstab],
                          file.path(output_dir, "crosstabs.xlsx"))
  
  if (any(is_regression))
    export_regressions_xlsx(output_tables[is_regression],
                            file.path(output_dir, "regressions.xlsx"))
  
  if (any(is_diagnostic))
    export_diagnostics_xlsx(output_tables[is_diagnostic],
                            file.path(output_dir, "diagnostics.xlsx"))
  
  # Warn about any unrouted tables
  unrouted <- output_tables[!is_crosstab & !is_regression & !is_diagnostic]
  if (length(unrouted) > 0)
    warning("Tables not routed to any file:\n",
            paste(" -", names(unrouted), collapse = "\n"))
  
  invisible(NULL)
}
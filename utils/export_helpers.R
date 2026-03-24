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
# Plus forest_plots/ subfolder with one PNG per outcome × population.
#
# Table names in output_tables are used to route to the correct file:
#   "* - Crosstabs - *"    -> crosstabs.xlsx
#   "* - Regressions - *"  -> regressions.xlsx
#   "* - Collinearity"     -> diagnostics.xlsx
#   "* - Sensitivity - *"  -> diagnostics.xlsx
#   "* - Univariable - *"  -> diagnostics.xlsx
#   "* - Forest - *"       -> forest_plots/<name>.png
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
  
  counters <- list()
  sheets   <- character(length(names))
  
  for (i in seq_along(names)) {
    nm  <- names[i]
    g   <- group_code(nm)
    t   <- type_code(nm)
    key <- paste0(g, t)
    
    counters[[key]] <- (counters[[key]] %||% 0) + 1
    n <- counters[[key]]
    
    short <- nm
    short <- gsub("^Women - |^Children - ", "", short)
    short <- gsub("^Regressions - |^Crosstabs - |^Sensitivity - [^-]+ - |^Univariable - [^-]+ - |^Collinearity", "", short)
    short <- trimws(short)
    short <- substr(short, 1, 12)
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
# FOREST PLOTS WRITER
# ----------------------------------------------------------------------------

#' Save all forest plot ggplot objects as individual PNGs.
#' One PNG per outcome x population. Directory is created automatically.
#' File names are sanitized from the output_tables entry name.
export_forest_plots_png <- function(plots, output_dir) {
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  
  cfg        <- if (exists("FOREST_PLOT_CONFIG")) FOREST_PLOT_CONFIG else list()
  png_width  <- cfg$png_width  %||% 8
  png_height <- cfg$png_height %||% NULL   # NULL = auto-sized by term count
  png_dpi    <- cfg$png_dpi    %||% 180
  
  for (name in names(plots)) {
    plot_obj <- plots[[name]]
    if (!inherits(plot_obj, "gg")) next
    
    # Sanitize name -> filename
    # e.g. "Women - Forest - Anemia (women)" -> "Women_Forest_Anemia_women_.png"
    fname <- gsub("[^A-Za-z0-9_]", "_", name)
    fname <- gsub("_+", "_", fname)
    fname <- paste0(fname, ".png")
    fpath <- file.path(output_dir, fname)
    
    # Auto-height: 0.35in per term row + 1.5in for title/axis/legend
    if (is.null(png_height)) {
      n_terms <- nrow(plot_obj$data)
      height  <- max(4, n_terms * 0.35 + 1.5)
    } else {
      height <- png_height
    }
    
    tryCatch({
      ggplot2::ggsave(
        filename = fpath,
        plot     = plot_obj,
        width    = png_width,
        height   = height,
        dpi      = png_dpi,
        bg       = "white"
      )
      cat("  Saved:", fname, "\n")
    }, error = function(e) {
      warning(paste("Forest plot save failed for", name, ":", e$message))
    })
  }
  
  cat("  Forest plots written to:", output_dir, "\n")
}


# ----------------------------------------------------------------------------
# MAIN EXPORT ROUTER
# ----------------------------------------------------------------------------

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
  is_forest     <- grepl("- Forest -",      names(output_tables))
  
  if (any(is_crosstab))
    export_crosstabs_xlsx(output_tables[is_crosstab],
                          file.path(output_dir, "crosstabs.xlsx"))
  
  if (any(is_regression))
    export_regressions_xlsx(output_tables[is_regression],
                            file.path(output_dir, "regressions.xlsx"))
  
  if (any(is_diagnostic))
    export_diagnostics_xlsx(output_tables[is_diagnostic],
                            file.path(output_dir, "diagnostics.xlsx"))
  
  if (any(is_forest))
    export_forest_plots_png(output_tables[is_forest],
                            file.path(output_dir, "forest_plots"))
  
  # Warn about any unrouted tables
  unrouted <- output_tables[!is_crosstab & !is_regression & !is_diagnostic & !is_forest]
  if (length(unrouted) > 0)
    warning("Tables not routed to any file:\n",
            paste(" -", names(unrouted), collapse = "\n"))
  
  invisible(NULL)
}
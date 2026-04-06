# utils/export_helpers.R - Export Functions
#
# Three Excel files are produced:
#   crosstabs.xlsx    — one sheet per outcome, all stratifiers stacked
#   regressions.xlsx  — one sheet per outcome, weighted above unweighted
#   diagnostics.xlsx  — collinearity, sensitivity, univariable
#
# Plus results.rds for the full output_tables object.
# Plus forest_plots/ subfolder with one PNG per outcome × population.
#
# Routing is declared by each module via its export field:
#   export = list(file = "regressions.xlsx", type = "xlsx")
#   export = list(file = "forest_plots",     type = "png")
#
# To add a new output type, add an else if branch in export_results().
# To change sheet formatting, pass a formatter function to export_xlsx().
#

# ----------------------------------------------------------------------------
# UTILITIES
# ----------------------------------------------------------------------------

`%||%` <- function(x, y) if (is.null(x)) y else x


# ----------------------------------------------------------------------------
# SHEET NAME HELPER
# ----------------------------------------------------------------------------

build_sheet_registry <- function(table_names) {
  sheets <- paste0("Sheet", seq_along(table_names))  # Sheet1, Sheet2, ...
  names(sheets) <- table_names
  
  legend <- data.frame(
    Sheet     = sheets,
    Full_Name = table_names,
    stringsAsFactors = FALSE
  )
  
  list(sheets = sheets, legend = legend)
}


# ----------------------------------------------------------------------------
# SHARED EXCEL WRITER
# ----------------------------------------------------------------------------

#' Write a named list of tables to a single Excel workbook.
#'
#' @param tables   Named list of dataframes to write — one sheet each.
#' @param filepath Full path to the output .xlsx file.
#' @param formatter Optional function called after each sheet is written,
#'   signature: function(wb, sheet, table). Use for per-type formatting
#'   e.g. bold headers, column widths, conditional formatting on p-values.
#'   Pass NULL (default) for plain output.
export_xlsx <- function(tables, filepath, formatter = NULL) {
  wb       <- openxlsx::createWorkbook()
  registry <- build_sheet_registry(names(tables))
  
  openxlsx::addWorksheet(wb, "Legend")
  openxlsx::writeData(wb, "Legend", registry$legend, startRow = 1)
  
  for (name in names(tables)) {
    sheet <- registry$sheets[[name]]
    openxlsx::addWorksheet(wb, sheet)
    openxlsx::writeData(wb, sheet, tables[[name]], startRow = 1)
    if (!is.null(formatter)) formatter(wb, sheet, tables[[name]])
  }
  
  openxlsx::saveWorkbook(wb, filepath, overwrite = TRUE)
  cat("  Saved:", basename(filepath), "\n")
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
  png_height <- cfg$png_height %||% NULL
  png_dpi    <- cfg$png_dpi    %||% 180
  
  for (name in names(plots)) {
    plot_obj <- plots[[name]]
    if (!inherits(plot_obj, "gg")) next
    
    fname <- gsub("[^A-Za-z0-9_]", "_", name)
    fname <- gsub("_+", "_", fname)
    fname <- paste0(fname, ".png")
    fpath <- file.path(output_dir, fname)
    
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

export_results <- function(output_tables, output_dir, modules) {
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  if (length(output_tables) == 0) { message("No tables to export."); return(invisible(NULL)) }
  
  saveRDS(output_tables, file.path(output_dir, "results.rds"))
  cat("  Saved: results.rds\n")
  
  xlsx_groups <- list()
  
  for (mod in modules) {
    if (!mod$enabled()) next
    results <- output_tables[grepl(mod$name, names(output_tables))]
    if (length(results) == 0) next
    
    if (mod$export$type == "xlsx") {
      xlsx_groups[[mod$export$file]] <- c(xlsx_groups[[mod$export$file]], results)
    } else if (mod$export$type == "png") {
      export_forest_plots_png(results, file.path(output_dir, mod$export$file))
    }
  }
  
  for (filename in names(xlsx_groups)) {
    export_xlsx(xlsx_groups[[filename]], file.path(output_dir, filename))
  }
  
  invisible(NULL)
}
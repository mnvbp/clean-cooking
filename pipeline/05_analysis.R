# 05_ANALYSIS.R - Run Analyses

# Executes all registered modules in order and collects results into a single
# named list: output_tables.

# To add a new analysis:
#   1. Create a new file in modules/ following the existing module pattern
#   2. Source it in 00_main.R
#   3. Add it to MODULES below

# Collinearity must run first — sensitivity module reads its output
MODULES <- list(
  COLLINEARITY_MODULE,
  REGRESSION_MODULE,
  CROSSTAB_MODULE,
  UNIVARIABLE_MODULE,
  SENSITIVITY_MODULE,
  FOREST_PLOT_MODULE
)

output_tables <- list()

for (mod in MODULES) {
  if (mod$enabled()) {
    cat("\n  Module:", mod$name, "\n")
    
    # Sensitivity module/forestplots receives output_tables so it can read results pror
    result <- if (isTRUE(mod$needs_output_tables)) {
      mod$run(output_tables)
    } else {
      mod$run()
    }
    
    output_tables <- c(output_tables, result)
    cat("  Done:", mod$name, "—", length(result), "table(s) added.\n")
  }
}


# SAMPLE SIZE LOG
# Add pipeline_log to output_tables for export to diagnostics.xlsx

if (exists("pipeline_log") && nrow(pipeline_log) > 0) {
  output_tables[["Sample Sizes"]] <- pipeline_log
}


# SUMMARY
cat("  Total tables collected:", length(output_tables), "\n")
for (nm in names(output_tables)) {
  cat("   -", nm, "\n")
}
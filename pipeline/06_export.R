# ============================================================================
# 06_EXPORT.R - Export Results
# ============================================================================
#
# Writes all tabular results from output_tables to Excel files + results.rds.
# To change output format, edit utils/export_helpers.R only.
# This file never needs to change when new analyses are added.
#
# ============================================================================

cat("Exporting results...\n\n")

export_results(output_tables, OUTPUT_DIR)

# ----------------------------------------------------------------------------
# SUMMARY
# ----------------------------------------------------------------------------

cat("\n")
cat("================================================================================\n")
cat("                           EXPORT COMPLETE                                      \n")
cat("================================================================================\n")
cat("\nFiles saved to:", OUTPUT_DIR, "\n")
cat("  Tables exported:", length(output_tables), "\n")
cat("================================================================================\n")
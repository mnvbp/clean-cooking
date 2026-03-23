# ============================================================================
# 04_CREATE_VARIABLES.R - Derive Analysis Variables
# ============================================================================
#
# This script uses the variable mappings from config.R and helper functions
# from utils/variable_helpers.R to create all analysis variables.
#
# Benefits of this approach:
# - Single source of truth for variable definitions (config.R)
# - Shared recoding logic (variable_helpers.R)
# - Easy to adapt for different DHS phases or countries
#
# ============================================================================

cat("Creating analysis variables...\n")

# ----------------------------------------------------------------------------
# CHILDREN DATASET
# ----------------------------------------------------------------------------

cat("  Creating children variables using VAR_MAP_CHILDREN...\n")

children_data <- create_children_variables(pr_children, VAR_MAP_CHILDREN)

# ----------------------------------------------------------------------------
# WOMEN DATASET
# ----------------------------------------------------------------------------

cat("  Creating women variables using VAR_MAP_WOMEN...\n")

women_data <- create_women_variables(merged_women, VAR_MAP_WOMEN)


# ----------------------------------------------------------------------------
# CREATE SURVEY DESIGNS
# ----------------------------------------------------------------------------
# NOTE: Survey designs are now created dynamically per-outcome in 
# utils/analysis_helpers.R to support outcome-specific weights.
# The build_survey_design() function handles this.

cat("  Survey designs will be created per-outcome during analysis.\n")
cat("  Default weights: Women =", VAR_MAP_WOMEN$weight_var, 
    ", Children =", VAR_MAP_CHILDREN$weight_var, "\n")
cat("  (Override per-outcome in config.R using weight_override)\n")

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------

cat("\nVariable creation complete.\n")
cat("\nChildren dataset (n =", format(nrow(children_data), big.mark = ","), "):\n")
cat("  Variables from:", paste(names(VAR_MAP_CHILDREN), collapse = ", "), "\n")
cat("  Outcomes:\n")
cat("    - anemic:          ", sum(!is.na(children_data$anemic)), " valid\n")
cat("    - cough:           ", sum(!is.na(children_data$cough)), " valid\n")
cat("    - low_birthweight: ", sum(!is.na(children_data$low_birthweight)), " valid\n")

cat("\nWomen dataset (n =", format(nrow(women_data), big.mark = ","), "):\n")
cat("  Variables from:", paste(names(VAR_MAP_WOMEN), collapse = ", "), "\n")
cat("  Outcomes:\n")
cat("    - anemic:       ", sum(!is.na(women_data$anemic)), " valid\n")
cat("    - pregterm:     ", sum(!is.na(women_data$pregterm)), " valid\n")
cat("    - hypertension: ", sum(!is.na(women_data$hypertension)), " valid\n")

cat("================================================================================\n\n")

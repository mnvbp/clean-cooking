# ============================================================================
# 04_CREATE_VARIABLES.R - Derive Analysis Variables
# ============================================================================
#
# Uses apply_schema() to create all standard variables from the schema
# definitions in config.R. Complex two-column variables (anemic for children,
# low_birthweight) are handled explicitly after apply_schema().
#
# ============================================================================

cat("Creating analysis variables...\n")

# ----------------------------------------------------------------------------
# CHILDREN DATASET
# ----------------------------------------------------------------------------

cat("  Creating children variables...\n")

children_data <- pr_children %>%
  # Survey design variables
  mutate(
    survey_weight = !!sym(VAR_MAP_CHILDREN$weight_var) / 1e6,
    cluster       = !!sym(VAR_MAP_CHILDREN$cluster_var),
    strata        = !!sym(VAR_MAP_CHILDREN$strata_var)
  ) %>%
  # All schema-defined variables
  apply_schema(CHILDREN_SCHEMA) %>%
  # Complex two-column outcomes handled explicitly
  mutate(
    anemic = create_child_anemia(
      anemia_values = hc57,
      age_months    = b19,
      min_months    = ANEMIA_AGE_MIN_MONTHS,
      max_months    = ANEMIA_AGE_MAX_MONTHS
    ),
    low_birthweight = create_low_birthweight(
      bw_values        = m19,
      bw_flag          = m19a,
      threshold        = LOW_BIRTH_WEIGHT_THRESHOLD
    )
  )


# ----------------------------------------------------------------------------
# WOMEN DATASET
# ----------------------------------------------------------------------------

cat("  Creating women variables...\n")

women_data <- merged_women %>%
  # Survey design variables
  mutate(
    survey_weight = !!sym(VAR_MAP_WOMEN$weight_var) / 1e6,
    cluster       = !!sym(VAR_MAP_WOMEN$cluster_var),
    strata        = !!sym(VAR_MAP_WOMEN$strata_var),
    # male hardcoded to 0 (female) for stratification compatibility with children
    male          = 0L
  ) %>%
  # All schema-defined variables
  apply_schema(WOMEN_SCHEMA)


# ----------------------------------------------------------------------------
# WIRE DATA INTO POPULATIONS
# ----------------------------------------------------------------------------

POPULATIONS$women$data    <- women_data
POPULATIONS$children$data <- children_data

cat("  Survey designs will be created per-outcome during analysis.\n")
cat("  Default weights: Women =", VAR_MAP_WOMEN$weight_var,
    ", Children =", VAR_MAP_CHILDREN$weight_var, "\n")

# ----------------------------------------------------------------------------
# SUMMARY
# ----------------------------------------------------------------------------

cat("\nVariable creation complete.\n")

cat("\nChildren dataset (n =", format(nrow(children_data), big.mark = ","), "):\n")
cat("  Outcomes:\n")
cat("    - anemic:          ", sum(!is.na(children_data$anemic)), "valid\n")
cat("    - cough:           ", sum(!is.na(children_data$cough)), "valid\n")
cat("    - low_birthweight: ", sum(!is.na(children_data$low_birthweight)), "valid\n")

cat("\nWomen dataset (n =", format(nrow(women_data), big.mark = ","), "):\n")
cat("  Outcomes:\n")
cat("    - anemic:       ", sum(!is.na(women_data$anemic)), "valid\n")
cat("    - pregterm:     ", sum(!is.na(women_data$pregterm)), "valid\n")
cat("    - hypertension: ", sum(!is.na(women_data$hypertension)), "valid\n")

cat("================================================================================\n\n")
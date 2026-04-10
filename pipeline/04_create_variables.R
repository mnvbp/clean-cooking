# 04_CREATE_VARIABLES.R - Derive Analysis Variables

# This script uses the variable mappings from config.R and helper functions
# from utils/variable_helpers.R to create all analysis variables.


#' Create all analysis variables for children dataset
#' 
#' @param data Dataframe (merged PR + KR data)
#' @param var_map Variable mapping list (from config)
#' @return Dataframe with all derived variables added
#' 
#' @details
#' Creates the following variables:
#'   - survey_weight, cluster, strata: Survey design variables
#'   - anemic: Binary anemia (children 6-59 months only)
#'   - cough: Cough in past 2 weeks
#'   - low_birthweight: Low birth weight (<2500g, card weights only)
#'   - dirtyfuel, elec, outsidecook, smoking_frequent: Exposure variables
#'   - poorest, male_head, urban, age, male: Covariates
#'   - region, wealth: Stratification variables
create_children_variables <- function(data, var_map = VAR_MAP_CHILDREN) {
  
  data %>%
    mutate(
      # Survey design
      survey_weight = !!sym(var_map$weight_var) / 1e6,
      cluster = !!sym(var_map$cluster_var),
      strata = !!sym(var_map$strata_var),
      
      # Outcomes
      anemic = create_child_anemia(
        anemia_values = !!sym(var_map$anemia_var),
        age_months = !!sym(var_map$age_months_var),
        min_months = ANEMIA_AGE_MIN_MONTHS,
        max_months = ANEMIA_AGE_MAX_MONTHS
      ),
      cough = create_cough(!!sym(var_map$cough_var)),
      low_birthweight = create_low_birthweight(
        bw_values = !!sym(var_map$bw_var),
        bw_flag = !!sym(var_map$bw_flag_var),
        threshold = LOW_BIRTH_WEIGHT_THRESHOLD
      ),
      
      # Predictors
      dirtyfuel = create_dirtyfuel(!!sym(var_map$fuel_var)),
      elec = create_electricity(!!sym(var_map$elec_var)),
      outsidecook = create_outsidecook(
        !!sym(var_map$cook_loc_var),
        outdoor_codes = var_map$outdoor_codes,
        indoor_codes = var_map$indoor_codes
      ),
      smoking_frequent = create_smoking(!!sym(var_map$smoke_var)),
      wealth_factor = relevel(haven::as_factor(!!sym(var_map$wealth_var)), ref = WEALTH_REFERENCE),
      male_head = create_male_head(!!sym(var_map$hh_sex_var)),
      urban = create_urban(!!sym(var_map$urban_var)),
      age = !!sym(var_map$age_months_var) / 12,
      male = create_male(!!sym(var_map$gender_var)),
      
      # Stratifiers
      region = !!sym(var_map$region_var),
      wealth = !!sym(var_map$wealth_var)
    )
}


#' Create all analysis variables for women dataset
#' 
#' @param data Dataframe (merged PR + IR data)
#' @param var_map Variable mapping list (from config)
#' @return Dataframe with all derived variables added
#' 
#' @details
#' Creates the following variables:
#'   - survey_weight, cluster, strata: Survey design variables
#'   - anemic: Binary anemia (any vs none)
#'   - pregterm: Pregnancy ever terminated
#'   - hypertension: Hypertension (country-specific variable)
#'   - dirtyfuel, elec, outsidecook, smoking_frequent: Exposure variables
#'   - poorest, male_head, urban, age: Covariates
#'   - region, wealth, male: Stratification variables
#' 
#' NOTE (Issue #8): male is hardcoded to 0L (female) for all women to allow
#' stratification compatibility with the children dataset where gender varies.
create_women_variables <- function(data, var_map = VAR_MAP_WOMEN) {
  
  data %>%
    mutate(
      # Survey design
      survey_weight = !!sym(var_map$weight_var) / 1e6,
      cluster = !!sym(var_map$cluster_var),
      strata = !!sym(var_map$strata_var),
      
      # Outcomes
      anemic = create_anemia(!!sym(var_map$anemia_var)),
      pregterm = create_pregterm(!!sym(var_map$pregterm_var)),
      hypertension = create_hypertension(!!sym(var_map$bp_var)),
      
      # Predictors
      dirtyfuel = create_dirtyfuel(!!sym(var_map$fuel_var)),
      elec = create_electricity(!!sym(var_map$elec_var)),
      outsidecook = create_outsidecook(
        !!sym(var_map$cook_loc_var),
        outdoor_codes = var_map$outdoor_codes,
        indoor_codes = var_map$indoor_codes
      ),
      smoking_frequent = create_smoking(!!sym(var_map$smoke_var)),
      wealth_factor = relevel(haven::as_factor(!!sym(var_map$wealth_var)), ref = WEALTH_REFERENCE),
      male_head = create_male_head(!!sym(var_map$hh_sex_var)),
      urban = create_urban(!!sym(var_map$urban_var)),
      age = !!sym(var_map$age_var),
      
      # Stratifiers
      region = !!sym(var_map$region_var),
      wealth = !!sym(var_map$wealth_var),
      # NOTE: male hardcoded to 0 (female) for stratification compatibility
      male = 0L
    )
}

# CHILDREN DATASET
children_data <- create_children_variables(pr_children, VAR_MAP_CHILDREN)


# WOMEN DATASET
women_data <- create_women_variables(merged_women, VAR_MAP_WOMEN)


# Wire data objects into POPULATIONS
POPULATIONS$women$data    <- women_data
POPULATIONS$children$data <- children_data


# CREATE SURVEY DESIGNS

# NOTE: Survey designs are now created dynamically per-outcome in 
# utils/analysis_helpers.R to support outcome-specific weights.
# The build_survey_design() function handles this.

cat("  Survey designs will be created per-outcome during analysis.\n")
cat("  Default weights: Women =", VAR_MAP_WOMEN$weight_var, 
    ", Children =", VAR_MAP_CHILDREN$weight_var, "\n")
cat("  (Override per-outcome in config.R using weight_override)\n")


# Summary

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

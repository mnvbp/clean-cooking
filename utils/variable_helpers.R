# utils/variable_helpers.R - Variable Creation Functions

# These functions provide config-driven variable creation to:
# 1. Eliminate duplication between women/children variable creation
# 2. Make the code adaptable to different DHS phases/countries
# 3. Centralize recoding logic for consistency

#
# METHODOLOGICAL DECISIONS LOG
# ----------------------------
# This section documents key decisions that may need to be referenced in
# your methods section or revisited for sensitivity analyses.
#
# 1. SMOKING (create_smoking, Issue #7):
#    - DHS hv252 codes: 0=never, 1=daily, 2=weekly, 3=monthly, 4=less than monthly
#    - Current grouping: frequent (1,2,3) vs never/rarely (0,4)
#    - DECISION: Code 4 ("less than monthly") grouped with "never" (code 0)
#    - RATIONALE: Exposure focus is on regular indoor air pollution; occasional
#      smoking (<1x/month) has minimal cumulative exposure effect
#    - ALTERNATIVE: Could group code 4 with frequent if any smoking is relevant
#
# 2. LOW BIRTH WEIGHT (create_low_birthweight, Issue #6):
#    - DHS m19a flag codes: 1=from card, 2=from recall
#    - Current: Only card-based weights (flag=1) are used
#    - DECISION: Recall weights (flag=2) excluded to ensure data quality
#    - RATIONALE: Card weights are measured; recall weights are mother's memory
#    - ALTERNATIVE: Set valid_flag_codes=c(1,2) to include recall weights
#
# 3. WEALTH DICHOTOMIZATION (create_poorest, Issue #17):
#    - DHS hv270 codes: 1=poorest, 2=poorer, 3=middle, 4=richer, 5=richest
#    - Current: Compares poorest (1) vs middle (3) only
#    - DECISION: Quintiles 2, 4, 5 become NA and are EXCLUDED from analysis
#    - RATIONALE: Clean contrast between extreme poor and middle reference
#    - IMPLICATION: ~60% of observations have NA for poorest
#    - ALTERNATIVE: Use full wealth quintile as categorical, or different contrasts
#
# 4. WOMEN GENDER VARIABLE (create_women_variables, Issue #8):
#    - All women assigned male=0L (female) for stratification compatibility
#    - DECISION: Hardcoded to allow gender stratification across both datasets
#    - IMPLICATION: When stratifying by gender, all women appear as single stratum
#
# 5. OUTSIDECOOK ASYMMETRY (Issue #16):
#    - DHS hv241 codes: 1=in house, 2=separate building, 3=outdoors
#    - Women: outdoor_codes=2 (separate building = ventilated)
#    - Children: outdoor_codes=3 (only true outdoors)
#    - DECISION: Different definitions reflect different exposure models
#    - See config.R for the specific codes used in each pipeline
#


#' Recode a variable to binary (1/0/NA)
#' 
#' @param x Vector of values to recode
#' @param yes_values Values that map to 1
#' @param no_values Values that map to 0
#' @return Integer vector with 1, 0, or NA
recode_binary <- function(x, yes_values, no_values) {
  
  case_when(
    x %in% yes_values ~ 1L,
    x %in% no_values ~ 0L,
    TRUE ~ NA_integer_
  )
}


#' Create dirty fuel indicator
#' 
#' @param fuel_values Vector of fuel type codes
#' @param clean_codes Codes for clean fuels (default from config)
#' @param dirty_codes Codes for dirty fuels (default from config)
#' @return Integer vector: 1 = dirty fuel, 0 = clean fuel, NA = other/missing
#' 
#' @details
#' DHS fuel codes (hv226/v161):
#'   Clean: 1=electricity, 2=LPG, 3=natural gas, 4=biogas, 12=solar
#'   Dirty: 5=kerosene, 6=coal/lignite, 7=charcoal, 8=wood, 9=straw/shrubs/grass,
#'          10=agricultural crop, 11=animal dung
#'   Excluded: 95=no food cooked, 96=other, 97=not dejure resident
#' 
#' NOTE: Women use v161, children use hv226. These should have identical coding
#' but come from different questionnaires. See config.R CLEAN_FUELS/DIRTY_FUELS.
create_dirtyfuel <- function(fuel_values, 
                             clean_codes = CLEAN_FUELS, 
                             dirty_codes = DIRTY_FUELS) {
  case_when(
    fuel_values %in% clean_codes ~ 0L,
    fuel_values %in% dirty_codes ~ 1L,
    TRUE ~ NA_integer_
  )
}


#' Create electricity access indicator
#' 
#' @param elec_values Vector of electricity codes (typically 0/1)
#' @return Integer vector: 1 = has electricity, 0 = no electricity
#' 
#' @details DHS codes: 0=no, 1=yes
create_electricity <- function(elec_values) {
  recode_binary(elec_values, yes_values = 1, no_values = 0)
}


#' Create outdoor cooking indicator
#' 
#' @param cook_loc_values Vector of cooking location codes
#' @param outdoor_codes Codes indicating outdoor cooking
#' @param indoor_codes Codes indicating indoor/separate building
#' @return Integer vector: 1 = outdoor, 0 = indoor/separate
#' 
#' @details
#' DHS hv241 codes: 1=in the house, 2=in a separate building, 3=outdoors
#' 
#' NOTE: The definition of "outdoor" differs between women and children pipelines:
#'   - Women: outdoor_codes=2 (separate building counts as ventilated)
#'   - Children: outdoor_codes=3 (only true outdoors)
#' This is configured in config.R VAR_MAP_WOMEN/VAR_MAP_CHILDREN.
create_outsidecook <- function(cook_loc_values, outdoor_codes, indoor_codes) {
  recode_binary(cook_loc_values, yes_values = outdoor_codes, no_values = indoor_codes)
}


#' Create indoor smoking indicator
#' 
#' @param smoke_values Vector of smoking frequency codes
#' @param frequent_codes Codes indicating frequent smoking (daily/weekly/monthly)
#' @param infrequent_codes Codes indicating never/rarely
#' @return Integer vector: 1 = frequent indoor smoking, 0 = never/rarely
#' 
#' @details
#' DHS hv252 codes for frequency of smoking in the home:
#'   0 = never
#'   1 = daily
#'   2 = weekly
#'   3 = monthly
#'   4 = less than once a month
#' 
#' METHODOLOGICAL NOTE (Issue #7):
#' Code 4 ("less than monthly") is grouped with "never" (code 0), not with
#' frequent smoking. This decision treats very occasional smoking as negligible
#' for cumulative indoor air pollution exposure. If ANY smoking exposure is
#' relevant to your analysis, consider changing infrequent_codes to c(0) only.
create_smoking <- function(smoke_values, 
                           frequent_codes = c(1, 2, 3), 
                           infrequent_codes = c(0, 4)) {
  recode_binary(smoke_values, yes_values = frequent_codes, no_values = infrequent_codes)
}


#' Create household head sex indicator
#' 
#' @param sex_values Vector of sex codes (1=male, 2=female typically)
#' @return Integer vector: 1 = male head, 0 = female head
#' 
#' @details DHS codes: 1=male, 2=female
create_male_head <- function(sex_values) {
  recode_binary(sex_values, yes_values = 1, no_values = 2)
}


#' Create urban indicator
#' 
#' @param urban_values Vector of urban/rural codes (1=urban, 2=rural typically)
#' @return Integer vector: 1 = urban, 0 = rural
#' 
#' @details 
#' DHS codes: 1=urban, 2=rural
#' NOTE: This is a cluster-level variable - all individuals in the same
#' cluster have the same value.
create_urban <- function(urban_values) {
  recode_binary(urban_values, yes_values = 1, no_values = 2)
}


#' Create male indicator for children
#' 
#' @param gender_values Vector of gender codes (1=male, 2=female typically)
#' @return Integer vector: 1 = male, 0 = female
#' 
#' @details DHS codes: 1=male, 2=female
create_male <- function(gender_values) {
  recode_binary(gender_values, yes_values = 1, no_values = 2)
}


#' Create anemia indicator for women
#' 
#' @param anemia_values Vector of anemia level codes
#' @param anemic_codes Codes indicating any anemia (mild, moderate, severe)
#' @param not_anemic_code Code for not anemic
#' @return Integer vector: 1 = anemic, 0 = not anemic
#' 
#' @details
#' DHS v457 anemia level codes:
#'   1 = Severe
#'   2 = Moderate
#'   3 = Mild
#'   4 = Not anemic
#' Values are based on altitude-adjusted hemoglobin levels.
create_anemia <- function(anemia_values, 
                          anemic_codes = c(1, 2, 3), 
                          not_anemic_code = 4) {
  recode_binary(anemia_values, yes_values = anemic_codes, no_values = not_anemic_code)
}


#' Create anemia indicator for children (restricted to 6-59 months)
#' 
#' @param anemia_values Vector of anemia level codes
#' @param age_months Vector of child ages in months
#' @param min_months Minimum age for anemia measurement (default 6)
#' @param max_months Maximum age for anemia measurement (default 59)
#' @param anemic_codes Codes indicating any anemia
#' @param not_anemic_code Code for not anemic
#' @return Integer vector: 1 = anemic, 0 = not anemic, NA if outside age range
#' 
#' @details
#' DHS hc57 anemia level codes (same as v457):
#'   1 = Severe
#'   2 = Moderate
#'   3 = Mild
#'   4 = Not anemic
#' 
#' NOTE: Hemoglobin testing is only done for children 6-59 months.
#' Children outside this age range are set to NA.
create_child_anemia <- function(anemia_values, 
                                age_months,
                                min_months,
                                max_months,
                                anemic_codes = c(1, 2, 3),
                                not_anemic_code = 4) {
  case_when(
    age_months >= min_months & age_months <= max_months & anemia_values %in% anemic_codes ~ 1L,
    age_months >= min_months & age_months <= max_months & anemia_values == not_anemic_code ~ 0L,
    TRUE ~ NA_integer_
  )
}


#' Create pregnancy termination indicator
#' 
#' @param pregterm_values Vector of pregnancy termination codes (0=no, 1=yes)
#' @return Integer vector: 1 = ever had termination, 0 = never
#' 
#' @details DHS v228: pregnancy ever terminated (0=no, 1=yes)
create_pregterm <- function(pregterm_values) {
  recode_binary(pregterm_values, yes_values = 1, no_values = 0)
}


#' Create hypertension/blood pressure indicator
#' 
#' @param bp_values Vector of blood pressure codes (0=no, 1=yes)
#' @return Integer vector: 1 = has hypertension, 0 = no hypertension
#' 
#' @details
#' NOTE: Blood pressure variables are country-specific and may not be available
#' in all surveys. Check your survey's questionnaire for the specific variable.
#' Zambia 2018 uses s1110a.
create_hypertension <- function(bp_values) {
  recode_binary(bp_values, yes_values = 1, no_values = 0)
}


#' Create cough indicator
#' 
#' @param cough_values Vector of cough codes
#' @param yes_codes Codes indicating cough (default 1,2)
#' @param no_code Code for no cough (default 0)
#' @return Integer vector: 1 = had cough, 0 = no cough
#' 
#' @details
#' DHS h31 codes for cough in last 2 weeks:
#'   0 = no
#'   1 = yes, seen provider
#'   2 = yes, not seen provider
#'   8 = don't know
create_cough <- function(cough_values, yes_codes = c(1, 2), no_code = 0) {
  recode_binary(cough_values, yes_values = yes_codes, no_values = no_code)
}


#' Create low birth weight indicator
#' 
#' @param bw_values Vector of birth weights in grams
#' @param bw_flag Vector indicating source of weight data
#' @param threshold Weight threshold in grams (default 2500)
#' @param valid_flag_codes Codes indicating valid weight source (default 1 = card only)
#' @return Integer vector: 1 = low birth weight, 0 = normal, NA if invalid source
#' 
#' @details
#' DHS m19a flag codes for source of birth weight:
#'   1 = from written card
#'   2 = from mother's recall
#' 
#' METHODOLOGICAL NOTE (Issue #6):
#' By default, only card-based weights (flag=1) are included. Recall-based
#' weights (flag=2) are excluded because maternal recall is less reliable.
#' 
#' To include recall weights, change valid_flag_codes to c(1, 2):
#'   create_low_birthweight(bw, flag, valid_flag_codes = c(1, 2))
#' 
#' This decision may undercount low birth weight prevalence if card-based
#' weights are systematically different from recall-based weights.
create_low_birthweight <- function(bw_values, 
                                   bw_flag, 
                                   threshold,
                                   valid_flag_codes = 1) {
  case_when(
    bw_flag %in% valid_flag_codes & bw_values < threshold ~ 1L,
    bw_flag %in% valid_flag_codes & bw_values >= threshold ~ 0L,
    TRUE ~ NA_integer_
  )
}

#' Create age group categorical variable
#' 
#' @param age_values Vector of ages (in months for children, years for women)
#' @param breaks Vector of break points for age groups (left-closed intervals)
#' @param labels Vector of labels for age groups (must be length(breaks)-1)
#' @param right Logical: if TRUE, intervals are right-closed; if FALSE (default), left-closed.
#'   Default FALSE matches DHS reporting convention.
#' @return Factor vector with age group labels
#' 
#' @details
#' Uses cut() with right=FALSE to create left-closed intervals [a, b).
#' 
#' CHILDREN (default breaks, ages in months):
#'   <6: [0, 6)
#'   6-11: [6, 12)
#'   12-23: [12, 24)
#'   24-35: [24, 36)
#'   36-47: [36, 48)
#'   48-59: [48, 60)
#' 
#' WOMEN (for use with women dataset, ages in years):
#'   15-19: [15, 20)
#'   20-24: [20, 25)
#'   25-29: [25, 30)
#'   30-34: [30, 35)
#'   35-39: [35, 40)
#'   40-44: [40, 45)
#'   45-49: [45, 50)
#' 
#' To use for women, call with:
#'   create_age_group(age_years, breaks = c(15, 20, 25, 30, 35, 40, 45, 50),
#'                    labels = c("15-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49"))
#' 
#' To override defaults for sensitivity or robustness checks, pass custom breaks/labels.
create_age_group <- function(age_values,
                             breaks = c(0, 6, 12, 24, 36, 48, 60),
                             labels = c("<6", "6-11", "12-23", "24-35", "36-47", "48-59"),
                             right = FALSE) {
  
  # Validate lengths match
  if (length(breaks) - 1 != length(labels)) {
    stop("Length of labels must be length(breaks) - 1. Got ",
         length(labels), " labels for ", length(breaks) - 1, " intervals.")
  }
  
  cut(age_values, breaks = breaks, labels = labels, right = right, include.lowest = FALSE)
}


# ============================================================================
# SCHEMA-BASED VARIABLE CREATION
# ============================================================================

#' Apply a schema to create all variables for a population
#'
#' Loops over schema entries and dispatches on type field:
#'   - recode: calls recode_binary with yes/no values from schema
#'   - age_group: calls create_age_group with breaks/labels from schema
#'   - factor: calls haven::as_factor then relevel with reference
#'   - scale: multiplies source column by scale_factor
#'   - passthrough: rename only (source_col → derived_name)
#'
#' @param data Dataframe with raw DHS variables
#' @param schema Schema list (WOMEN_SCHEMA or CHILDREN_SCHEMA)
#' @return Dataframe with all schema-derived variables added
#'
#' @details
#' This function replaces the manual mutate() lists in create_women_variables()
#' and create_children_variables(). It handles all standard variable types
#' except "complex" cases like anemic (children) and low_birthweight which
#' need custom logic and stay outside the schema.
#'
#' The function adds new columns but does NOT drop original DHS columns.
#' After apply_schema() returns, the caller should append any additional
#' custom mutations (e.g., anemic, low_birthweight) and then select()
#' to keep only the final variables needed.
apply_schema <- function(data, schema) {
  
  result <- data
  
  for (entry in schema) {
    derived_name <- entry$derived_name
    source_col   <- entry$source_col
    var_type     <- entry$type %||% "passthrough"
    
    # Skip if source column doesn't exist
    if (!(source_col %in% names(result))) {
      warning(paste("Source column", source_col, "not found in data for", derived_name))
      next
    }
    
    # Dispatch on type
    if (var_type == "recode") {
      result[[derived_name]] <- recode_binary(
        result[[source_col]],
        yes_values = entry$yes_values,
        no_values  = entry$no_values
      )
    }
    
    else if (var_type == "age_group") {
      result[[derived_name]] <- create_age_group(
        result[[source_col]],
        breaks = entry$breaks,
        labels = entry$labels
      )
    }
    
    else if (var_type == "factor") {
      result[[derived_name]] <- haven::as_factor(result[[source_col]])
      if (!is.null(entry$ref_category)) {
        result[[derived_name]] <- relevel(result[[derived_name]], ref = entry$ref_category)
      }
    }
    
    else if (var_type == "scale") {
      result[[derived_name]] <- result[[source_col]] * entry$scale_factor
    }
    
    else if (var_type == "passthrough") {
      result[[derived_name]] <- result[[source_col]]
    }
    
    else {
      warning(paste("Unknown schema type:", var_type, "for", derived_name))
    }
  }
  
  result
}


# Null-coalescing operator for optional fields in schema entries
`%||%` <- function(x, y) if (is.null(x)) y else x


#' Extract derived variable names from a schema by role
#'
#' @param schema  WOMEN_SCHEMA or CHILDREN_SCHEMA
#' @param role    "predictor", "outcome", or "stratifier"
#' @return Character vector of derived_name values matching that role
get_names <- function(schema, role) {
  matches <- Filter(function(e) e$role == role, schema)
  sapply(matches, function(e) e$derived_name)
}
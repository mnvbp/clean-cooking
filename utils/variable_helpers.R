# ============================================================================
# utils/variable_helpers.R - Variable Creation Functions
# ============================================================================
#
# These functions provide config-driven variable creation to:
# 1. Eliminate duplication between women/children variable creation
# 2. Make the code adaptable to different DHS phases/countries
# 3. Centralize recoding logic for consistency
#
# ============================================================================
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
# ============================================================================

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


#' Create poorest quintile indicator (vs middle)
#' 
#' @param wealth_values Vector of wealth quintile codes (1-5)
#' @param poor_code Code for poorest quintile (default 1)
#' @param reference_code Code for reference category (default 3 = middle)
#' @return Integer vector: 1 = poorest, 0 = middle, NA = other quintiles
#' 
#' @details
#' DHS hv270 wealth index quintiles:
#'   1 = poorest
#'   2 = poorer
#'   3 = middle
#'   4 = richer
#'   5 = richest
#' 
#' METHODOLOGICAL NOTE (Issue #17):
#' This function creates a DICHOTOMOUS variable comparing only poorest vs middle.
#' Quintiles 2 (poorer), 4 (richer), and 5 (richest) are set to NA and will be
#' EXCLUDED from regressions using this variable. This results in ~60% of
#' observations being dropped for this predictor.
#' 
#' If you need to analyze all wealth levels, either:
#'   - Use the raw 'wealth' variable (hv270) as a factor in regressions
#'   - Create different contrasts (e.g., poorest vs richest, or below/above median)
create_poorest <- function(wealth_values, poor_code = 1, reference_code = 3) {
  recode_binary(wealth_values, yes_values = poor_code, no_values = reference_code)
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
                                min_months = ANEMIA_AGE_MIN_MONTHS,
                                max_months = ANEMIA_AGE_MAX_MONTHS,
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
                                   threshold = LOW_BIRTH_WEIGHT_THRESHOLD,
                                   valid_flag_codes = 1) {
  case_when(
    bw_flag %in% valid_flag_codes & bw_values < threshold ~ 1L,
    bw_flag %in% valid_flag_codes & bw_values >= threshold ~ 0L,
    TRUE ~ NA_integer_
  )
}


# ============================================================================
# MASTER FUNCTION: Create all variables using config mappings
# ============================================================================

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
        age_months = !!sym(var_map$age_months_var)
      ),
      cough = create_cough(!!sym(var_map$cough_var)),
      low_birthweight = create_low_birthweight(
        bw_values = !!sym(var_map$bw_var),
        bw_flag = !!sym(var_map$bw_flag_var)
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

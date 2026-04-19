# CONFIG.R - Survey Configuration -- Zambia 2018
#
# Edit this file to change survey, country, variables, or file paths.
# All other scripts read from this configuration — nothing else needs
# to be changed when adapting to a new survey.
#
# STRUCTURE:
#   1.  Survey identification
#   2.  File paths
#   3.  Analysis flags
#   4.  Constants (must come before schemas — schemas reference these)
#   5.  Survey design variables
#   6.  Schemas
#   7.  Model specifications
#   8.  Populations
#   9.  Collinearity & sensitivity
#   10. Univariable analysis
#   11. Forest plot configuration


# =============================================================================
# 1. SURVEY IDENTIFICATION
# =============================================================================

SURVEY_NAME  <- "Zambia DHS 2018"
COUNTRY_CODE <- "ZM"
SURVEY_YEAR  <- 2018
DHS_PHASE    <- 7
AUTHOR       <- "Manav Parikh"


# =============================================================================
# 2. FILE PATHS
# =============================================================================

BASE_DIR   <- here::here("Zambia-2018", "data")
OUTPUT_DIR <- here::here("Zambia-2018", "outputs")

DATA_FILES <- list(
  pr = "ZMPR71FL.DTA",
  ir = "ZMIR71FL.DTA",
  kr = "ZMKR71FL.DTA"
)


# =============================================================================
# 3. ANALYSIS FLAGS
# =============================================================================

RUN_REGRESSIONS  <- TRUE
RUN_CROSSTABS    <- TRUE
RUN_CORRELATIONS <- FALSE
RUN_UNIVARIABLE  <- FALSE
RUN_SENSITIVITY  <- FALSE
RUN_FOREST_PLOTS <- TRUE

SURVEY_LONELY_PSU <- "adjust"

USE_CACHE <- FALSE
N_CORES   <- NULL


# =============================================================================
# 4. CONSTANTS
# =============================================================================
# Must be defined before schemas — schema entries reference these directly.

# Fuel classification (WHO)
# Clean: electricity, LPG, natural gas, biogas, solar
# Dirty: kerosene, coal, charcoal, wood, straw, crop, dung
# Excluded: 95=no food cooked, 96=other, 97=not de jure resident
CLEAN_FUELS <- c(1, 2, 3, 4, 12)
DIRTY_FUELS <- c(5, 6, 7, 8, 9, 10, 11)

# Reference categories for factor variables in regression models.
# Change here to update all models simultaneously.
# Age group references follow largest-cell convention (most common in DHS literature).
WEALTH_REFERENCE       <- "richest"
AGE_GROUP_REF_CHILDREN <- "12-23"   # Largest cell for children 6-59 months
AGE_GROUP_REF_WOMEN    <- "25-29"   # Modal age group for women 15-49

# Outcome thresholds
ANEMIA_AGE_MIN_MONTHS      <- 6
ANEMIA_AGE_MAX_MONTHS      <- 59
LOW_BIRTH_WEIGHT_THRESHOLD <- 2500


# =============================================================================
# 5. SURVEY DESIGN VARIABLES
# =============================================================================
# Only survey design variables remain here — all analysis variables have
# moved to the schemas in section 6.
# get_names() helper lives in utils/variable_helpers.R.

VAR_MAP_WOMEN <- list(
  weight_var  = "v005",
  cluster_var = "v021",
  strata_var  = "v023"
)

VAR_MAP_CHILDREN <- list(
  weight_var  = "hv005",
  cluster_var = "hv021",
  strata_var  = "hv023"
)


# =============================================================================
# 6. SCHEMAS
# =============================================================================
# Each entry declares one derived variable with its source column, role,
# and creation parameters. Variable creation, predictor lists, outcome lists,
# and stratifier lists are all derived from these schemas at runtime by
# apply_schema() and get_names() in utils/variable_helpers.R.
#
# Fields:
#   derived_name  name the variable will have in the dataframe
#   source_col    raw DHS column it comes from
#   role          "predictor", "outcome", or "stratifier"
#   type          "recode", "scale", "age_group", "factor", "passthrough"
#
# Type-specific fields:
#   recode      yes_values, no_values
#   scale       scale_factor
#   age_group   breaks, labels, ref
#   factor      ref_category
#   passthrough (no additional fields)
#
# Variables outside the schema:
#   anemic (children)  — two-column logic, handled explicitly in
#                        create_children_variables() after apply_schema()
#   low_birthweight    — two-column logic, handled explicitly in
#                        create_children_variables() after apply_schema()
#   survey design      — weight_var, cluster_var, strata_var in VAR_MAP_*


# -----------------------------------------------------------------------------
# WOMEN_SCHEMA
# -----------------------------------------------------------------------------

WOMEN_SCHEMA <- list(
  
  # --- Outcomes ---
  
  list(
    derived_name = "anemic",
    source_col   = "v457",
    role         = "outcome",
    type         = "recode",
    yes_values   = c(1, 2, 3),   # severe, moderate, mild
    no_values    = 4
  ),
  list(
    derived_name = "pregterm",
    source_col   = "v228",
    role         = "outcome",
    type         = "recode",
    yes_values   = 1,
    no_values    = 0
  ),
  list(
    derived_name = "hypertension",
    source_col   = "s1110a",     # Country-specific — verify for each survey
    role         = "outcome",    # Zambia 2024 uses chd02
    type         = "recode",
    yes_values   = 1,
    no_values    = 0
  ),
  
  # --- Predictors ---
  
  list(
    derived_name = "dirtyfuel",
    source_col   = "hv226",
    role         = "predictor",
    type         = "recode",
    yes_values   = DIRTY_FUELS,
    no_values    = CLEAN_FUELS
  ),
  list(
    derived_name = "elec",
    source_col   = "v119",
    role         = "predictor",
    type         = "recode",
    yes_values   = 1,
    no_values    = 0
  ),
  list(
    derived_name  = "outsidecook",
    source_col    = "hv241",
    role          = "predictor",
    type          = "recode",
    yes_values    = 3,        
    no_values     = c(1, 2)   # hv241: 1=in house, 2=separate building, 3=outdoors
  ),
  list(
    derived_name = "smoking_frequent",
    source_col   = "hv252",
    role         = "predictor",
    type         = "recode",
    yes_values   = c(1, 2, 3),   # daily, weekly, monthly
    no_values    = c(0, 4)       # never, less than monthly — see variable_helpers.R
  ),
  list(
    derived_name = "wealth_factor",
    source_col   = "hv270",
    role         = "predictor",
    type         = "factor",
    ref_category = WEALTH_REFERENCE
  ),
  list(
    derived_name = "male_head",
    source_col   = "v151",
    role         = "predictor",
    type         = "recode",
    yes_values   = 1,
    no_values    = 2
  ),
  list(
    derived_name = "urban",
    source_col   = "v025",
    role         = "predictor",
    type         = "recode",
    yes_values   = 1,
    no_values    = 2
  ),
  list(
    derived_name = "age",
    source_col   = "v012",
    role         = "predictor",
    type         = "passthrough"   # continuous age in years, no transform needed
  ),
  list(
    derived_name = "age_group",
    source_col   = "v012",
    role         = "predictor",
    type         = "age_group",
    breaks       = c(15, 20, 25, 30, 35, 40, 45, 50),
    labels       = c("15-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49"),
    ref          = AGE_GROUP_REF_WOMEN
  ),
  
  # --- Stratifiers ---
  
  list(
    derived_name = "region",
    source_col   = "v024",
    role         = "stratifier",
    type         = "passthrough"
  ),
  list(
    derived_name = "wealth",
    source_col   = "hv270",
    role         = "stratifier",
    type         = "passthrough"
  )
)


# -----------------------------------------------------------------------------
# CHILDREN_SCHEMA
# -----------------------------------------------------------------------------
# anemic and low_birthweight are NOT in this schema — they require two source
# columns each and are handled explicitly in create_children_variables().

CHILDREN_SCHEMA <- list(
  
  # --- Outcomes ---
  
  list(
    derived_name = "cough",
    source_col   = "h31",
    role         = "outcome",
    type         = "recode",
    yes_values   = c(1, 2),   # yes seen provider, yes not seen provider
    no_values    = 0
  ),
  # anemic:          see create_children_variables() — age-gated two-column recode
  # low_birthweight: see create_children_variables() — flag-gated two-column recode
  
  # --- Predictors ---
  
  list(
    derived_name = "dirtyfuel",
    source_col   = "hv226",
    role         = "predictor",
    type         = "recode",
    yes_values   = DIRTY_FUELS,
    no_values    = CLEAN_FUELS
  ),
  list(
    derived_name = "elec",
    source_col   = "hv206",
    role         = "predictor",
    type         = "recode",
    yes_values   = 1,
    no_values    = 0
  ),
  list(
    derived_name  = "outsidecook",
    source_col    = "hv241",
    role          = "predictor",
    type          = "recode",
    yes_values    = 3,         # Children: only true outdoors counts as outdoor
    no_values     = c(1, 2)   # hv241: 1=in house, 2=separate building, 3=outdoors
  ),
  list(
    derived_name = "smoking_frequent",
    source_col   = "hv252",
    role         = "predictor",
    type         = "recode",
    yes_values   = c(1, 2, 3),
    no_values    = c(0, 4)
  ),
  list(
    derived_name = "wealth_factor",
    source_col   = "hv270",
    role         = "predictor",
    type         = "factor",
    ref_category = WEALTH_REFERENCE
  ),
  list(
    derived_name = "male_head",
    source_col   = "hv219",
    role         = "predictor",
    type         = "recode",
    yes_values   = 1,
    no_values    = 2
  ),
  list(
    derived_name = "urban",
    source_col   = "hv025",
    role         = "predictor",
    type         = "recode",
    yes_values   = 1,
    no_values    = 2
  ),
  list(
    derived_name = "age",
    source_col   = "b19",
    role         = "predictor",
    type         = "scale",
    scale_factor = 1/12   # convert months to years
  ),
  list(
    derived_name = "age_group",
    source_col   = "b19",
    role         = "predictor",
    type         = "age_group",
    breaks       = c(0, 6, 12, 24, 36, 48, 60),
    labels       = c("<6", "6-11", "12-23", "24-35", "36-47", "48-59"),
    ref          = AGE_GROUP_REF_CHILDREN
  ),
  list(
    derived_name = "male",
    source_col   = "hv104",
    role         = "predictor",
    type         = "recode",
    yes_values   = 1,
    no_values    = 2
  ),
  
  # --- Stratifiers ---
  
  list(
    derived_name = "region",
    source_col   = "hv024",
    role         = "stratifier",
    type         = "passthrough"
  ),
  list(
    derived_name = "wealth",
    source_col   = "hv270",
    role         = "stratifier",
    type         = "passthrough"
  )
)


# =============================================================================
# 7. MODEL SPECIFICATIONS
# =============================================================================
# Each outcome declares its own predictor list. This replaces the shared
# PREDICTORS_* pattern which applied identical predictors to every outcome
# regardless of methodological appropriateness.
#
# Age variable convention:
#   - "age"       continuous age (years) — default for most outcomes
#   - "age_group" categorical age bands  — comment in/out as needed
#   Only one should be active per outcome — including both causes collinearity.
#
# To switch an outcome to categorical age:
#   comment out "age" and uncomment "age_group"


# -----------------------------------------------------------------------------
# MODELS_WOMEN
# -----------------------------------------------------------------------------

MODELS_WOMEN <- list(
  anemic = list(
    label           = "Anemia (women)",
    weight_override = NULL,
    predictors      = c(
      "dirtyfuel",
      "elec",
      "outsidecook",
      "smoking_frequent",
      "wealth_factor",
      "male_head",
      "urban",
      "age"
      # "age_group"
    )
  ),
  pregterm = list(
    label           = "Pregnancy terminated",
    weight_override = NULL,
    predictors      = c(
      "dirtyfuel",
      "elec",
      "outsidecook",
      "smoking_frequent",
      "wealth_factor",
      "male_head",
      "urban",
      "age"
      # "age_group"
    )
  ),
  hypertension = list(
    label           = "Hypertension",
    weight_override = NULL,
    predictors      = c(
      "dirtyfuel",
      "elec",
      "outsidecook",
      "smoking_frequent",
      "wealth_factor",
      "male_head",
      "urban",
      "age"
      # "age_group"
    )
  )
)


# -----------------------------------------------------------------------------
# MODELS_CHILDREN
# -----------------------------------------------------------------------------

MODELS_CHILDREN <- list(
  anemic = list(
    label           = "Anemia (children 6-59mo)",
    weight_override = NULL,
    predictors      = c(
      "dirtyfuel",
      "elec",
      "outsidecook",
      "smoking_frequent",
      "wealth_factor",
      "male_head",
      "urban",
      "male",
      "age"
      # "age_group"
    )
  ),
  cough = list(
    label           = "Cough (past 2 weeks)",
    weight_override = NULL,
    predictors      = c(
      "dirtyfuel",
      "elec",
      "outsidecook",
      "smoking_frequent",
      "wealth_factor",
      "male_head",
      "urban",
      "male",
      "age"
      # "age_group"
    )
  ),
  low_birthweight = list(
    label           = "Low birth weight (<2500g)",
    weight_override = NULL,
    predictors      = c(
      "dirtyfuel",
      "elec",
      "outsidecook",
      "smoking_frequent",
      "wealth_factor",
      "male_head",
      "urban",
      "male"
      # age excluded: child age at interview is post-natal and cannot
      # causally influence birth weight. Including it would introduce bias.
    )
  )
)


# =============================================================================
# 8. POPULATIONS
# =============================================================================
# Defines all analysis populations. Modules loop over this automatically.
# data is wired in 04_create_variables.R after variable creation.
#
# To add a population:
#   1. Add an entry here
#   2. Add VAR_MAP_*, *_SCHEMA, and MODELS_* above
#   3. Add variable creation logic in utils/variable_helpers.R and
#      04_create_variables.R

POPULATIONS <- list(
  women = list(
    label   = "Women",
    data    = NULL,        # wired in 04_create_variables.R
    schema  = WOMEN_SCHEMA,
    models  = MODELS_WOMEN,
    var_map = VAR_MAP_WOMEN
  ),
  children = list(
    label   = "Children",
    data    = NULL,        # wired in 04_create_variables.R
    schema  = CHILDREN_SCHEMA,
    models  = MODELS_CHILDREN,
    var_map = VAR_MAP_CHILDREN
  )
)


# =============================================================================
# 9. COLLINEARITY & SENSITIVITY
# =============================================================================

COLLINEARITY_THRESHOLD_R <- 0.5

# Manual sensitivity runs. Leave as list() to rely entirely on auto-generated
# collinearity runs. See README for format.
SENSITIVITY_ANALYSES <- list()


# =============================================================================
# 10. UNIVARIABLE ANALYSIS
# =============================================================================
# IAP predictors for unadjusted single-variable regressions.
# Derived at runtime as intersect(model predictors, IAP_PREDICTORS).

IAP_PREDICTORS <- c(
  "dirtyfuel",
  "elec",
  "outsidecook",
  "smoking_frequent"
)

# Fuel distribution table
RUN_FUEL_DISTRIBUTION    <- TRUE
FUEL_DISTRIBUTION_STRATA <- c("region", "urban", "wealth")
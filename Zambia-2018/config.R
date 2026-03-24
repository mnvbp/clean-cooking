# ============================================================================
# CONFIG.R - Survey Configuration -- Zambia 2018
# ============================================================================
#
# Edit this file to change survey, country, variables, or file paths.
# All other scripts read from this configuration — nothing else needs
# to be changed when adapting to a new survey.
#
# TO ADD A NEW ANALYSIS TYPE:
#   1. Create modules/<n>_module.R following the existing module pattern
#   2. Source it in 00_main.R
#   3. Add it to MODULES in 05_analysis.R
#   4. Add a RUN_* flag here if needed
#
# ============================================================================


# ============================================================================
# 1. SURVEY IDENTIFICATION
# ============================================================================

SURVEY_NAME  <- "Zambia DHS 2018"
COUNTRY_CODE <- "ZM"
SURVEY_YEAR  <- 2018
DHS_PHASE    <- 7
AUTHOR       <- "Manav Parikh"


# ============================================================================
# 2. FILE PATHS
# ============================================================================
# Always run the pipeline by sourcing 00_main.R — paths are relative to
# the project root set by setwd() in that script.

# Raw data folder — place your DTA files here
BASE_DIR   <- here::here("Zambia-2018", "data")

# Results are written here (created automatically if missing)
OUTPUT_DIR <- here::here("Zambia-2018", "outputs")

# DTA filenames inside BASE_DIR
DATA_FILES <- list(
  pr = "ZMPR71FL.DTA",
  ir = "ZMIR71FL.DTA",
  kr = "ZMKR71FL.DTA"
)

# Optional additional files (uncomment to enable)
# DATA_FILES$hr <- "ZMHR71FL.DTA"
# DATA_FILES$br <- "ZMBR71FL.DTA"
# DATA_FILES$mr <- "ZMMR71FL.DTA"


# ============================================================================
# 3. ANALYSIS FLAGS
# ============================================================================
# Toggle analyses on/off. RUN_CORRELATIONS should remain TRUE when using
# RUN_SENSITIVITY — sensitivity runs are auto-derived from collinearity results.

RUN_REGRESSIONS  <- TRUE
RUN_CROSSTABS    <- TRUE
RUN_CORRELATIONS <- TRUE   # Must be TRUE for auto-sensitivity to work
RUN_UNIVARIABLE  <- TRUE
RUN_SENSITIVITY  <- TRUE
RUN_FOREST_PLOTS <- TRUE
# Survey design options
SURVEY_LONELY_PSU <- "adjust"  # Options: "adjust", "certainty", "remove"

# ----------------------------------------------------------------------------
# PERFORMANCE
# ----------------------------------------------------------------------------
# USE_CACHE: if TRUE and outputs/results.rds exists, skip analysis entirely
#   and load cached results. Set FALSE to force a fresh run.
# N_CORES: number of parallel workers for regression. NULL = all cores minus one.
#   Reduce if you want to keep cores free for other work e.g. N_CORES <- 4

USE_CACHE <- FALSE
N_CORES   <- NULL


# ============================================================================
# 4. OUTCOMES
# ============================================================================
#
# Each outcome requires a label. weight_override is optional — omit or set
# to NULL to use the population default from VAR_MAP_*.
#
# To add an outcome: add an entry here, then add variable creation logic
# in utils/variable_helpers.R and 04_create_variables.R.

OUTCOMES_WOMEN <- list(
  anemic = list(
    label           = "Anemia (women)",
    weight_override = NULL          # Uses default v005
  ),
  pregterm = list(
    label           = "Pregnancy terminated",
    weight_override = NULL
  ),
  hypertension = list(
    label           = "Hypertension",
    weight_override = NULL          # Country-specific variable — see VAR_MAP_WOMEN$bp_var
  )
)

OUTCOMES_CHILDREN <- list(
  anemic = list(
    label           = "Anemia (children 6-59mo)",
    weight_override = NULL          # Set to "hv028" if using biomarker subsample weight
  ),
  cough = list(
    label           = "Cough (past 2 weeks)",
    weight_override = NULL
  ),
  low_birthweight = list(
    label           = "Low birth weight (<2500g)",
    weight_override = NULL
  )
)


# ============================================================================
# 5. PREDICTORS & STRATIFIERS
# ============================================================================
#
# To add a predictor: add the name here and add variable creation logic
# in utils/variable_helpers.R and 04_create_variables.R.
# Collinearity and sensitivity analyses update automatically.

PREDICTORS_WOMEN <- c(
  "dirtyfuel",         # Primary exposure: unclean fuel use
  "elec",              # Electricity access
  "outsidecook",       # Outdoor cooking location
  "smoking_frequent",  # Indoor smoking frequency
  "wealth_factor",     # Wealth quintile (categorical, ref = WEALTH_REFERENCE)
  "male_head",         # Sex of household head (1=male, 0=female)
  "urban",             # Urban/rural — cluster-level variable
  "age"                # Age in years
)

PREDICTORS_CHILDREN <- c(
  "dirtyfuel",
  "elec",
  "outsidecook",
  "smoking_frequent",
  "wealth_factor",
  "male_head",
  "urban",
  "age",
  "male"               # Child sex (1=male, 0=female)
)

# Stratification variables for crosstabulations
# Labels applied automatically from embedded DHS labels via haven::as_factor()
STRATIFIERS_WOMEN <- c(
  "region",
  "urban",
  "wealth"
)

STRATIFIERS_CHILDREN <- c(
  "region",
  "male",
  "urban",
  "wealth"
)

# Wealth quintile reference category
WEALTH_REFERENCE <- "richest"


# ============================================================================
# 6. POPULATIONS
# ============================================================================
# Defines all analysis populations. Each entry references the data object
# created in 04_create_variables.R and the config objects defined above.
# All modules loop over POPULATIONS automatically — adding a new population
# (e.g. men) only requires adding an entry here and creating the data object
# in 04_create_variables.R.
#
# To add a population:
#   1. Add an entry here
#   2. Add VAR_MAP_*, OUTCOMES_*, PREDICTORS_*, STRATIFIERS_* above
#   3. Add variable creation logic in utils/variable_helpers.R and
#      04_create_variables.R

POPULATIONS <- list(
  women = list(
    label       = "Women",
    data        = "women_data",        # object name created in 04_create_variables.R
    outcomes    = "OUTCOMES_WOMEN",
    predictors  = "PREDICTORS_WOMEN",
    var_map     = "VAR_MAP_WOMEN",
    stratifiers = "STRATIFIERS_WOMEN"
  ),
  children = list(
    label       = "Children",
    data        = "children_data",
    outcomes    = "OUTCOMES_CHILDREN",
    predictors  = "PREDICTORS_CHILDREN",
    var_map     = "VAR_MAP_CHILDREN",
    stratifiers = "STRATIFIERS_CHILDREN"
  )
)


# ============================================================================
# 7. VARIABLE MAPPINGS
# ============================================================================
# Maps source DHS variable names to their roles in the analysis.
# Update these when adapting to a new survey, country, or DHS phase.
# Used by utils/variable_helpers.R to create all derived variables.

VAR_MAP_WOMEN <- list(
  # Survey design
  weight_var   = "v005",
  cluster_var  = "v021",
  strata_var   = "v023",
  
  # Outcomes
  anemia_var   = "v457",
  pregterm_var = "v228",
  bp_var       = "s1110a",   # Country-specific — verify for each survey
  
  # Predictors
  fuel_var     = "hv226",    # v161 (women) and hv226 (children) identically coded
  elec_var     = "v119",
  cook_loc_var = "hv241",
  smoke_var    = "hv252",
  wealth_var   = "hv270",
  hh_sex_var   = "v151",
  urban_var    = "v025",
  age_var      = "v012",
  region_var   = "v024",
  
  # Cooking location codes (hv241: 1=in house, 2=separate building, 3=outdoors)
  # Women: separate building (2) treated as indoor (ventilated)
  outdoor_codes = 3,
  indoor_codes  = c(1, 2)
)

VAR_MAP_CHILDREN <- list(
  # Survey design
  weight_var     = "hv005",
  cluster_var    = "hv021",
  strata_var     = "hv023",
  
  # Outcomes
  anemia_var     = "hc57",
  age_months_var = "b19",    # DHS-7 recommendation over hc1 — see variable_helpers.R
  cough_var      = "h31",
  bw_var         = "m19",
  bw_flag_var    = "m19a",
  
  # Predictors
  fuel_var     = "hv226",
  elec_var     = "hv206",
  cook_loc_var = "hv241",
  smoke_var    = "hv252",
  wealth_var   = "hv270",
  hh_sex_var   = "hv219",
  urban_var    = "hv025",
  gender_var   = "hv104",
  region_var   = "hv024",
  
  # Cooking location codes
  # Children: only true outdoors (3) counts as outdoor
  outdoor_codes = 3,
  indoor_codes  = c(1, 2)
)


# ============================================================================
# 7. FUEL DEFINITIONS (WHO Classification)
# ============================================================================

# Clean fuels: electricity, LPG, natural gas, biogas, solar
CLEAN_FUELS <- c(1, 2, 3, 4, 12)

# Dirty/polluting fuels: kerosene, coal, charcoal, wood, straw, crop, dung
DIRTY_FUELS <- c(5, 6, 7, 8, 9, 10, 11)

# Excluded codes: 95 = no food cooked, 96 = other, 97 = not de jure resident

# Stratifiers for the fuel distribution table
RUN_FUEL_DISTRIBUTION    <- TRUE
FUEL_DISTRIBUTION_STRATA <- c("region", "urban", "wealth")


# ============================================================================
# 8. COLLINEARITY & SENSITIVITY
# ============================================================================
# Auto sensitivity runs are generated from collinearity results when
# RUN_SENSITIVITY = TRUE. Any predictor pair with |r| >= THRESHOLD_R
# triggers a run dropping each variable in the pair individually.

COLLINEARITY_THRESHOLD_R   <- 0.5   # Pairwise correlation threshold
COLLINEARITY_THRESHOLD_VIF <- 5.0   # VIF threshold (for future VIF checks)

# Manual sensitivity runs — add here for non-collinearity-driven runs.
# Use population keys matching POPULATIONS above. Each entry needs a label
# and a predictors entry per population key e.g.:
#
#   rural_only = list(
#     label      = "Rural households only",
#     predictors = list(
#       women    = PREDICTORS_WOMEN[PREDICTORS_WOMEN != "urban"],
#       children = PREDICTORS_CHILDREN[PREDICTORS_CHILDREN != "urban"]
#     )
#   )
#
# Leave as list() to rely entirely on auto-generated collinearity runs.
SENSITIVITY_ANALYSES <- list()


# ============================================================================
# 9. UNIVARIABLE ANALYSIS
# ============================================================================
# IAP predictors for unadjusted single-variable regressions.
# Active list derived as intersect(PREDICTORS_*, IAP_PREDICTORS) at runtime
# so this never goes stale when predictors are added or removed above.

IAP_PREDICTORS <- c(
  "dirtyfuel",
  "elec",
  "outsidecook",
  "smoking_frequent"
)


# ============================================================================
# 10. MERGE & FILTER CONFIGURATION
# ============================================================================
# Rarely needs editing — only change when adapting to a new DHS phase
# that uses different merge keys or filter variables.

MERGE_CHILDREN <- list(
  kr_select_vars = c("v001", "v002", "b16", "b19", "h31", "m19", "m19a"),
  kr_filter_expr = "b16 > 0 & !is.na(b16)",
  join_by        = c("hv001" = "v001", "hv002" = "v002", "hvidx" = "b16"),
  join_type      = "left"
)

MERGE_WOMEN <- list(
  join_by   = c("v001", "v002", "v003"),
  join_type = "inner"
)

# De facto population recommended for biomarker-based indicators.
# See Guide to DHS Statistics, Section 1.37.
CHILDREN_FILTER <- list(
  de_facto = list(
    var               = "hv103",
    val               = 1,
    filter_after_join = FALSE
  ),
  age = list(
    var               = "b19",
    max               = 60,          # < 60 months (under 5 years)
    filter_after_join = TRUE         # b19 comes from KR, available only after join
  )
)

WOMEN_FILTER <- list(
  de_facto = list(
    var               = "hv103",
    val               = 1,
    filter_after_join = FALSE
  )
)

# Anemia age restriction (months)
ANEMIA_AGE_MIN_MONTHS <- 6
ANEMIA_AGE_MAX_MONTHS <- 59

# Low birth weight threshold (grams)
LOW_BIRTH_WEIGHT_THRESHOLD <- 2500

# ============================================================================
# 11. FOREST PLOT CONFIGURATION
# ============================================================================
# Controls visual appearance and output dimensions for forest plots.
# All entries are optional — omit any to use the built-in default.
#
# x_min / x_max: manual x-axis limits (OR scale). Leave NULL for auto.
#   Example: x_min = 0.2, x_max = 5.0
#
# sig_color:  color for significant (p < 0.05) points and CIs
# null_color: color for non-significant points and CIs
# ref_color:  color of the vertical reference line at OR = 1
#
# png_width:  output width in inches (default 8)
# png_height: output height in inches — NULL = auto-sized by row count
# png_dpi:    resolution (default 180 for screen-quality; use 300 for print)

FOREST_PLOT_CONFIG <- list(
  x_min       = NULL,        # NULL = auto
  x_max       = NULL,        # NULL = auto
  point_size  = 3,
  line_size   = 0.5,
  base_size   = 11,
  sig_color   = "#1D9E75",   # c-teal 400 — significant associations
  null_color  = "#888780",   # c-gray 400 — non-significant
  ref_color   = "#B4B2A9",   # c-gray 200 — reference line at OR=1
  png_width   = 8,
  png_height  = NULL,        # NULL = auto (0.35in per term + 1.5in header)
  png_dpi     = 180
)

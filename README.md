# DHS Clean Cooking Analysis Pipeline

Config-driven R pipeline for DHS survey analysis. Currently supports Zambia 2018 (Phase 7) and Zambia 2024 (Phase 8).

---

## Repository Structure

```
clean-cooking/
├── clean-cooking.Rproj
├── run_all_surveys.R
│
├── pipeline/
│   ├── 00_main.R             ← Entry point — source this to run one survey
│   ├── 01_setup.R
│   ├── 02_load_data.R
│   ├── 03_merge_data.R
│   ├── 04_create_variables.R
│   ├── 05_analysis.R
│   └── 06_export.R
│
├── modules/
│   ├── collinearity_module.R
│   ├── regression_module.R
│   ├── crosstab_module.R
│   ├── univariable_module.R
│   └── sensitivity_module.R
│
├── utils/
│   ├── variable_helpers.R
│   ├── regression_helpers.R
│   ├── crosstab_helpers.R
│   ├── collinearity_helpers.R
│   ├── export_helpers.R
│   └── sample_tracking_helpers.R
│
├── Zambia-2018/
│   ├── config.R
│   └── data/                 ← ZMPR71FL.DTA, ZMIR71FL.DTA, ZMKR71FL.DTA
│
└── Zambia-2024/
    ├── config.R
    └── data/                 ← ZMPR81FL.DTA, ZMIR81FL.DTA, ZMKR81FL.DTA
```

---

## How to Run

**Prerequisites:** R >= 4.1, RStudio, DHS `.DTA` files in the correct `data/` folder.

```r
# Single survey
CONFIG_PATH <- "Zambia-2018/config.R"
source("pipeline/00_main.R")

# All surveys
source("run_all_surveys.R")
```

Open `clean-cooking.Rproj` first — this sets the working directory correctly.

---

## Configuration

Everything survey-specific lives in `config.R`. The pipeline scripts never need to change between surveys.

### Analysis flags

```r
RUN_REGRESSIONS  <- TRUE
RUN_CROSSTABS    <- TRUE
RUN_CORRELATIONS <- TRUE   # required if RUN_SENSITIVITY = TRUE
RUN_UNIVARIABLE  <- TRUE
RUN_SENSITIVITY  <- TRUE
```

### Outcomes

```r
OUTCOMES_WOMEN <- list(
  anemic = list(label = "Anemia (women)", weight_override = NULL),
  ...
)
```

To add an outcome: add an entry here, then add recoding logic in `utils/variable_helpers.R` and `pipeline/04_create_variables.R`.

### Predictors

```r
PREDICTORS_WOMEN <- c("dirtyfuel", "elec", "outsidecook", ...)
```

To add a predictor: add the name here, then add recoding logic in `variable_helpers.R`. Collinearity and sensitivity analyses pick it up automatically.

### Variable mappings (Section 7)

The main thing to update when adapting to a new survey. Maps DHS variable names to their roles:

```r
VAR_MAP_WOMEN <- list(
  weight_var = "v005",
  anemia_var = "v457",
  bp_var     = "s1110a",   # country-specific — verify for each survey
  ...
)
```

### Sensitivity analyses (Section 8)

Auto runs are generated when any predictor pair hits `|r| >= COLLINEARITY_THRESHOLD_R` (default 0.5). Manual runs go here:

```r
SENSITIVITY_ANALYSES <- list(
  rural_only = list(
    label      = "Rural households only",
    predictors = list(
      women    = PREDICTORS_WOMEN[PREDICTORS_WOMEN != "urban"],
      children = PREDICTORS_CHILDREN[PREDICTORS_CHILDREN != "urban"]
    )
  )
)
```

---

## Adding a New Survey

1. Copy an existing survey folder: `cp -r Zambia-2018 Kenya-2022`
2. Place `.DTA` files in `Kenya-2022/data/`
3. Edit `config.R` — minimum changes:

| Section | What to update |
|---------|----------------|
| 1 | `SURVEY_NAME`, `COUNTRY_CODE`, `SURVEY_YEAR`, `DHS_PHASE` |
| 2 | `BASE_DIR`, `OUTPUT_DIR`, `DATA_FILES` |
| 7 | `bp_var` and any other non-standard variable names |

4. Register in `run_all_surveys.R`:

```r
list(name = "Kenya 2022", config = "Kenya-2022/config.R", enabled = TRUE)
```

5. **Verify `bp_var`** — the hypertension variable is not standardized across surveys:
   - Zambia 2018 (Phase 7): `s1110a`
   - Zambia 2024 (Phase 8): `chd02`
   - Other surveys: check the questionnaire

---

## Outputs

Written to `OUTPUT_DIR` from `config.R`.

| File | Contents |
|------|----------|
| `crosstabs.xlsx` | Weighted + unweighted counts/percentages with DHS suppression flags |
| `regressions.xlsx` | ORs with 95% CI; weighted (svyglm) stacked above unweighted (glm) |
| `diagnostics.xlsx` | Collinearity matrices, sensitivity runs, univariable regressions |
| `results.rds` | Full `output_tables` list for re-export without re-running |

**DHS suppression rules** (based on unweighted N):

| N | Flag |
|---|------|
| < 25 | `*` suppress |
| 25–49 | `(n)` use with caution |
| ≥ 50 | none |

**Re-export without re-running:**

```r
output_tables <- readRDS("Zambia-2018/outputs/results.rds")
source("utils/export_helpers.R")
export_results(output_tables, "Zambia-2018/outputs")
```

---

## Methodological Decisions

### Smoking (`smoking_frequent`)
`hv252` codes: 0=never, 1=daily, 2=weekly, 3=monthly, 4=less than monthly. Codes 1–3 = frequent; codes 0 and 4 = never/rarely. Code 4 is grouped with never because occasional smoking (<1x/month) has negligible cumulative indoor air pollution effect.

### Low birth weight (`low_birthweight`)
Only card-based weights (`m19a = 1`) are used. Recall weights (`m19a = 2`) are excluded for data quality. To include recall: set `valid_flag_codes = c(1, 2)` in `create_low_birthweight()`.

### Outdoor cooking (`outsidecook`)
`hv241`: 1=in house, 2=separate building, 3=outdoors. Both women and children use `outdoor_codes = 3` only — separate building is treated as ventilated/indoor.

### Wealth quintile (`wealth_factor`)
5-level factor, `richest` as reference (`WEALTH_REFERENCE`). Collinearity correlations treat wealth as ordinal 1–5.

### De facto filter
Only de facto residents (`hv103 = 1`) are included. See DHS Guide to Statistics §1.37.

### Child age variable
`b19` (age in months at time of survey, from KR) is used over `hc1`, per DHS Phase 7/8 recommendation.
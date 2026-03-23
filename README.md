# DHS Clean Cooking Analysis Pipeline

A config-driven R pipeline for analyzing social and economic determinants of health
outcomes in DHS surveys. Built to support multi-country, multi-survey comparisons
with minimal code changes between surveys.

**Current surveys:** Zambia 2018 (DHS Phase 7), Zambia 2024 (DHS Phase 8)

---

## Table of Contents

1. [Repository Structure](#repository-structure)
2. [How to Run](#how-to-run)
3. [Pipeline Overview](#pipeline-overview)
4. [Configuration Guide](#configuration-guide)
5. [Adding a New Survey or Country](#adding-a-new-survey-or-country)
6. [Outputs](#outputs)
7. [Methodological Decisions](#methodological-decisions)
8. [Key Design Principles](#key-design-principles)

---

## Repository Structure

```
clean-cooking/
├── clean-cooking.Rproj       ← Always open this first in RStudio
├── run_all_surveys.R         ← Multi-survey runner (run all configs in sequence)
│
├── pipeline/                 ← Execution scripts — run in order by 00_main.R
│   ├── 00_main.R             ← Entry point — source this to run one survey
│   ├── 01_setup.R            ← Package loading, parallel setup, output dir
│   ├── 02_load_data.R        ← Read PR, IR, KR .DTA files from BASE_DIR
│   ├── 03_merge_data.R       ← Merge PR+KR (children) and PR+IR (women)
│   ├── 04_create_variables.R ← Derive all analysis variables via variable_helpers.R
│   ├── 05_analysis.R         ← Run all enabled modules, collect output_tables
│   └── 06_export.R           ← Write Excel files + results.rds to OUTPUT_DIR
│
├── modules/                  ← Analysis modules — each is a self-contained list
│   ├── collinearity_module.R ← Pairwise correlations (runs first — feeds sensitivity)
│   ├── regression_module.R   ← Weighted + unweighted logistic regression
│   ├── crosstab_module.R     ← Weighted + unweighted crosstabulations
│   ├── univariable_module.R  ← Unadjusted single-predictor regressions (IAP only)
│   └── sensitivity_module.R  ← Auto (collinearity-driven) + manual sensitivity runs
│
├── utils/                    ← Helper functions — sourced by 00_main.R
│   ├── variable_helpers.R    ← All variable creation/recoding functions
│   ├── regression_helpers.R  ← svyglm setup, parallel regression runner
│   ├── crosstab_helpers.R    ← DHS suppression flags, weighted crosstabs
│   ├── collinearity_helpers.R← Correlation matrix + collinear pair flagging
│   ├── export_helpers.R      ← Routes tables to crosstabs/regressions/diagnostics.xlsx
│   └── sample_tracking_helpers.R ← Pipeline log (N at each filter/merge step)
│
├── Zambia-2018/
│   ├── config.R              ← Survey-specific settings (DHS Phase 7)
│   └── data/                 ← Place .DTA files here (not committed to git)
│       ├── ZMPR71FL.DTA
│       ├── ZMIR71FL.DTA
│       └── ZMKR71FL.DTA
│
└── Zambia-2024/
    ├── config.R              ← Survey-specific settings (DHS Phase 8)
    └── data/                 ← Place .DTA files here (not committed to git)
        ├── ZMPR81FL.DTA
        ├── ZMIR81FL.DTA
        └── ZMKR81FL.DTA
```

---

## How to Run

### Prerequisites

- R >= 4.1
- RStudio (recommended)
- DHS `.DTA` files placed in the correct `data/` folder for each survey
- Internet access on first run (to install packages via `pacman`)

### Run a single survey

```r
# 1. Open clean-cooking.Rproj in RStudio (sets working directory automatically)
# 2. In the console:
CONFIG_PATH <- "Zambia-2018/config.R"
source("pipeline/00_main.R")
```

### Run all surveys in sequence

```r
source("run_all_surveys.R")
```

This loops through every enabled survey in `run_all_surveys.R`, runs the full
pipeline for each, and prints a summary table of pass/fail + runtime at the end.
Failed surveys do not stop the runner (controlled by `STOP_ON_ERROR`).

### Check your working directory

```r
getwd()  # Should be the repo root: .../clean-cooking
```

If it's wrong, either open the `.Rproj` file or run `setwd("path/to/clean-cooking")`.

---

## Pipeline Overview

`00_main.R` sources each step in order. Every step reads from config globals
set by `config.R` — nothing is hardcoded in the pipeline scripts themselves.

```
00_main.R
  │
  ├── source(CONFIG_PATH)          # Load all config globals
  ├── source("utils/*.R")          # Load all helper functions
  ├── source("modules/*.R")        # Register all analysis modules
  │
  ├── 01_setup.R    ── Install/load packages, set parallel plan, create OUTPUT_DIR
  ├── 02_load_data.R ─ Read PR, IR, KR .DTA files → pr_data, ir_data, kr_data
  ├── 03_merge_data.R ─ Filter + join → pr_children, merged_women
  │     ├── Children: PR (de facto filter) → left join KR → age filter
  │     └── Women:    PR (de facto filter) → inner join IR
  ├── 04_create_variables.R ─ Recode → children_data, women_data
  ├── 05_analysis.R ─ Run modules → output_tables (named list of dataframes)
  │     ├── COLLINEARITY_MODULE  (always first — sensitivity reads its output)
  │     ├── REGRESSION_MODULE
  │     ├── CROSSTAB_MODULE
  │     ├── UNIVARIABLE_MODULE
  │     └── SENSITIVITY_MODULE
  └── 06_export.R ── Route output_tables → crosstabs.xlsx, regressions.xlsx,
                      diagnostics.xlsx, results.rds
```

### Survey design

All regressions use `survey::svyglm()` with `quasibinomial` family, incorporating:
- Normalized sampling weights (`hv005 / 1e6` for children, `v005 / 1e6` for women)
- Primary sampling units (PSU) via `cluster_var`
- Stratification via `strata_var`
- Lonely PSU handling: `options(survey.lonely.psu = "adjust")` (configurable)

### Parallelization

Regression outcomes are processed in parallel using `furrr::future_map()`.
- Mac/Linux: `multicore` (fork-based, zero overhead)
- Windows: `multisession`
- Workers: all cores minus one by default (`N_CORES = NULL` in config)

---

## Configuration Guide

Everything survey-specific lives in `config.R`. The pipeline scripts never need
to change between surveys. Key sections:

### Section 2 — File Paths
```r
BASE_DIR   <- "Zambia-2018/data"     # Where .DTA files live
OUTPUT_DIR <- "Zambia-2018/outputs"  # Where results are written
DATA_FILES <- list(pr = "ZMPR71FL.DTA", ir = "ZMIR71FL.DTA", kr = "ZMKR71FL.DTA")
```

### Section 3 — Analysis Flags
Toggle any analysis on/off without touching the modules:
```r
RUN_REGRESSIONS  <- TRUE
RUN_CROSSTABS    <- TRUE
RUN_CORRELATIONS <- TRUE   # Must be TRUE if RUN_SENSITIVITY = TRUE
RUN_UNIVARIABLE  <- TRUE
RUN_SENSITIVITY  <- TRUE
```

### Section 4 — Outcomes
Add a new outcome by adding an entry here, then adding recoding logic in
`utils/variable_helpers.R` and `pipeline/04_create_variables.R`:
```r
OUTCOMES_WOMEN <- list(
  anemic = list(label = "Anemia (women)", weight_override = NULL),
  ...
)
```

### Section 5 — Predictors
Add a predictor name here, then add recoding logic in `variable_helpers.R`.
Collinearity and sensitivity analyses update automatically:
```r
PREDICTORS_WOMEN <- c("dirtyfuel", "elec", "outsidecook", ...)
```

### Section 7 — Variable Mappings
Maps DHS variable names to their roles. **This is the main section to update
when adapting to a new country or DHS phase:**
```r
VAR_MAP_WOMEN <- list(
  weight_var   = "v005",
  anemia_var   = "v457",
  bp_var       = "s1110a",   # Country-specific — verify for each survey!
  ...
)
```

### Section 8 — Collinearity & Sensitivity
Auto-sensitivity runs trigger when `|r| >= COLLINEARITY_THRESHOLD_R` (default 0.5).
Add manual sensitivity runs (e.g. rural-only, excluding a variable) here:
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

## Adding a New Survey or Country

### 1. Create the survey folder

Copy an existing config as a starting point:
```
Kenya-2022/
├── config.R    ← copy from Zambia-2018/config.R and edit
└── data/       ← place .DTA files here
```

### 2. Edit config.R — minimum required changes

| Section | What to change |
|---------|---------------|
| Section 1 | `SURVEY_NAME`, `COUNTRY_CODE`, `SURVEY_YEAR`, `DHS_PHASE` |
| Section 2 | `BASE_DIR`, `OUTPUT_DIR`, `DATA_FILES` (filenames) |
| Section 7 | `VAR_MAP_WOMEN$bp_var` — hypertension variable is country-specific |
| Section 7 | Any other variable names that differ from standard DHS naming |

### 3. Register in run_all_surveys.R

```r
list(
  name    = "Kenya 2022",
  config  = "Kenya-2022/config.R",
  enabled = TRUE
)
```

### 4. Verify the hypertension variable

The BP variable (`bp_var` in `VAR_MAP_WOMEN`) is **not standardized across DHS surveys**.
Always check the survey's questionnaire before running:
- Zambia 2018 (Phase 7): `s1110a`
- Zambia 2024 (Phase 8): `chd02`
- Other countries/phases: check DHS documentation

---

## Outputs

All outputs are written to `OUTPUT_DIR` defined in `config.R`.

| File | Contents |
|------|----------|
| `crosstabs.xlsx` | One sheet per outcome × population; unweighted + weighted counts and percentages with DHS suppression flags |
| `regressions.xlsx` | One sheet per outcome × population; weighted (svyglm) stacked above unweighted (glm); ORs with 95% CI and significance stars |
| `diagnostics.xlsx` | Collinearity matrices, sensitivity run results, univariable regressions |
| `results.rds` | Full `output_tables` list — reload without re-running: `readRDS("outputs/results.rds")` |

### DHS suppression rules (applied in crosstabs)

| Unweighted N | Flag | Meaning |
|-------------|------|---------|
| < 25 | `*` | Suppress — too few cases |
| 25–49 | `(n)` | Use with caution |
| ≥ 50 | none | Reportable |

### Sheet naming convention (Excel)

Sheet names follow the pattern `<G><Type><N> <Outcome>` where:
- `G` = `W` (Women) or `C` (Children)
- `Type` = `R` (Regression), `X` (Crosstab), `S` (Sensitivity), `U` (Univariable), `D` (Collinearity)
- A Legend sheet in each workbook maps short sheet names to full table names

### Re-exporting without re-running

```r
output_tables <- readRDS("Zambia-2018/outputs/results.rds")
source("utils/export_helpers.R")
export_results(output_tables, "Zambia-2018/outputs")
```

---

## Methodological Decisions

These are documented in `utils/variable_helpers.R` and summarized here for
quick reference when writing methods sections.

### Smoking (`smoking_frequent`)
DHS `hv252` codes: 0=never, 1=daily, 2=weekly, 3=monthly, 4=less than monthly.
**Decision:** Codes 1–3 = frequent; codes 0 and 4 = never/rarely.
Code 4 ("less than monthly") is grouped with "never" — occasional smoking is
treated as negligible for cumulative indoor air pollution exposure.

### Low birth weight (`low_birthweight`)
**Decision:** Only card-based weights (`m19a = 1`) are used. Maternal recall
weights (`m19a = 2`) are excluded for data quality.
To include recall: change `valid_flag_codes = c(1, 2)` in `create_low_birthweight()`.

### Outdoor cooking (`outsidecook`)
**Decision:** Definition differs between populations:
- Women: `outdoor_codes = 3` only (separate building = ventilated = indoor)
- Children: `outdoor_codes = 3` only (same)
Both are configured via `VAR_MAP_*/outdoor_codes` in `config.R`.

### Wealth quintile (`wealth_factor`)
Used as a 5-level factor with `richest` as the reference category (`WEALTH_REFERENCE`).
Collinearity correlations treat wealth as ordinal 1–5.

### De facto population filter
Only de facto residents (`hv103 = 1`) are included, as recommended by the
DHS Guide to Statistics (Section 1.37) for biomarker-based indicators.

### Child age variable
`b19` (age in months at time of survey, from KR) is used instead of `hc1`,
per DHS Phase 7/8 recommendation for greater accuracy.

---

## Key Design Principles

**Config-driven, not hardcoded.** Every survey-specific value lives in `config.R`.
The pipeline scripts (`01`–`06`) and all modules/utils read from config globals
and never reference specific variable names or file paths directly.

**Modules are self-contained.** Each module is a named list with `$name`,
`$enabled()`, and `$run()`. Adding a new analysis means creating a new module
file, sourcing it in `00_main.R`, and adding it to `MODULES` in `05_analysis.R`.
Nothing else changes.

**Populations loop automatically.** All modules iterate over `POPULATIONS` from
`config.R`. Adding a new population (e.g. men) only requires adding an entry
to `POPULATIONS` and creating the data object in `04_create_variables.R`.

**Parallel by default.** Outcomes within each module run in parallel via
`furrr::future_map()`. The plan is set once in `01_setup.R` based on OS.

**Complete case analysis per outcome.** Each regression uses only observations
with non-missing values for that specific outcome and all predictors. Sample
sizes are reported per outcome in the regression output (`n`, `n_weighted`).

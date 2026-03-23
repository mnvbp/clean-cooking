# ============================================================================
# 02_LOAD_DATA.R - Load DHS Data Files
# ============================================================================

cat("Loading data files...\n")

# ----------------------------------------------------------------------------
# Load PR (Household Member Recode)
# ----------------------------------------------------------------------------

cat("  Loading PR (Household Member Recode)...\n")
pr_data <- read_dta(file.path(BASE_DIR, DATA_FILES$pr))

# Create merge keys to match with Women's Recode
pr_data <- pr_data %>%
  mutate(
    v001 = hv001,
    v002 = hv002,
    v003 = hvidx
  )

cat("    PR loaded:", format(nrow(pr_data), big.mark = ","), "records\n")
pipeline_log <- log_step(pipeline_log, "Both", "PR loaded", nrow(pr_data))

# ----------------------------------------------------------------------------
# Load IR (Women's Recode)
# ----------------------------------------------------------------------------

cat("  Loading IR (Women's Recode)...\n")
ir_data <- read_dta(file.path(BASE_DIR, DATA_FILES$ir))
cat("    IR loaded:", format(nrow(ir_data), big.mark = ","), "records\n")

# ----------------------------------------------------------------------------
# Load KR (Children's Recode)
# ----------------------------------------------------------------------------

cat("  Loading KR (Children's Recode)...\n")
kr_data <- read_dta(file.path(BASE_DIR, DATA_FILES$kr))
cat("    KR loaded:", format(nrow(kr_data), big.mark = ","), "records\n")

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------

cat("\nData loading complete.\n")
cat("  PR (Household Members):", format(nrow(pr_data), big.mark = ","), "\n")
cat("  IR (Women):            ", format(nrow(ir_data), big.mark = ","), "\n")
cat("  KR (Children):         ", format(nrow(kr_data), big.mark = ","), "\n")
cat("================================================================================\n\n")
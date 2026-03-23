# ============================================================================
# 03_MERGE_DATA.R - Merge and Combine Datasets
# ============================================================================
#
# Merges PR with KR (children) and IR (women) using config-driven logic.
# Logs N at each step to pipeline_log for sample size tracking.
#
# ============================================================================

cat("Merging datasets...\n")

# ----------------------------------------------------------------------------
# CHILDREN PIPELINE
# ----------------------------------------------------------------------------

cat("  Building children dataset...\n")

# De facto filter
pr_children <- pr_data %>%
  filter(!!sym(CHILDREN_FILTER$de_facto$var) == CHILDREN_FILTER$de_facto$val)

pipeline_log <- log_step(pipeline_log, "Children", "De facto filter",
                         nrow(pr_children),
                         variable  = CHILDREN_FILTER$de_facto$var,
                         condition = paste("==", CHILDREN_FILTER$de_facto$val))

cat("    De facto filter (", CHILDREN_FILTER$de_facto$var, "==",
    CHILDREN_FILTER$de_facto$val, "):", format(nrow(pr_children), big.mark = ","), "\n")

# Prepare KR data
kr_outcomes <- kr_data %>%
  select(all_of(MERGE_CHILDREN$kr_select_vars)) %>%
  filter(eval(parse(text = MERGE_CHILDREN$kr_filter_expr)))

pipeline_log <- log_step(pipeline_log, "Children", "KR filter",
                         nrow(kr_outcomes),
                         condition = MERGE_CHILDREN$kr_filter_expr)

cat("    KR filtered (", MERGE_CHILDREN$kr_filter_expr, "):",
    format(nrow(kr_outcomes), big.mark = ","), "\n")

# Left join PR with KR
pr_children <- pr_children %>%
  left_join(kr_outcomes, by = MERGE_CHILDREN$join_by)

pipeline_log <- log_step(pipeline_log, "Children", "Left join PR + KR",
                         nrow(pr_children),
                         variable  = paste(names(MERGE_CHILDREN$join_by), collapse = ", "),
                         condition = "left join")

cat("    After left join:", format(nrow(pr_children), big.mark = ","), "\n")

# Age filter (b19 from KR, applied after join)
pr_children <- pr_children %>%
  filter(!!sym(CHILDREN_FILTER$age$var) < CHILDREN_FILTER$age$max)

pipeline_log <- log_step(pipeline_log, "Children", "Age filter",
                         nrow(pr_children),
                         variable  = CHILDREN_FILTER$age$var,
                         condition = paste("<", CHILDREN_FILTER$age$max))

cat("    Age filter (", CHILDREN_FILTER$age$var, "<",
    CHILDREN_FILTER$age$max, "):", format(nrow(pr_children), big.mark = ","), "\n")

pipeline_log <- log_step(pipeline_log, "Children", "Final analysis sample",
                         nrow(pr_children))

# ----------------------------------------------------------------------------
# WOMEN PIPELINE
# ----------------------------------------------------------------------------

cat("  Building women dataset...\n")

# De facto filter
pr_women <- pr_data %>%
  filter(!!sym(WOMEN_FILTER$de_facto$var) == WOMEN_FILTER$de_facto$val)

pipeline_log <- log_step(pipeline_log, "Women", "De facto filter",
                         nrow(pr_women),
                         variable  = WOMEN_FILTER$de_facto$var,
                         condition = paste("==", WOMEN_FILTER$de_facto$val))

cat("    De facto filter (", WOMEN_FILTER$de_facto$var, "==",
    WOMEN_FILTER$de_facto$val, "):", format(nrow(pr_women), big.mark = ","), "\n")

# Inner join with IR
merged_women <- pr_women %>%
  inner_join(ir_data, by = MERGE_WOMEN$join_by)

pipeline_log <- log_step(pipeline_log, "Women", "Inner join PR + IR",
                         nrow(merged_women),
                         variable  = paste(MERGE_WOMEN$join_by, collapse = ", "),
                         condition = "inner join")

cat("    After inner join:", format(nrow(merged_women), big.mark = ","), "\n")

pipeline_log <- log_step(pipeline_log, "Women", "Final analysis sample",
                         nrow(merged_women))

# ----------------------------------------------------------------------------
# Cleanup
# ----------------------------------------------------------------------------

rm(kr_outcomes, pr_women)

cat("\nMerge complete.\n")
cat("  Children base:", format(nrow(pr_children), big.mark = ","), "\n")
cat("  Women base:   ", format(nrow(merged_women), big.mark = ","), "\n")
cat("================================================================================\n\n")
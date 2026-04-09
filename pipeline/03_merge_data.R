# 03_MERGE_DATA.R - Merge and Combine Datasets

cat("Merging datasets...\n")

# ----------------------------------------------------------------------------
# CHILDREN PIPELINE
# ----------------------------------------------------------------------------

cat("  Building children dataset...\n")

# De facto filter
pr_children <- pr_data %>%
  filter(hv103 == 1)

pipeline_log <- log_step(pipeline_log, "Children", "De facto filter",
                         nrow(pr_children),
                         variable  = "hv103",
                         condition = "== 1")

cat("    De facto filter (hv103 == 1):", format(nrow(pr_children), big.mark = ","), "\n")

# Prepare KR data
kr_outcomes <- kr_data %>%
  select(v001, v002, b16, b19, h31, m19, m19a) %>%
  filter(b16 >= 1, !is.na(b16))

pipeline_log <- log_step(pipeline_log, "Children", "KR filter",
                         nrow(kr_outcomes),
                         condition = "b16 >= 1 & !is.na(b16)")

cat("    KR filtered:", format(nrow(kr_outcomes), big.mark = ","), "\n")

# Left join PR with KR
pr_children <- pr_children %>%
  left_join(kr_outcomes, by = c("hv001" = "v001", "hv002" = "v002", "hvidx" = "b16"))

pipeline_log <- log_step(pipeline_log, "Children", "Left join PR + KR",
                         nrow(pr_children))

cat("    After left join:", format(nrow(pr_children), big.mark = ","), "\n")

# Age filter (b19 from KR, available after join)
pr_children <- pr_children %>%
  filter(b19 < 60)

pipeline_log <- log_step(pipeline_log, "Children", "Age filter",
                         nrow(pr_children),
                         variable  = "b19",
                         condition = "< 60")

cat("    Age filter (b19 < 60):", format(nrow(pr_children), big.mark = ","), "\n")

pipeline_log <- log_step(pipeline_log, "Children", "Final analysis sample",
                         nrow(pr_children))

# ----------------------------------------------------------------------------
# WOMEN PIPELINE
# ----------------------------------------------------------------------------

cat("  Building women dataset...\n")

# De facto filter
pr_women <- pr_data %>%
  filter(hv103 == 1)

pipeline_log <- log_step(pipeline_log, "Women", "De facto filter",
                         nrow(pr_women),
                         variable  = "hv103",
                         condition = "== 1")

cat("    De facto filter (hv103 == 1):", format(nrow(pr_women), big.mark = ","), "\n")

# Inner join with IR
merged_women <- pr_women %>%
  inner_join(ir_data, by = c("v001", "v002", "v003"))

pipeline_log <- log_step(pipeline_log, "Women", "Inner join PR + IR",
                         nrow(merged_women))

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
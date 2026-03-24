# ============================================================================
# modules/forest_plot_module.R
# ============================================================================
#
# Generates one forest plot PNG per outcome × population combination.
# Reads weighted regression results from output_tables (already computed
# by REGRESSION_MODULE). Does not re-run any regressions.
#
# Output naming: "<Group> - Forest - <outcome_label>"
# Routes to forest_plots/ subfolder via export_helpers.R
#
# Requires: ggplot2 (loaded in 01_setup.R via pacman)
#
# ============================================================================

FOREST_PLOT_MODULE <- list(
  name    = "Forest Plots",
  enabled = function() RUN_FOREST_PLOTS,
  run     = function(output_tables) {

    out <- list()

    for (pop_key in names(POPULATIONS)) {
      pop    <- POPULATIONS[[pop_key]]
      group  <- pop$label

      # Pull all weighted regression tables for this population
      reg_names <- names(output_tables)[
        grepl(paste0("^", group, " - Regressions - "), names(output_tables))
      ]

      for (tbl_name in reg_names) {
        tbl <- output_tables[[tbl_name]]

        # Keep weighted rows only, drop intercept
        wgt_rows <- tbl[tbl$section == "Weighted" & tbl$term != "(Intercept)", ]

        if (nrow(wgt_rows) == 0) next

        outcome_label <- unique(wgt_rows$outcome_label)
        if (length(outcome_label) == 0) next
        outcome_label <- outcome_label[1]

        plot_obj <- build_forest_plot(wgt_rows, group, outcome_label)

        entry_name        <- paste0(group, " - Forest - ", outcome_label)
        out[[entry_name]] <- plot_obj
      }
    }

    out
  }
)


# ============================================================================
# build_forest_plot()
# ============================================================================
# Constructs a single ggplot2 forest plot for one outcome × population.
#
# Design decisions:
#   - Terms are displayed in reverse order (top = first predictor in model)
#   - Wealth quintiles are indented under a "Wealth quintile" group label
#   - Reference line at OR = 1.0
#   - Points scaled by significance (p < 0.05 = filled, otherwise open)
#   - x-axis log-scaled; limits from FOREST_PLOT_CONFIG or auto
#   - Color: significant = c-teal hex, non-significant = c-gray hex
# ============================================================================

build_forest_plot <- function(df, group_label, outcome_label) {

  # ------------------------------------------------------------------
  # Pull config with safe defaults
  # ------------------------------------------------------------------
  cfg <- if (exists("FOREST_PLOT_CONFIG")) FOREST_PLOT_CONFIG else list()

  x_min       <- cfg$x_min       %||% NA   # NA = auto
  x_max       <- cfg$x_max       %||% NA
  point_size  <- cfg$point_size  %||% 3
  line_size   <- cfg$line_size   %||% 0.5
  base_size   <- cfg$base_size   %||% 11
  sig_color   <- cfg$sig_color   %||% "#1D9E75"   # c-teal 400
  null_color  <- cfg$null_color  %||% "#888780"   # c-gray 400
  ref_color   <- cfg$ref_color   %||% "#B4B2A9"   # c-gray 200
  strip_color <- cfg$strip_color %||% "#F1EFE8"   # c-gray 50

  # ------------------------------------------------------------------
  # Label cleaning and ordering
  # ------------------------------------------------------------------
  df$is_sig <- df$p.value < 0.05

  # Build display labels — wealth quintiles get a short prefix for grouping
  df$label <- clean_term_label(df$term)

  # Reverse so first predictor appears at top
  df$label <- factor(df$label, levels = rev(unique(df$label)))

  # Clamp CIs to plot limits to avoid infinite segments dropping rows
  if (!is.na(x_min)) df$conf.low  <- pmax(df$conf.low,  x_min * 0.5)
  if (!is.na(x_max)) df$conf.high <- pmin(df$conf.high, x_max * 2.0)

  # ------------------------------------------------------------------
  # Build x limits
  # ------------------------------------------------------------------
  all_vals   <- c(df$conf.low, df$conf.high, df$estimate)
  all_vals   <- all_vals[is.finite(all_vals) & all_vals > 0]
  auto_min   <- floor(log10(min(all_vals, na.rm = TRUE) * 0.85) * 10) / 10
  auto_max   <- ceiling(log10(max(all_vals, na.rm = TRUE) * 1.15) * 10) / 10
  x_lo       <- if (!is.na(x_min)) x_min else 10^auto_min
  x_hi       <- if (!is.na(x_max)) x_max else 10^auto_max

  # ------------------------------------------------------------------
  # ggplot construction
  # ------------------------------------------------------------------
  p <- ggplot2::ggplot(df,
      ggplot2::aes(x = estimate, y = label,
                   xmin = conf.low, xmax = conf.high,
                   color = is_sig, fill = is_sig)) +

    # Reference line
    ggplot2::geom_vline(xintercept = 1, linetype = "dashed",
                        color = ref_color, linewidth = 0.6) +

    # CI whiskers
    ggplot2::geom_errorbarh(height = 0.25, linewidth = line_size,
                            show.legend = FALSE) +

    # Point: filled if significant, open if not
    ggplot2::geom_point(
      ggplot2::aes(shape = is_sig),
      size = point_size, stroke = 0.8
    ) +

    # OR label to the right of each point
    ggplot2::geom_text(
      ggplot2::aes(
        x     = x_hi,
        label = format_or_ci(estimate, conf.low, conf.high)
      ),
      hjust  = 1, size = 2.8,
      color  = "grey40",
      family = "sans"
    ) +

    # Log scale x
    ggplot2::scale_x_log10(
      limits = c(x_lo, x_hi),
      breaks = log_breaks(x_lo, x_hi),
      labels = scales::label_number(accuracy = 0.01, drop0trailing = TRUE)
    ) +

    # Color and shape scales
    ggplot2::scale_color_manual(
      values = c("TRUE" = sig_color, "FALSE" = null_color),
      labels = c("TRUE" = "p < 0.05", "FALSE" = "p \u2265 0.05"),
      name   = NULL
    ) +
    ggplot2::scale_fill_manual(
      values = c("TRUE" = sig_color, "FALSE" = "white"),
      guide  = "none"
    ) +
    ggplot2::scale_shape_manual(
      values = c("TRUE" = 21, "FALSE" = 21),
      guide  = "none"
    ) +

    ggplot2::labs(
      title    = outcome_label,
      subtitle = paste(group_label, "\u2014 weighted logistic regression"),
      x        = "Odds ratio (log scale)",
      y        = NULL
    ) +

    ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title         = ggplot2::element_text(face = "bold", size = base_size + 1),
      plot.subtitle      = ggplot2::element_text(color = "grey50", size = base_size - 1),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor   = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(color = "grey90", linewidth = 0.3),
      axis.text.y        = ggplot2::element_text(size = base_size - 1),
      legend.position    = "bottom",
      legend.text        = ggplot2::element_text(size = base_size - 2),
      plot.margin        = ggplot2::margin(12, 80, 8, 8)
    )

  p
}


# ============================================================================
# Helper: clean predictor term labels for display
# ============================================================================
# Converts raw R term names (e.g. "wealth_factorpoorest") to readable labels.
# Wealth quintiles get "  Poorest", "  Poorer" etc. (indented) so they visually
# group under the "Wealth quintile" header term which is NOT in the model.
# Add cases here as new predictors are introduced.

clean_term_label <- function(terms) {
  label_map <- c(
    # Fuel / environment
    "dirtyfuel"                       = "Unclean fuel use",
    "elec"                            = "Electricity access",
    "outsidecook"                     = "Outdoor cooking",
    "smoking_frequent"                = "Indoor smoker (frequent)",

    # Wealth — indented
    "wealth_factorpoorest"            = "  Wealth: poorest",
    "wealth_factorpoorer"             = "  Wealth: poorer",
    "wealth_factormiddle"             = "  Wealth: middle",
    "wealth_factorricher"             = "  Wealth: richer",

    # Household
    "male_head"                       = "Male household head",
    "urban"                           = "Urban residence",
    "age"                             = "Age",

    # Child-specific
    "male"                            = "Male sex (child)"
  )

  # Apply map; fall back to a tidied version of the raw term for unmapped terms
  out <- label_map[terms]
  unmapped <- is.na(out)
  out[unmapped] <- gsub("_", " ", terms[unmapped])
  out[unmapped] <- paste0(toupper(substr(out[unmapped], 1, 1)),
                          substr(out[unmapped], 2, nchar(out[unmapped])))
  unname(out)
}


# ============================================================================
# Helper: generate sensible log-scale x-axis breaks
# ============================================================================
log_breaks <- function(lo, hi) {
  candidates <- c(0.1, 0.2, 0.25, 0.3, 0.4, 0.5, 0.6, 0.7,
                  0.8, 0.9, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0,
                  4.0, 5.0, 6.0, 8.0, 10.0)
  candidates[candidates >= lo * 0.9 & candidates <= hi * 1.1]
}


# ============================================================================
# Helper: format OR (95% CI) label string
# ============================================================================
format_or_ci <- function(est, lo, hi) {
  sprintf("%.2f (%.2f\u2013%.2f)", est, lo, hi)
}


# ============================================================================
# Null-coalescing operator (mirrors export_helpers.R)
# ============================================================================
`%||%` <- function(x, y) if (is.null(x)) y else x

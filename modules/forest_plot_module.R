# modules/forest_plot_module.R
#
# Generates one forest plot PNG per outcome × population combination.
# Reads weighted regression results from output_tables (already computed
# by REGRESSION_MODULE). Does not re-run any regressions.
#
# Output naming: "<Group> - Forest - <outcome_label>"
# Routes to forest_plots/ subfolder via export_helpers.R
#
# Requires: ggplot2 (loaded in 01_setup.R via pacman)


# CONFIGURATION
# x_min / x_max: manual OR-scale axis limits. NULL = auto.
# png_height:    NULL = auto-sized (0.35in per term + 1.5in header)
# png_dpi:       180 for screen, 300 for print

FP_X_MIN      <- NULL
FP_X_MAX      <- NULL
FP_POINT_SIZE <- 3
FP_LINE_SIZE  <- 0.5
FP_BASE_SIZE  <- 11
FP_SIG_COLOR  <- "#1D9E75"   # c-teal 400 — significant (p < 0.05)
FP_NULL_COLOR <- "#888780"   # c-gray 400 — non-significant
FP_REF_COLOR  <- "#B4B2A9"   # c-gray 200 — reference line at OR = 1
FP_PNG_WIDTH  <- 12
FP_PNG_HEIGHT <- NULL
FP_PNG_DPI    <- 180


FOREST_PLOT_MODULE <- list(
  name                = "Forest Plots",
  needs_output_tables = TRUE,
  export              = list(file = "forest_plots", type = "png"),
  enabled             = function() RUN_FOREST_PLOTS,
  run                 = function(output_tables) {
    
    out <- list()
    
    for (pop_key in names(POPULATIONS)) {
      pop   <- POPULATIONS[[pop_key]]
      group <- pop$label
      
      reg_names <- names(output_tables)[
        grepl(paste0("^", group, " - Regressions - "), names(output_tables))
      ]
      
      for (tbl_name in reg_names) {
        tbl      <- output_tables[[tbl_name]]
        wgt_rows <- tbl[tbl$section == "Weighted" & tbl$term != "(Intercept)", ]
        
        if (nrow(wgt_rows) == 0) next
        
        outcome_label <- unique(wgt_rows$outcome_label)
        if (length(outcome_label) == 0) next
        outcome_label <- outcome_label[1]
        
        entry_name        <- paste0(group, " - Forest - ", outcome_label)
        out[[entry_name]] <- build_forest_plot(wgt_rows, group, outcome_label)
      }
    }
    
    out
  }
)


build_forest_plot <- function(df, group_label, outcome_label) {
  
  df$is_sig <- df$p.value < 0.05
  df$label  <- clean_term_label(df$term)
  df$label  <- factor(df$label, levels = rev(unique(df$label)))
  
  # Clamp CIs if manual limits are set
  if (!is.null(FP_X_MIN)) df$conf.low  <- pmax(df$conf.low,  FP_X_MIN * 0.5)
  if (!is.null(FP_X_MAX)) df$conf.high <- pmin(df$conf.high, FP_X_MAX * 2.0)
  
  # Build x-axis limits
  all_vals <- c(df$conf.low, df$conf.high, df$estimate)
  all_vals <- all_vals[is.finite(all_vals) & all_vals > 0]
  x_lo <- if (!is.null(FP_X_MIN)) FP_X_MIN else
    10^(floor(log10(min(all_vals) * 0.85) * 10) / 10)
  x_hi <- if (!is.null(FP_X_MAX)) FP_X_MAX else
    10^(ceiling(log10(max(all_vals) * 1.15) * 10) / 10)
  
  ggplot2::ggplot(df,
                  ggplot2::aes(x = estimate, y = label,
                               xmin = conf.low, xmax = conf.high,
                               color = is_sig, fill = is_sig)) +
    
    ggplot2::geom_vline(xintercept = 1, linetype = "dashed",
                        color = FP_REF_COLOR, linewidth = 0.6) +
    
    ggplot2::geom_errorbarh(height = 0.25, linewidth = FP_LINE_SIZE,
                            show.legend = FALSE) +
    
    ggplot2::geom_point(ggplot2::aes(shape = is_sig),
                        size = FP_POINT_SIZE, stroke = 0.8) +
    
    ggplot2::geom_text(
      ggplot2::aes(x = x_hi, label = format_or_ci(estimate, conf.low, conf.high)),
      hjust = 1, size = 2.8, color = "grey40", family = "sans"
    ) +
    
    ggplot2::scale_x_log10(
      limits = c(x_lo, x_hi),
      breaks = log_breaks(x_lo, x_hi),
      labels = scales::label_number(accuracy = 0.01, drop0trailing = TRUE)
    ) +
    
    ggplot2::scale_color_manual(
      values = c("TRUE" = FP_SIG_COLOR, "FALSE" = FP_NULL_COLOR),
      labels = c("TRUE" = "p < 0.05",   "FALSE" = "p \u2265 0.05"),
      name   = NULL
    ) +
    ggplot2::scale_fill_manual(
      values = c("TRUE" = FP_SIG_COLOR, "FALSE" = "white"),
      guide  = "none"
    ) +
    ggplot2::scale_shape_manual(values = c("TRUE" = 21, "FALSE" = 21),
                                guide  = "none") +
    
    ggplot2::labs(
      title    = outcome_label,
      subtitle = paste(group_label, "\u2014 weighted logistic regression"),
      x        = "Odds ratio (log scale)",
      y        = NULL
    ) +
    
    ggplot2::theme_minimal(base_size = FP_BASE_SIZE) +
    ggplot2::theme(
      plot.title         = ggplot2::element_text(face = "bold",
                                                 size = FP_BASE_SIZE + 1),
      plot.subtitle      = ggplot2::element_text(color = "grey50",
                                                 size = FP_BASE_SIZE - 1),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor   = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(color = "grey90",
                                                 linewidth = 0.3),
      axis.text.y        = ggplot2::element_text(size = FP_BASE_SIZE - 1),
      legend.position    = "bottom",
      legend.text        = ggplot2::element_text(size = FP_BASE_SIZE - 2),
      plot.margin        = ggplot2::margin(12, 120, 8, 8)
    )
}


clean_term_label <- function(terms) {
  label_map <- c(
    "dirtyfuel"            = "Unclean fuel use",
    "elec"                 = "Electricity access",
    "outsidecook"          = "Outdoor cooking",
    "smoking_frequent"     = "Indoor smoker (frequent)",
    "wealth_factorpoorest" = "  Wealth: poorest",
    "wealth_factorpoorer"  = "  Wealth: poorer",
    "wealth_factormiddle"  = "  Wealth: middle",
    "wealth_factorricher"  = "  Wealth: richer",
    "male_head"            = "Male household head",
    "urban"                = "Urban residence",
    "age"                  = "Age",
    "male"                 = "Male sex (child)"
  )
  
  out      <- label_map[terms]
  unmapped <- is.na(out)
  out[unmapped] <- gsub("_", " ", terms[unmapped])
  out[unmapped] <- paste0(toupper(substr(out[unmapped], 1, 1)),
                          substr(out[unmapped], 2, nchar(out[unmapped])))
  unname(out)
}


log_breaks <- function(lo, hi) {
  candidates <- c(0.1, 0.2, 0.25, 0.3, 0.4, 0.5, 0.6, 0.7,
                  0.8, 0.9, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0,
                  4.0, 5.0, 6.0, 8.0, 10.0)
  candidates[candidates >= lo * 0.9 & candidates <= hi * 1.1]
}


format_or_ci <- function(est, lo, hi) {
  sprintf("%.2f (%.2f\u2013%.2f)", est, lo, hi)
}
plot_cashflow <- function(mcSimulation_object, cashflow_var_name, x_axis_name = "Timeline of intervention", 
                          y_axis_name = "Cashflow", legend_name = "Quantiles (%)", 
                          legend_labels = c("5 to 95", "25 to 75", "median"), color_25_75 = "grey40", 
                          color_5_95 = "grey70", color_median = "blue", facet_labels = cashflow_var_name, 
                          base_size = 11, ...) {
  
  # Ensure mcSimulation_object is of the correct class
  assertthat::assert_that(class(mcSimulation_object)[[1]] == "mcSimulation", 
                          msg = "mcSimulation_object is not class 'mcSimulation', please provide a valid object.")
  
  # Convert mcSimulation results into a data frame
  data <- data.frame(mcSimulation_object$y, mcSimulation_object$x)
  
  # Check if the provided cashflow_var_name matches any column names
  matching_vars <- grep(paste0("^", cashflow_var_name), names(data), value = TRUE)
  
  # If no matching variables are found, stop with an error
  if (length(matching_vars) == 0) {
    stop("The data for plotting is empty. Please check your input data or variable names.")
  }
  
  # Debugging: Print matching variable names
  print("Matching variables for cashflow_var_name:")
  print(matching_vars)
  
  # Filter and pivot the data for the given cashflow variable names
  subset_data <- data %>%
    dplyr::select(all_of(matching_vars)) %>%
    tidyr::pivot_longer(cols = everything(), names_to = "name", values_to = "value") %>%
    tidyr::separate(name, into = c("decision_option", "x_scale"), sep = "_", convert = TRUE)
  
  # Debugging: Print subset_data to check if it contains rows
  print("Subset data for plotting:")
  print(head(subset_data))
  
  # Check if subset_data is empty
  if (nrow(subset_data) == 0) {
    stop("The data for plotting is empty after processing. Please check your input data or variable names.")
  }
  
  # Ensure that x_scale is numeric and adjusted for months 1 to 7
  subset_data$x_scale <- as.numeric(subset_data$x_scale)
  
  # Summarize the data for plotting
  summary_subset_data <- subset_data %>%
    dplyr::group_by(decision_option, x_scale) %>%
    dplyr::summarize(
      p5 = quantile(value, 0.05, na.rm = TRUE), 
      p25 = quantile(value, 0.25, na.rm = TRUE), 
      p50 = quantile(value, 0.5, na.rm = TRUE), 
      p75 = quantile(value, 0.75, na.rm = TRUE), 
      p95 = quantile(value, 0.95, na.rm = TRUE),
      .groups = 'drop'
    )
  
  # Plot the summarized data
  ggplot2::ggplot(summary_subset_data, ggplot2::aes(x = x_scale)) + 
    ggplot2::geom_ribbon(ggplot2::aes(ymin = p5, ymax = p95, fill = legend_labels[1])) + 
    ggplot2::geom_ribbon(ggplot2::aes(ymin = p25, ymax = p75, fill = legend_labels[2])) + 
    ggplot2::geom_line(ggplot2::aes(y = p50, color = legend_labels[3])) + 
    ggplot2::geom_line(ggplot2::aes(y = 0), color = "black", linetype = "dashed") + 
    ggplot2::scale_x_continuous(breaks = 1:7, labels = month.abb[4:10], expand = c(0, 0)) + 
    ggplot2::scale_y_continuous(labels = scales::comma) + 
    ggplot2::scale_fill_manual(values = c(color_25_75, color_5_95)) + 
    ggplot2::scale_color_manual(values = color_median) + 
    ggplot2::guides(fill = ggplot2::guide_legend(reverse = TRUE, order = 1)) + 
    ggplot2::labs(x = x_axis_name, y = y_axis_name, fill = legend_name, color = "") + 
    ggplot2::facet_wrap(~factor(decision_option, levels = unique(subset_data$decision_option), labels = facet_labels)) + 
    ggplot2::theme_bw(base_size = base_size) + 
    ggplot2::theme(
      legend.margin = ggplot2::margin(-0.75, 0, 0, 0, unit = "cm"), 
      strip.background = ggplot2::element_blank(),
      ...
    )
}

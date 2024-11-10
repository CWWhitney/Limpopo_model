# Function to test different efficiency values
test_efficiency_values <- function(x, varnames, efficiency_values) {
  # Create a list to store results for different efficiencies
  efficiency_results <- list()
  
  for (eff in efficiency_values) {
    # Adjust the efficiency values in your model
    efficiency_pumps <- rep(eff, 12)
    efficiency_irrig_scheduling <- rep(eff, 12)
    
    # Ensure the efficiencies are capped between 0 and 1
    efficiency_pumps <- sapply(efficiency_pumps, function(x) min(max(x, 0), 1))
    efficiency_irrig_scheduling <- sapply(efficiency_irrig_scheduling, function(x) min(max(x, 0), 1))
    
    # Calculate the water losses
    water_losses_share <- (1 - efficiency_pumps * efficiency_irrig_scheduling)
    
    # Adjust the irrigation water need
    irrigation_water_need <- total_irrigation_need / (1 - water_losses_share)
    
    # Calculate the total yearly irrigation water need
    yearly_irrigation_water_need <- sum(irrigation_water_need)
    
    # Store the results
    efficiency_results[[paste0("Efficiency_", eff * 100, "%")]] <- list(
      efficiency = eff,
      irrigation_water_need = irrigation_water_need,
      yearly_irrigation_water_need = yearly_irrigation_water_need
    )
  }
  
  return(efficiency_results)
}


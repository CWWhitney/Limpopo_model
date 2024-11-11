# load vv function
source(file = "functions/vv.R")

limpopo_decision_function <- function(x){
  
  # generating boundary conditions for the simulation run ####
  
  # simulate how much rainwater is available in mm ####
  rainfall<-sapply(1:12,function(x) eval(parse(text=paste0("prec_",x)))) 
  # lowest in the dry season between July and November
  # Test
  # rainfall
  # reasonable for the Letaba region in terms of expected seasonal rainfall
  
  effective_rain <- sapply(rainfall,function(x) min(x,effprec_high))
  effective_rainfall <- sapply(effective_rain,function(x) max(x,effprec_low))
  
  # Compute crop water needs based on ET0 ####
  # ET0 is the baseline evapotranspiration, based on the Hargreaves Samani equation, as implemented in the Evapotranspiration package). Input temperature data comes from the NASAPOWER dataset (accessed through the nasapower package). The scenario data are based on scenarios that represent conditions during real years in the past. 
  ET0 <- sapply(1:12,function(x) eval(parse(text=paste0("ET0_",x)))) # in mm / month
  # To get from ET0 to crop water use, we need to multiply ET0 with a crop coefficient (kc), which is estimated for each month.
  # According to the FAO Irrigation and Drainage Paper 56, reference ET0 values for arid and semi-arid regions are often closer to 80–150 mm/month during peak months
  
  # # The crop coefficient (kc) ranges 
  # Maize: 0.4 to 1.2, depending on the growth stage.
  # Legumes: 0.4 to 1.0, depending on the crop type and growth stage.
  # Vegetables: 0.6 to 1.2, depending on the crop and stage.
  kc <- sapply(1:12,function(x) eval(parse(text=paste0("kc_",x)))) # in mm
  # According to FAO Irrigation and Drainage Paper No. 56 by Allen et al. (1998), crop coefficients in the initial stage are typically low, ranging between 0.2 and 0.4, as the crop has limited leaf area and the evapotranspiration is primarily soil evaporation.
  
  # resulting 12 months of crop water needs 
  # crop water need per hectare, in millimeters
  cropwat_need <- ET0*kc # in mm / ha / month
  # Test 
  sum(cropwat_need*10) # (m3 /ha / year)
  # around 5,000 m³/ha/year, generally within the range reported in the literature
  # for drought-tolerant crops grown in arid and semi-arid regions. Millet and
  # Sorghum: These crops are highly drought-tolerant, with annual water needs
  # ranging from 3,000 to 6,000 m³/ha. Maize (Drought-Tolerant Varieties): Water
  # requirements can vary significantly based on the variety and growing
  # conditions but typically range from 4,000 to 8,000 m³/ha. Legumes (e.g.,
  # cowpea, pigeon pea): Generally require 2,500 to 5,000 m³/ha/year. The FAO
  # Irrigation and Drainage Paper No. 56 mentions that annual water requirements
  # for common drought-tolerant crops in arid regions, such as millet, sorghum, or
  # chickpeas, typically range between 3,000 and 6,000 m³/ha/year,
  
  
  # Compute irrigation water needs ####
  irrigation_need <- cropwat_need - effective_rainfall # in mm / ha / mont
  
  # Define river flow for each month #### Base river flow data from 1920 to 2010,
  # Letaba River at EWR site EWR4 (Letaba Ranch upstream Little Letaba confluence)
  pre_livestock_river_flow <- sapply(1:12,function(x) eval(parse(text=paste0("river_flow_",x)))) # in m3 / month
  
  # Define e-flow for each month ####
  eflow <- sapply(1:12,function(x) eval(parse(text=paste0("eflow_",x)))) # in m3 / month
  
  # Calculating the water needed for watering livestock m3 / month ####
  # assuming that this is more or less stable throughout the year, but varies a bit
  livestock_water_needs <- vv(livestock_water_need,var_CV,12) # m3 / month
  # assuming that the eflows aren't affecting ability to water livestock 
  # and that there's always enough water for all the livestock
  river_flow <- pre_livestock_river_flow-livestock_water_needs
  
  # Calculating the farmed area ####
  # Total farmed area in ha in the region and number of farm households
  demand_for_farm_area <- n_subsistence_farmers*necessary_farm_size_per_household
  # ha of farmed area either all that is available or just what is demanded (if that is less) minus the expected portion of that land that is not available for sociopolitical reasons
  # Total irrigable Letaba River smallholder irrigation area
  farmed_area <- min(available_area, demand_for_farm_area)*(1-unused_sociopolit)
  # the farmed_area value matches realistic values for the Letaba River’s smallholder irrigation area. 
  
  # Calculating the total annual crop water need m3/ha ####
  # farmed_area = available farm area in Prieska, Ga-Selwana, and Mahale (ha)
  total_cropwater_need <- (cropwat_need*10)*farmed_area # total water need in m3 (the 10 is the mm to m3/ha conversion)
  total_effective_rainfall <- (effective_rainfall*10)*farmed_area # total effective rainfall per year
  
  # total_irrigation_need calculation (in m³/ha)
  # Calculating the total annual irrigation need m3/ha ####
  total_irrigation_need <- total_cropwater_need-total_effective_rainfall # in m3/ha per year
  # sum(total_irrigation_need/farmed_area) is around 8600 m3/ha, very close to the
  # reported values across the literature in Limpopo - reasonable by compared to
  # known benchmarks for irrigation requirements in similar climates and cropping
  # systems.
  
  # Calculating the annual water losses in m3/ha #### from the efficiency of the
  # pumps and in the water allocation Efficiency of pumps (efficiency_pumps) and
  # efficiency of irrigation scheduling (efficiency_irrig_scheduling) are adjusted
  # to ensure they remain between 0 and 1,
  efficiency_pumps <- vv(effi_pump,var_CV,12)
  efficiency_irrig_scheduling <- vv(effi_sched,var_CV,12)
  efficiency_pumps <- sapply(efficiency_pumps, function(x)  min(x,1))
  efficiency_pumps <- sapply(efficiency_pumps, function(x)  max(x,0))
  efficiency_irrig_scheduling <- sapply(efficiency_irrig_scheduling, function(x)  min(x,1))
  efficiency_irrig_scheduling <- sapply(efficiency_irrig_scheduling, function(x)  max(x,0))
  
  # # Test source(file = "functions/test_efficiency_values.R") # Define a range of
  # efficiency values to test (e.g., 50%, 70%, 90%) efficiency_values <- c(0.5,
  # 0.7, 0.9) # Run the function and observe the results efficiency_test_results
  # <- test_efficiency_values( x = mcSimulation_results$x, varnames =
  # colnames(mcSimulation_results$x), efficiency_values = efficiency_values)
  # efficiency_values # At 50% efficiency, the yearly irrigation water need is
  # 4,830,093 m³. # At 70% efficiency, it reduces to 2,464,333 m³. # At 90%
  # efficiency, it further drops to 1,490,770 m³.
  
  # water_losses_share represents the share of water lost due to inefficiencies,
  # calculated as  1 − ( efficiency_pumps × efficiency_irrig_scheduling )
  # 1−(efficiency_pumps×efficiency_irrig_scheduling). This results in higher
  # irrigation water needs to compensate for these losses around 50% efficiency
  water_losses_share <- (1-efficiency_pumps*efficiency_irrig_scheduling)
  #Adjusted Irrigation Water Need: irrigation_water_need is calculated by dividing
  #total_irrigation_need by the remaining efficient share (1 − water_losses_share)
  #(1−water_losses_share), effectively increasing the water required due to
  #inefficiencies.
  irrigation_water_need <- total_irrigation_need/(1-water_losses_share) # m3/ha 
  # irrigation inefficiency doubles the irrigation need
  # sum(irrigation_water_need-total_irrigation_need)/farmed_area is around 6,886
  
  # Scenario 1 - UNRES unrestricted baseline with no eflows #### No restrictions
  # at all for water extraction. Little or no effective measures are taken to
  # ensure that e-flows are maintained at times when the present flow is below the
  # e-flow requirement.
  scen1_usable_river_flow <- sapply(1:12,function(x) max(0,river_flow[x]-minimum_flow_to_operate_pumps))
  
  # Scenario 2 - EFLOW abstraction control #### with eflows as a limit to
  # extraction only. E-flows are to be ensured whenever there is more water in the
  # river than the e-flow requirement would mandate, i.e. farmers aren't allowed
  # to extract water beyond the e-flow requirement.
  scen2_usable_river_flow <- sapply(1:12,function(x) max(0,river_flow[x]-max(eflow[x],minimum_flow_to_operate_pumps)))
  
  # Scenario 3 - SUPPL dam releases #### e-flows are assured by dam releases,
  # whenever the present flow is below the e-flow requirement, water is released
  # from an upstream dam to ensure that the e-flows are met.
  adj_river_flow <- sapply(1:12, function(x)
    max(river_flow[x], eflow[x]))
  
  scen3_usable_river_flow <-
    sapply(1:12, function(x)
      max(0, adj_river_flow[x] - minimum_flow_to_operate_pumps))
  
  # Calculate monthly how much water is released from an upstream dam to ensure
  # that the e-flows are met
  required_dam_release <- adj_river_flow - river_flow
  
  # Calculate how much water gets extracted from the river
  scen1_extracted_river_water <-
    sapply(1:12, function(x)
      min(scen1_usable_river_flow[x], irrigation_water_need[x]))
  scen2_extracted_river_water <-
    sapply(1:12, function(x)
      min(scen2_usable_river_flow[x], irrigation_water_need[x]))
  scen3_extracted_river_water <-
    sapply(1:12, function(x)
      min(scen3_usable_river_flow[x], irrigation_water_need[x]))
  
  # calculate damage to crop production due to lack of irrigation water
  scen1_water_shortfall <-
    sapply(1:12, function (x)
      max(0, irrigation_water_need[x] - scen1_extracted_river_water[x]))
  scen2_water_shortfall <-
    sapply(1:12, function (x)
      max(0, irrigation_water_need[x] - scen2_extracted_river_water[x])) 
  scen3_water_shortfall <-
    sapply(1:12, function (x)
      max(0, irrigation_water_need[x] - scen3_extracted_river_water[x]))
  
  scen1_irrigation_shortfall <- scen1_water_shortfall*(1-water_losses_share)
  scen2_irrigation_shortfall <- scen2_water_shortfall*(1-water_losses_share)
  scen3_irrigation_shortfall <- scen3_water_shortfall*(1-water_losses_share)
  
  scen1_crop_water_gap <- scen1_irrigation_shortfall/(cropwat_need*farmed_area*10)
  scen2_crop_water_gap <- scen2_irrigation_shortfall/(cropwat_need*farmed_area*10)
  scen3_crop_water_gap <- scen3_irrigation_shortfall/(cropwat_need*farmed_area*10)
  
  # calculate how much water is left after farmers extracted water
  scen1_river_flow_downstream <- river_flow-scen1_extracted_river_water
  scen2_river_flow_downstream <- river_flow-scen2_extracted_river_water
  scen3_river_flow_downstream <- adj_river_flow-scen3_extracted_river_water
  
  # calculate outputs and differences 
  
  return(list(cropwater_need=total_cropwater_need,
              yearly_crop_water_need=sum(total_cropwater_need),
              irrigation_water_need=irrigation_water_need,
              yearly_irrigation_water_need=sum(irrigation_water_need),
              scen1_downstream_river_flow=mean(scen1_river_flow_downstream),
              scen2_downstream_river_flow=mean(scen2_river_flow_downstream),
              scen3_downstream_river_flow=mean(scen3_river_flow_downstream),
              scen3_dam_release=required_dam_release,
              scen3_total_dam_release=sum(required_dam_release),
              Downstream_river_flow_1_=scen1_river_flow_downstream,
              Downstream_difference_2_vs_1=scen2_river_flow_downstream-scen1_river_flow_downstream,
              Downstream_difference_3_vs_1=scen3_river_flow_downstream-scen1_river_flow_downstream,
              scen1_crop_water_gap=mean(scen1_crop_water_gap),
              scen2_crop_water_gap=mean(scen2_crop_water_gap),
              scen3_crop_water_gap=mean(scen3_crop_water_gap),
              Crop_water_gap_scen1_=scen1_crop_water_gap,
              Crop_water_gap_difference_2_vs_1=scen2_crop_water_gap-scen1_crop_water_gap,
              Crop_water_gap_difference_3_vs_1=scen3_crop_water_gap-scen1_crop_water_gap,
              Mean_Crop_water_gap_difference_2_vs_1=mean(scen2_crop_water_gap-scen1_crop_water_gap),
              Mean_Crop_water_gap_difference_3_vs_1=mean(scen3_crop_water_gap-scen1_crop_water_gap)))
  
}

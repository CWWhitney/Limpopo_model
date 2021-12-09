
limpopo_decision_function <- function(x, varnames){
  
  
  # generating boundary conditions for the simulation run 
  
  # how much rainwater is available
  # for now we used data from some random climate diagram on the internet
  rainfall<-sapply(1:12,function(x) eval(parse(text=paste0("prec_",x))))
  
  effective_rainfall<-sapply(rainfall,function(x) min(x,effprec_high))
  effective_rainfall<-sapply(effective_rainfall,function(x) max(x,effprec_low))
  
  
  # We compute crop water needs based on ET0 (computed based on the Hargreaves
  # Samani equation, as implemented in the Evapotranspiration package). Input
  # temperature data comes from the NASAPOWER dataset (accessed through the 
  # nasapower package)
  # The data will be based on scenarios that represent conditions during real
  # years in the past
  # To get from ET0 to crop water use, we need to multiply ET0 with a crop
  # coefficient (kc), which is estimated for each month
  
  ET0<-sapply(1:12,function(x) eval(parse(text=paste0("ET0_",x)))) # in mm
  
  kc<-sapply(1:12,function(x) eval(parse(text=paste0("kc_",x)))) # in mm
  
  cropwat_need<-ET0*kc # in mm
  
  irrigation_need<-cropwat_need-effective_rainfall # in mm
  
  
  # define river flow and eflow for each month ####
  # Base river flow data from 1920 to 2010, Letaba River at EWR site EWR4 (Letaba Ranch upstream Little Letaba confluence)
  pre_livestock_river_flow<-sapply(1:12,function(x) eval(parse(text=paste0("river_flow_",x)))) # in m3 / month
  eflow<-sapply(1:12,function(x) eval(parse(text=paste0("eflow_",x)))) # in m3 / month
  
  # watering livestock
  # assuming that this is more or less stable throughout the year, but varies a bit
  livestock_water_needs<-vv(livestock_water_need,var_CV,12)
  
  # assuming that the eflows aren't affecting ability to water livestock and that there's always enough
  # water for all the livestock
  river_flow<-pre_livestock_river_flow-livestock_water_needs
  
  # calculating the farmed area
  
  demand_for_farm_area<-n_subsistence_farmers*necessary_farm_size_per_household
  
  farmed_area<-min(available_area, demand_for_farm_area)*(1-unused_sociopolit)
  
  total_cropwater_need<-cropwat_need*farmed_area*10 # total water need in m3 (the 10 is the mm to m3/ha conversion)
  total_effective_rainfall<-effective_rainfall*farmed_area*10 # total effective rainfall
  
  # total irrigation need
  total_irrigation_need<-total_cropwater_need-total_effective_rainfall # in m3
  
  # water losses are calculated from the efficiency of the pumps and the water allocation
  efficiency_pumps<-vv(effi_pump,var_CV,12)
  efficiency_irrig_scheduling<-vv(effi_sched,var_CV,12)
  efficiency_pumps<-sapply(efficiency_pumps, function(x)  min(x,1))
  efficiency_pumps<-sapply(efficiency_pumps, function(x)  max(x,0))
  efficiency_irrig_scheduling<-sapply(efficiency_irrig_scheduling, function(x)  min(x,1))
  efficiency_irrig_scheduling<-sapply(efficiency_irrig_scheduling, function(x)  max(x,0))
  
  water_losses_share<-(1-efficiency_pumps*efficiency_irrig_scheduling)
  
  irrigation_water_need<-total_irrigation_need/(1-water_losses_share)
  
  # eflow scenario 1 - no eflows
  
  scen1_usable_river_flow<-sapply(1:12,function(x) max(0,river_flow[x]-minimum_flow_to_operate_pumps))
  
  # eflow scenario 2 - eflows as a limit to extraction only
  
  # eflows are to be ensured whenever there is more water in the river than the eflow
  # requirement would mandate, i.e. farmers aren't allowed to extract water beyond
  # the eflow requirement.
  # no measures are taken to ensure that eflows are maintained at times when
  # the present flow is below the eflow requirement. 
  
  scen2_usable_river_flow<-sapply(1:12,function(x) max(0,river_flow[x]-max(eflow[x],minimum_flow_to_operate_pumps)))
  
  # eflow scenario 3 - eflows are assured by dam releases
  
  # whenever the present flow is below the eflow requirement, water is released
  # from an upstream dam to ensure that the eflows are met.
  
  adj_river_flow <- sapply(1:12, function(x)
    max(river_flow[x], eflow[x]))
  
  required_dam_release <- adj_river_flow - river_flow
  
  scen3_usable_river_flow <-
    sapply(1:12, function(x)
      max(0, adj_river_flow[x] - minimum_flow_to_operate_pumps))
  
  # calculate how much water gets extracted from the river
  
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
  
  scen1_irrigation_shortfall<-scen1_water_shortfall*(1-water_losses_share)
  scen2_irrigation_shortfall<-scen2_water_shortfall*(1-water_losses_share)
  scen3_irrigation_shortfall<-scen3_water_shortfall*(1-water_losses_share)
  
  scen1_crop_water_gap<-scen1_irrigation_shortfall/(cropwat_need*farmed_area*10)
  scen2_crop_water_gap<-scen2_irrigation_shortfall/(cropwat_need*farmed_area*10)
  scen3_crop_water_gap<-scen3_irrigation_shortfall/(cropwat_need*farmed_area*10)
  
  # calculate how much water is left after farmers extracted water
  scen1_river_flow_downstream<-river_flow-scen1_extracted_river_water
  scen2_river_flow_downstream<-river_flow-scen2_extracted_river_water
  scen3_river_flow_downstream<-adj_river_flow-scen3_extracted_river_water
  
  # calculate outputs and differences 
  
  return(list(scen1_downstream_river_flow=scen1_river_flow_downstream,
              scen2_downstream_river_flow=scen2_river_flow_downstream,
              scen3_downstream_river_flow=scen3_river_flow_downstream,
              scen3_dam_release=required_dam_release,
              Downstream_difference_2_vs_1=scen2_river_flow_downstream-scen1_river_flow_downstream,
              Downstream_difference_3_vs_1=scen3_river_flow_downstream-scen1_river_flow_downstream,
              scen1_crop_water_gap=scen1_crop_water_gap,
              scen2_crop_water_gap=scen2_crop_water_gap,
              scen3_crop_water_gap=scen3_crop_water_gap,
              Crop_water_gap_difference_2_vs_1=scen2_crop_water_gap-scen1_crop_water_gap,
              Crop_water_gap_difference_3_vs_1=scen3_crop_water_gap-scen1_crop_water_gap,
              Mean_Crop_water_gap_difference_2_vs_1=mean(scen2_crop_water_gap-scen1_crop_water_gap),
              Mean_Crop_water_gap_difference_3_vs_1=mean(scen3_crop_water_gap-scen1_crop_water_gap)))
  
}


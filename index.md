Modeling the contribution of e-flows to sustainable agriculture, food
security and livelihoods in South Africa’s Limpopo basin
================
Eike Luedeling, Cory Whitney

We generate a holistic model to simulate the contribution of e-flows to
sustainable agriculture, food security and livelihoods. Spatially, we do
this for only a small portion of the basin as a test-case. We apply
holistic modeling approaches to generate conceptual impact pathways and
quantitative models to forecast decision outcomes (see Do, Luedeling,
and Whitney 2020; Lanzanova et al. 2019; Cory Whitney et al. 2018). This
includes collaborative model development (C. Whitney, Shepherd, and
Luedeling 2018) to assess farming futures given e-flow forecasts under
different management options. To build these simulations we use
functions from the `decisionSupport` (Luedeling et al. 2022), `dplyr`
(Wickham, François, et al. 2022), `nasapower` (Sparks 2022), `patchwork`
(Pedersen 2020), `tidyverse` (Wickham 2021) and `Evapotranspiration`
(Guo, Westra, and Peterson 2022) libraries in the R programming language
(R Core Team 2022).

## The model

Decision-makers often wish to have a quantitative basis for their
decisions. However,‘hard data’ is often missing or unattainable for many
important variables, which can paralyze the decision-making processes or
lead decision-makers to conclude that large research efforts are needed
before a decision can be made. That is, many variables decision makers
must consider cannot be precisely quantified, at least not without
unreasonable effort. The major objective of (prescriptive) decision
analysis is to support decision-making processes where decision makers
are faced with this problem. Following the principles of Decision
Analysis can allow us to make forecasts of decision outcomes without
precise numbers, as long as probability distributions describing the
possible values for all variables can be estimated.

The `decisionSupport` package implements this as a Monte Carlo
simulation, which generates a large number of plausible system outcomes,
based on random numbers for each input variable that are drawn from
user-specified probability distributions. This approach is useful for
determining whether a clearly preferable course of action can be
delineated based on the present state of knowledge without the need for
further information. If the distribution of predicted system outcomes
does not imply a clearly preferable decision option, variables
identified as carrying decision-relevant uncertainty can then be
targeted by decision-supporting research.

The `mcSimulation` function from the `decisionSupport` package can be
applied to conduct decision analysis (Luedeling et al. 2022). The
function requires three inputs:

1.  an `estimate` of the joint probability distribution of the input
    variables. These specify the names and probability distributions for
    all variables used in the decision model. These distributions aim to
    represent the full range of possible values for each component of
    the model.
2.  a `model_function` that predicts decision outcomes based on the
    variables named in a separate data table. This R function is
    customized by the user to address a particular decision problem to
    provide the decision analysis model.  
3.  `numberOfModelRuns` indicating the number of times to run the model
    function.

These inputs are provided as arguments to the `mcSimulation` function,
which conducts a Monte Carlo analysis with repeated model runs based on
probability distributions for all uncertain variables. The data table
and model are customized to fit the particulars of a specific decision.

### The `estimate`

To support the model building process we design an input table to store
the `estimate` values. The table is stored locally as
`limpopo_input_table.csv` and contains many of the basic values for the
analysis. This table contains all the input variables used in the model.
Their distributions are described by 90% confidence intervals, which are
specified by lower (5% quantile) and upper (95% quantile) bounds, as
well as the shape of the distribution. This model uses four different
distributions:

1.  `const` – a constant value
2.  `norm` – a normal distribution
3.  `tnorm_0_1` – a truncated normal distribution that can only have
    values between 0 and 1 (useful for probabilities; note that 0 and 1,
    as well as numbers outside this interval are not permitted as
    inputs)
4.  `posnorm` – a normal distribution truncated at 0 (only positive
    values allowed)

For a full list of input variables with descriptions and the chosen
distributions see the table at the end of this document.

### Scenarios

The following function defines 3 scenarios:

1.  UNRES – baseline, unrestricted water use with no e-flows: This is a
    scenario without eflows. Farmers extract water according to their
    irrigation needs. Extractions are only limited by the minimum water
    level that allows operating the pumps.
2.  EFLOW – E-flow through abstraction control (without using dam
    releases) with restricted extraction: This is an eflow scenario, in
    which eflows are interpreted in a purely ecological sense. Whenever
    eflows aren’t achieved, water extraction is curtailed. There are no
    measures to add water to the river in such events. We simulate this
    scenario with our own functions and some from the `nasapower`
    (Sparks 2022) and `Evapotranspiration` (Guo, Westra, and
    Peterson 2022) packages.
3.  SUPPL – E-flows achieved through abstraction control and dam
    releases: This is an eflow scenario, in which eflows are interpreted
    as encompassing the ecological as well as the smallholder irrigation
    requirement. In case eflows aren’t naturally met, water is released
    from upstream dams to ensure eflows. Extraction by smallholder
    farmers is restricted only by the ability to operate the pumps.

### The conceptual model

![Model of the social effects of altered river flows on the
sustainability of livelihoods in the Limpopo
Basin](figures/Fig_2_Collective_Model.png)

### The `model_function`

The decision model is coded as an R function which takes in the
variables provided in the data table and generates a model output, such
as the Net Present Value.

In the following we use of various decisionSupport functions, which use
the `tidyverse` libraries (Wickham et al. 2019) including `ggplot2`
(Wickham, Chang, et al. 2022), `plyr` (Wickham 2022) and `dplyr`
(Wickham, François, et al. 2022) among others in the [R programming
language](https://www.r-project.org/) (R Core Team 2022).

Here we generate a model as a function using `decisionSupport` library
we use the `decisionSupport` functions `vv()` to produce time series
with variation from a pre-defined mean and coefficient of variation,
`chance_event()` to simulate whether events occur and `discount()` to
discount values along a time series and generate a Net Present Value for
our intervention comparison.

The following script contains the basic model we used to run the Monte
Carlo.

``` r
limpopo_decision_function <- function(x, varnames){

# generating boundary conditions for the simulation run 

# simulate how much rainwater is available
rainfall<-sapply(1:12,function(x) eval(parse(text=paste0("prec_",x))))

effective_rainfall<-sapply(rainfall,function(x) min(x,effprec_high))
effective_rainfall<-sapply(effective_rainfall,function(x) max(x,effprec_low))

# We compute crop water needs based on ET0 
# Computed based on the Hargreaves Samani equation, as implemented in the Evapotranspiration package)
# Input temperature data comes from the NASAPOWER dataset 
# (accessed through the nasapower package) 
# The scenario data are based on scenarios that represent conditions 
# during real years in the past
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

# eflow Scenario 1 - no eflows
scen1_usable_river_flow<-sapply(1:12,function(x) max(0,river_flow[x]-minimum_flow_to_operate_pumps))

# eflow Scenario 2 - eflows as a limit to extraction only

# eflows are to be ensured whenever there is more water in the river than the eflow
# requirement would mandate, i.e. farmers aren't allowed to extract water beyond
# the eflow requirement.
# no measures are taken to ensure that eflows are maintained at times when
# the present flow is below the eflow requirement. 

scen2_usable_river_flow<-sapply(1:12,function(x) max(0,river_flow[x]-max(eflow[x],minimum_flow_to_operate_pumps)))

# eflow Scenario 3 - eflows are assured by dam releases

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
```

### Perform the Monte Carlo simulation with scenarios

Using the model function above, we can perform a Monte Carlo simulation
with the `mcSimulation()` function from `decisionSupport`. This function
generates distributions of all variables in the input table as well as
the specified model outputs (see `return()` function above) by
calculating random draws in our defined `limpopo_decision_function()`.
We run a visual assessment to ensure that all the variables in the input
table are included in the model (erroneous variables listed there can
cause issues with some of the post-hoc analyses).

The `numberOfModelRuns` argument is an integer indicating the number of
model runs for the Monte Carlo simulation. Unless the model function is
very complex, 10,000 runs is a reasonable choice (for complex models,
10,000 model runs can take a while, so especially when the model is
still under development, it often makes sense to use a lower number).

We first make a scenario file, for which we can use data for 1980 to
2020.

``` r
# load data from Evapotranspiration
data("constants")

# use nasapower for evapotranspiration data
ag_d <- get_power(
  community = "ag",
  lonlat = c(31.08,-23.7), #Letaba region
  pars = c("T2M_MAX", "T2M_MIN", "PRECTOTCORR"),
  dates = c("1981-01-01", "2020-12-31"),
  temporal_api = "daily"
)

# choose years of assessment
years <- 1981:2009

# name variables
colnames(ag_d)[c(3:5, 8, 9, 10)] <-
  c("Year", "Month", "Day", "Tmax", "Tmin", "Precipitation")

Inputs <- ReadInputs(c("Tmin", "Tmax"), ag_d, stopmissing = c(50, 50, 50))
#> The maximum acceptable percentage of date indices is 50 %
#> The maximum acceptable percentage of missing data is 50 %
#> The maximum acceptable percentage of continuous missing data is 50 %

# apply ET.HargreavesSamani from the Evapotranspiration library
ET <-
  ET.HargreavesSamani(
    Inputs,
    constants,
    ts = "daily",
    message = "yes",
    AdditionalStats = "yes",
    save.csv = "no"
  )
#> Hargreaves-Samani Reference Crop ET
#> Evaporative surface: reference crop
#> Timestep: daily
#> Units: mm
#> Time duration: 1981-01-01 to 2020-12-31
#> 14610 ET estimates obtained
#> Basic stats
#> Mean: 4.94
#> Max: 30.45
#> Min: 1.35

ETdata <- data.frame(year = years)
ETdata[, month.abb[1:12]] <- NA
for (yyyy in years)
  ETdata[which(ETdata$year == yyyy), 2:13] <-
  ET$ET.Monthly[as.character(yyyy + 0:11 / 12)]

rain <-
  aggregate(ag_d$Precipitation,
            by = list(ag_d$Year, ag_d$Month),
            FUN = sum)
raindata <- data.frame(year = years)
raindata[, month.abb[1:12]] <- NA
for (yyyy in years)
  raindata[which(raindata[, 1] == yyyy), 2:13] <-
  rain[which(rain[, 1] == yyyy), 3]


scenario_variables <-
  c(paste0("river_flow_", 1:12),
    paste0("ET0_", 1:12),
    paste0("prec_", 1:12),
    paste0("eflow_", 1:12))

Scenarios <- data.frame(Variable = scenario_variables, param = "both")

eflows<-read.csv("data/Letaba_eflows_exceedence_m3_per_s.csv",fileEncoding="UTF-8-BOM")
eflowsort <-
  eflows[, c(1, order(unlist(sapply(colnames(eflows)[2:13], function(x)
    which(month.abb[1:12] == x)))) + 1)]
eflow_exceedance<-eflowsort[which(eflowsort$Exceedence == 80),]
eflow_per_month<-eflow_exceedance[2:13]*c(31,28,31,30,31,30,31,31,30,31,30,31)*3600*24

# read data of present data 
present_flows<-read.csv("data/Letaba_modelled_present_flows_m3_per_s.csv",fileEncoding="UTF-8-BOM")
presentflowsort <-
  present_flows[, c(1, order(unlist(sapply(colnames(present_flows)[2:13], function(x)
    which(month.abb[1:12] == x)))) + 1)]
presentflow_permonth<-data.frame(cbind(presentflowsort[,1],t(t(presentflowsort[,2:13])*c(31,28,31,30,31,30,31,31,30,31,30,31)*3600*24)))
colnames(presentflow_permonth)[1]<-"Year"

# The hydrological year in the input file starts in October and runs until September. We're assuming here that the year given for each year in the data sets provided corresponds to the first calendar year of this period.

presentflow_permonth[2:nrow(presentflow_permonth),month.abb[1:9]]<-
  presentflow_permonth[1:(nrow(presentflow_permonth)-1),month.abb[1:9]]

presentflow_permonth[1,month.abb[1:9]]<-NA

for (yyyy in years)
{
  Scenarios[, paste0("y_", yyyy)] <- NA
  for (mm in 1:12)
  {
    Scenarios[which(Scenarios$Variable == paste0("ET0_", mm)), paste0("y_", yyyy)] <-
      ETdata[which(ETdata$year == yyyy), 1 + mm]
    Scenarios[which(Scenarios$Variable == paste0("prec_", mm)), paste0("y_", yyyy)] <-
      raindata[which(raindata$year == yyyy), 1 + mm]
    Scenarios[which(Scenarios$Variable == paste0("river_flow_", mm)), paste0("y_", yyyy)] <-
      presentflow_permonth[which(presentflow_permonth$Year == yyyy), 1 + mm]
    Scenarios[which(Scenarios$Variable == paste0("eflow_", mm)), paste0("y_", yyyy)] <-
      eflow_per_month[mm]
  }
}

# natural flows (this is for information and not used in the model)
natural_flows<-read.csv("data/Letaba_modelled_natural_flows_m3_per_s.csv",fileEncoding="UTF-8-BOM")

# write the scenarios file
write.csv(Scenarios, "data/scenarios_1980_2020.csv", row.names = FALSE)
```

Here we run the model with the `scenario_mc` function from the
`decisionSupport` package (Luedeling et al. 2022). The function
essentially generates a Monte Carlo model with data from existing
scenarios for some of the model inputs.

``` r
# run the model with the scenario_mc function 
mcSimulation_results <-
  scenario_mc(
    base_estimate = decisionSupport::estimate_read_csv("data/limpopo_input_table.csv"),
    scenarios = read.csv("data/scenarios_1980_2020.csv", fileEncoding =
                           "UTF-8-BOM"),
    model_function = limpopo_decision_function,
    numberOfModelRuns = 1e2, #run 100 times (2900 with 100 simulations of 29 scenarios)
    functionSyntax = "plainNames"
  )

#save this someplace to share
write.csv(mcSimulation_results, file = "data/mcSimulation_results.csv")
```

# Results

### Water needs

``` r
# Here the general estimates about needed water for crops
plotting_simulations <- mcSimulation_results 

Fig_total_annual_crop_water_irrigation_need <- 
        decisionSupport::plot_distributions(mcSimulation_object = plotting_simulations,
                                    vars = c("yearly_crop_water_need",
                                             "yearly_irrigation_water_need"),
                                    method = 'smooth_simple_overlay',
                                    x_axis_name = "",
                                    y_axis_name = "Distribution density",
                                    base_size = 13)  + 
                    ggplot2::theme_classic() + 
                    ggplot2::labs(x = expression(Total~annual~water~need~(m^3))) + 
                    ggplot2::labs(fill = "") +
                    ggplot2::scale_fill_discrete(labels=c('Crops', 'Irrigation')) +     
                    ggplot2::theme(legend.position="bottom") 
#> Scale for 'fill' is already present. Adding another scale for 'fill', which
#> will replace the existing scale.

Fig_monthly_irrigation_water_need <- plot_cashflow(mcSimulation_object = plotting_simulations, 
              cashflow_var_name = "irrigation_water_need",
              y_axis_name = "",
              x_axis_name = "Month", 
              facet_labels = "") + 
  labs(y = expression(Monthly~irrigation~water~need~(m^3)))
```

### Baseline vs scenarios results

``` r
library(patchwork)

Fig_total_annual_crop_water_irrigation_need +
  inset_element(Fig_monthly_irrigation_water_need, 
                  left = 0.29, 
                  bottom = 0.29, 
                  right = 0.97, 
                  top = 0.97) + 
  plot_annotation(title = "Annual crop water need")
```

![](index_files/figure-gfm/plot_baseline_results-1.png)<!-- -->

``` r

ggsave("figures/Fig_3_water_needs.png", width=10, height=5)


gap1_simulations <- mcSimulation_results 

gap1_simulations$y[,paste0("Crop_water_gap_scen1_",1:12)] <- gap1_simulations$y[,paste0("Crop_water_gap_scen1_",1:12)]*100

Fig_monthly_baseline_crop_water_gap <- 
  plot_cashflow(mcSimulation_object = gap1_simulations, 
              cashflow_var_name = "Crop_water_gap_scen1_",
              y_axis_name = "",
              x_axis_name = "", 
              facet_labels = "") + 
            labs(y = expression("")) + 
  annotate(geom="text", x=3, y=93, 
           label=expression(atop("Total gap (%) UNRES", 
                   paste("unrestricted water use")))) + 
          theme( axis.text.x = element_blank(),
          axis.ticks = element_blank())


gap2_1_simulations <- mcSimulation_results 

gap2_1_simulations$y[,paste0("Crop_water_gap_difference_2_vs_1",1:12)] <- gap2_1_simulations$y[,paste0("Crop_water_gap_difference_2_vs_1",1:12)]*100

monthly_crop_water_gap_environmental <- plot_cashflow(mcSimulation_object = gap2_1_simulations, 
              cashflow_var_name = "Crop_water_gap_difference_2_vs_1",
              y_axis_name = "",
              x_axis_name = "", 
              facet_labels = "") + 
  annotate(geom="text", x=3, y=77, 
           label=expression(atop("% change EFLOW", 
                                 paste("abstraction control")))) + 
          theme( axis.text.x = element_blank(),
          axis.ticks = element_blank()) + 
  labs(y = "Monthly crop water gap for all e-flows scenarios")

gap3_1_simulations <- mcSimulation_results

gap3_1_simulations$y[,paste0("Crop_water_gap_difference_3_vs_1",1:12)] <- gap3_1_simulations$y[,paste0("Crop_water_gap_difference_3_vs_1",1:12)]*100

monthly_crop_water_gap_suppl <- plot_cashflow(mcSimulation_object = gap3_1_simulations, 
              cashflow_var_name = "Crop_water_gap_difference_3_vs_1",
              y_axis_name = "",
              x_axis_name = "Month", 
              facet_labels = "") + 
  annotate(geom="text", x=3, y= -80, 
            label=(expression(atop("% change SUPPL", 
                                   paste("dam releases")))))


library(patchwork)

Fig_monthly_baseline_crop_water_gap +
  monthly_crop_water_gap_environmental +
  monthly_crop_water_gap_suppl +
  plot_layout(ncol = 1, guides = "collect")  
#> Warning in is.na(x): is.na() applied to non-(list or vector) of type
#> 'expression'

#> Warning in is.na(x): is.na() applied to non-(list or vector) of type
#> 'expression'

#> Warning in is.na(x): is.na() applied to non-(list or vector) of type
#> 'expression'
```

![](index_files/figure-gfm/plot_baseline_results-2.png)<!-- -->

``` r
ggsave("figures/Fig_5_flows.png", width=7, height=10)
#> Warning in is.na(x): is.na() applied to non-(list or vector) of type
#> 'expression'

#> Warning in is.na(x): is.na() applied to non-(list or vector) of type
#> 'expression'

#> Warning in is.na(x): is.na() applied to non-(list or vector) of type
#> 'expression'
```

### Change in crop water gap

``` r
# Here the distribution of the changes in the crop water gap through e-flows.

eflow_simulations <- mcSimulation_results

eflow_simulations$y$scen1_crop_water_gap <- eflow_simulations$y$scen1_crop_water_gap*100

eflow_simulations$y$Mean_Crop_water_gap_difference_2_vs_1 <- eflow_simulations$y$Mean_Crop_water_gap_difference_2_vs_1*100

eflow_simulations$y$Mean_Crop_water_gap_difference_3_vs_1 <- eflow_simulations$y$Mean_Crop_water_gap_difference_3_vs_1*100

Fig_eflow_policy_effect_crop_water_gap <- decisionSupport::plot_distributions(mcSimulation_object = eflow_simulations,
                                    vars = c("scen1_crop_water_gap",
                                             "Mean_Crop_water_gap_difference_2_vs_1", 
                                             "Mean_Crop_water_gap_difference_3_vs_1"),
                                    method = 'smooth_simple_overlay',
                                    x_axis_name = expression("Annual crop water gap % of needed irrigation water"),
                                    y_axis_name = "Distribution density",
                                    base_size = 13) + 
                    ggplot2::theme_classic() + 
                    ggplot2::labs(fill = "")  +
                     ggplot2::scale_fill_discrete(labels=c('UNRES (unrestricted) baseline', 'EFLOW abstraction control', 'SUPPL dam releases')) 
#> Scale for 'fill' is already present. Adding another scale for 'fill', which
#> will replace the existing scale.

eflow2_1_simulations <- mcSimulation_results

eflow2_1_simulations$y[,paste0("Crop_water_gap_difference_2_vs_1",1:12)] <- eflow2_1_simulations$y[,paste0("Crop_water_gap_difference_2_vs_1",1:12)]*100

Fig_monthly_env_eflow_increase_crop_water_gap <- plot_cashflow(mcSimulation_object = eflow2_1_simulations, 
              cashflow_var_name = "Crop_water_gap_difference_2_vs_1",
              y_axis_name = "",
              x_axis_name = "Month", 
              facet_labels = "") + 
  labs(y = expression("Crop water gap change (%)"))


# Here are the impacts of e-flow policy on the crop water gap in each month (livelihoods focused, environmentally focused)

library(patchwork)

 Fig_eflow_policy_effect_crop_water_gap + 
   plot_layout(guides = "collect") + 
   plot_annotation(title = "Crop water gap for all e-flows scenarios") &     
                    ggplot2::theme(legend.position="bottom") 
```

![](index_files/figure-gfm/plot_eflows_gap_change-1.png)<!-- -->

``` r
ggsave("figures/Fig_4_All_eflows.png", width=10, height=5)
```

### Dam releases

``` r
releases_simulations <- mcSimulation_results

Fig_7_required_dam_release <- plot_cashflow(mcSimulation_object = releases_simulations, 
              cashflow_var_name = "scen3_dam_release",
              y_axis_name = "a",
              x_axis_name = "Month", 
              facet_labels = "") + 
  labs(y = expression(atop(Required~water~release, paste(from~upstream~dams~(m^3)))))

library(patchwork)

  Fig_7_required_dam_release +
  plot_layout(ncol = 1, guides = "collect")  
```

![](index_files/figure-gfm/dam_release-1.png)<!-- -->

``` r
  
ggsave("figures/Fig_7_dam_release.png", width=7, height=5)
```

### Stream flow

``` r
# Here's the impact on stream flow 
#('UNRES (unrestricted) baseline', 'EFLOW abstraction control', 'SUPPL dam releases')) 
#Downstream river flows also vary throughout the year under the no e-flows scenario.

flow_simulations <- mcSimulation_results

Fig_monthly_downstream_river_flow <-
  plot_cashflow(mcSimulation_object = flow_simulations, 
              cashflow_var_name = "Downstream_river_flow_1_",
              y_axis_name = "",
              x_axis_name = "", 
              facet_labels = "") + 
  annotate(geom="text", x=9, y= 200000000, 
            label=(expression(atop("UNRES", 
                                   paste("(unrestricted) baseline"))))) + 
          theme( axis.text.x = element_blank(),
          axis.ticks = element_blank())

# Here's the impact on stream flow Downstream_difference_2_vs_1:

Fig_monthly_change_in_downstream_river_flow_env_eflows <-
  plot_cashflow(mcSimulation_object = flow_simulations, 
              cashflow_var_name = "Downstream_difference_2_vs_1",
              y_axis_name = "",
              x_axis_name = "", 
              facet_labels = "") +  
  annotate(geom="text", x=9, y= 250000, 
            label=(expression(atop("EFLOW", 
                                   paste("abstraction control"))))) + 
          theme( axis.text.x = element_blank(),
          axis.ticks = element_blank()) + 
  labs(y = expression(Downstream~river~flow~(m^3)))

Fig_monthly_change_in_downstream_river_flow_live_eflows <-
  plot_cashflow(mcSimulation_object = flow_simulations, 
              cashflow_var_name = "Downstream_difference_3_vs_1",
              y_axis_name = "",
              x_axis_name = "Month", 
              facet_labels = "") + 
  annotate(geom="text", x=9, y= 400000, 
            label=(expression(atop("SUPPL", 
                                   paste("dam releases")))))



library(patchwork)

  Fig_monthly_downstream_river_flow + 
  Fig_monthly_change_in_downstream_river_flow_env_eflows +
    Fig_monthly_change_in_downstream_river_flow_live_eflows +
  plot_layout(ncol = 1, guides = "collect")  
```

![](index_files/figure-gfm/stream-flow-1.png)<!-- -->

``` r
    # plot_annotation(title = expression(Downstream~river~flow~(m^3))) 

  # plot_annotation(tag_levels = 'a') +
# guides = "collect"

ggsave("figures/Fig_6_downstream.png", width=7, height=10)
```

## Sensitivity analysis

We use the `plsr.mcSimulation` function of the `decisionSupport` package
to run Partial Least Squares regression on the model outputs. Projection
to Latent Structures (PLS), also sometimes known as Partial Least
Squares regression is a multivariate statistical technique that can deal
with multiple colinear dependent and independent variables (Wold,
Sjöström, and Eriksson 2001). It can be used as another means to assess
the outcomes of a Monte Carlo model. We use the Variable Importance in
the Projection (VIP) scores to identify important variables. VIP scores
estimate the importance of each variable in the projection used in a PLS
model. VIP is a parameter used for calculating the cumulative measure of
the influence of individual variables on the model. Read more in [‘A
Simple Explanation of Partial Least Squares’ by Kee Siong
Ng](http://users.cecs.anu.edu.au/~kee/pls.pdf). More information on all
these procedures is contained in the [decisionSupport
manual](https://cran.r-project.org/web/packages/decisionSupport/decisionSupport.pdf),
especially under `welfareDecisionAnalysis`.

We apply the aforementioned post-hoc analysis to the `mcSimulation()`
outputs with `plsr.mcSimulation()` to determine the VIP score and
coefficients of our PLS regression models. This functions use the
outputs of the `mcSimulation()` selecting all the input variables from
the decision analysis function in the parameter `object` and then runs a
PLS regression with an outcome variable defined in the parameter
`resultName`. We also need to import the input table again to replace
the labels for the variables on the y-axis. The input table can include
a `label` and `variable` column. The standard labels (from the
`variable` column) are usually computer readable and not very nice for a
plot. The `plot_pls()` function uses the text in the `label` column as
replacement for the default text in the `variable` column.

``` r
# to ensure a clear process (not overwriting the original data) 
# rename the simulations results
mcSimulation_pls <- mcSimulation_results
# select the data for the scenario analysis 
mcSimulation_pls$x <- mcSimulation_pls$x[, !names(mcSimulation_pls$x) == "Scenario"]

pls_result_crop_water_need <- plsr.mcSimulation(object = mcSimulation_pls,
                  resultName = "yearly_crop_water_need",
                  ncomp = 1)

input_table <- read.csv("data/limpopo_input_table.csv")

# ### Irrigation demand

### No e-flows

pls_result_1 <- plsr.mcSimulation(object = mcSimulation_pls,
                  resultName = "scen1_crop_water_gap", 
                  ncomp = 1)

PLS_UNRES_baseline_crop_water_gap <- plot_pls(pls_result_1, 
                            input_table = input_table, 
                            threshold = 1) + 
  annotate(geom="text", x=1.7, y=3,
           label=expression(atop("UNRES",
                   paste("unrestricted water use")))) +
          theme(axis.text.x = element_blank(),
          axis.ticks = element_blank(),
          axis.title.x = element_blank())

### Environmental e-flows

pls_result_2 <- plsr.mcSimulation(object = mcSimulation_pls,
                  #  resultName = "Crop_water_gap_difference_2_vs_1",
                   resultName = "scen2_crop_water_gap", 
                  ncomp = 1)

Fig_PLS_EFLOW_crop_water_gap <- plot_pls(pls_result_2, 
                            input_table = input_table, 
                            threshold = 1, 
                            y_axis_name = "Model input variables") + 
  annotate(geom="text", x=1.7, y=3, 
           label=expression(atop("EFLOW", 
                   paste("abstraction control")))) + 
          theme(axis.text.x = element_blank(),
          axis.ticks = element_blank(),
          axis.title.x = element_blank())

### SUPPL dam release - Livelihoods e-flows

pls_result_3 <- plsr.mcSimulation(object = mcSimulation_pls,
                  #  resultName = "Crop_water_gap_difference_3_vs_1",  
                   resultName = "scen3_total_dam_release", 
                  ncomp = 1)

Fig_PLS_SUPPL_dam_release_crop_water_gap <- plot_pls(pls_result_3, 
                            input_table = input_table, 
                            threshold = 1, 
                            x_axis_name = "VIP")+ 
  annotate(geom="text", x=1.7, y=3, 
           label=expression(atop("SUPPL", 
                   paste("dam releases"))))  


library(patchwork)
      PLS_UNRES_baseline_crop_water_gap +
      Fig_PLS_EFLOW_crop_water_gap +
      Fig_PLS_SUPPL_dam_release_crop_water_gap +
      plot_layout(ncol = 1, guides = "collect") + 
    plot_annotation(title = "Variable Importance in the Projection (VIP)") &     
                    ggplot2::theme(legend.position="bottom") 
```

![](index_files/figure-gfm/pls-crop_needs-1.png)<!-- -->

``` r

ggsave("figures/Fig_8_sensitivity.png", width=7, height=10)
```

## Expected Value of Perfect Information

Here we calculate the Expected Value of Perfect Information (EVPI) using
the `multi_EVPI` function in the `decisionSupport` package. The results
show that there would be little additional value in the knowledge gained
by gathering further knowledge on any of the variables that were
included in the analysis.

``` r
# to ensure a clear process (not overwriting the original data) 
# rename the simulations results
simulations_evpi_data <- mcSimulation_results

#here we subset the outputs from the mcSimulation function (y) by selecting the comparative mean crop water gap variables
simulations_evpi_data_table <- data.frame(simulations_evpi_data$x[1:71], simulations_evpi_data$y[118:119])

# Run evpi

results_evpi <- multi_EVPI(mc = simulations_evpi_data_table, 
                          first_out_var = "Mean_Crop_water_gap_difference_2_vs_1")
#> [1] "Processing 2 output variables. This can take some time."
#> [1] "Output variable 1 (Mean_Crop_water_gap_difference_2_vs_1) completed."
#> [1] "Output variable 2 (Mean_Crop_water_gap_difference_3_vs_1) completed."
```

The EVPI summary statistics for the mean crop water gap difference
between the baseline UNRES and EFLOW scenarios.

``` r
summary(results_evpi$Mean_Crop_water_gap_difference_2_vs_1)
#>    variable         expected_gain        EVPI_do    EVPI_dont            EVPI  
#>  Length:71          Min.   :0.01862   Min.   :0   Min.   :0.00000   Min.   :0  
#>  Class :character   1st Qu.:0.08705   1st Qu.:0   1st Qu.:0.06397   1st Qu.:0  
#>  Mode  :character   Median :0.11872   Median :0   Median :0.10968   Median :0  
#>                     Mean   :0.10488   Mean   :0   Mean   :0.08715   Mean   :0  
#>                     3rd Qu.:0.12458   3rd Qu.:0   3rd Qu.:0.12435   3rd Qu.:0  
#>                     Max.   :0.17034   Max.   :0   Max.   :0.17034   Max.   :0  
#>                     NA's   :12                                                 
#>    decision        
#>  Length:71         
#>  Class :character  
#>  Mode  :character  
#>                    
#>                    
#>                    
#> 
```

The EVPI summary statistics for the mean crop water gap difference
between the baseline UNRES and SUPPL scenarios.

``` r
summary(results_evpi$Mean_Crop_water_gap_difference_3_vs_1)
#>    variable         expected_gain         EVPI_do         EVPI_dont      EVPI  
#>  Length:71          Min.   :-0.41267   Min.   :0.0000   Min.   :0   Min.   :0  
#>  Class :character   1st Qu.:-0.39056   1st Qu.:0.1394   1st Qu.:0   1st Qu.:0  
#>  Mode  :character   Median :-0.37450   Median :0.3387   Median :0   Median :0  
#>                     Mean   :-0.31421   Mean   :0.2611   Mean   :0   Mean   :0  
#>                     3rd Qu.:-0.26694   3rd Qu.:0.3901   3rd Qu.:0   3rd Qu.:0  
#>                     Max.   :-0.04822   Max.   :0.4127   Max.   :0   Max.   :0  
#>                     NA's   :12                                                 
#>    decision        
#>  Length:71         
#>  Class :character  
#>  Mode  :character  
#>                    
#>                    
#>                    
#> 
```

## Estimate values

| Description                                                                                                                                               | variable                          | distribution |       lower |       upper | label                                |
|:----------------------------------------------------------------------------------------------------------------------------------------------------------|:----------------------------------|:-------------|------------:|------------:|:-------------------------------------|
| Precipitation in month 1                                                                                                                                  | prec_1                            | posnorm      |       45.00 |      135.00 | Precipitation in January             |
| Precipitation in month 2                                                                                                                                  | prec_2                            | posnorm      |       31.00 |       93.00 | Precipitation in February            |
| Precipitation in month 3                                                                                                                                  | prec_3                            | posnorm      |       25.00 |       75.00 | Precipitation in March               |
| Precipitation in month 4                                                                                                                                  | prec_4                            | posnorm      |       12.50 |       37.50 | Precipitation in April               |
| Precipitation in month 5                                                                                                                                  | prec_5                            | posnorm      |        5.00 |       15.00 | Precipitation in May                 |
| Precipitation in month 6                                                                                                                                  | prec_6                            | posnorm      |        1.00 |        3.00 | Precipitation in June                |
| Precipitation in month 7                                                                                                                                  | prec_7                            | posnorm      |        2.00 |        6.00 | Precipitation in July                |
| Precipitation in month 8                                                                                                                                  | prec_8                            | posnorm      |        3.00 |        9.00 | Precipitation in August              |
| Precipitation in month 9                                                                                                                                  | prec_9                            | posnorm      |        7.00 |       21.00 | Precipitation in September           |
| Precipitation in month 10                                                                                                                                 | prec_10                           | posnorm      |       12.50 |       37.50 | Precipitation in October             |
| Precipitation in month 11                                                                                                                                 | prec_11                           | posnorm      |       35.00 |      105.00 | Precipitation in November            |
| Precipitation in month 12                                                                                                                                 | prec_12                           | posnorm      |       45.00 |      135.00 | Precipitation in December            |
|                                                                                                                                                           |                                   |              |          NA |          NA |                                      |
| Reference evapotranspiration (ET0) mm/per ha month 1 (Hargreaves Samani equation with nasapower package)                                                  | ET0_1                             | posnorm      |      144.00 |      240.00 | Ref. evapotranspiration in January   |
| Reference evapotranspiration (ET0) mm/per ha month 2                                                                                                      | ET0_2                             | posnorm      |      114.75 |      191.25 | Ref. evapotranspiration in February  |
| Reference evapotranspiration (ET0) mm/per ha month 3                                                                                                      | ET0_3                             | posnorm      |       96.00 |      160.00 | Ref. evapotranspiration in March     |
| Reference evapotranspiration (ET0) mm/per ha month 4                                                                                                      | ET0_4                             | posnorm      |       67.50 |      112.50 | Ref. evapotranspiration in April     |
| Reference evapotranspiration (ET0) mm/per ha month 5                                                                                                      | ET0_5                             | posnorm      |       52.50 |       87.50 | Ref. evapotranspiration in May       |
| Reference evapotranspiration (ET0) mm/per ha month 6                                                                                                      | ET0_6                             | posnorm      |       32.25 |       53.75 | Ref. evapotranspiration in June      |
| Reference evapotranspiration (ET0) mm/per ha month 7                                                                                                      | ET0_7                             | posnorm      |       40.50 |       67.50 | Ref. evapotranspiration in July      |
| Reference evapotranspiration (ET0) mm/per ha month 8                                                                                                      | ET0_8                             | posnorm      |       52.50 |       87.50 | Ref. evapotranspiration in August    |
| Reference evapotranspiration (ET0) mm/per ha month 9                                                                                                      | ET0_9                             | posnorm      |       71.25 |      118.75 | Ref. evapotranspiration in September |
| Reference evapotranspiration (ET0) mm/per ha month 10                                                                                                     | ET0_10                            | posnorm      |       99.75 |      166.25 | Ref. evapotranspiration in October   |
| Reference evapotranspiration (ET0) mm/per ha month 11                                                                                                     | ET0_11                            | posnorm      |      126.00 |      210.00 | Ref. evapotranspiration in November  |
| Reference evapotranspiration (ET0) mm/per ha month 12                                                                                                     | ET0_12                            | posnorm      |      145.50 |      242.50 | Ref. evapotranspiration in December  |
|                                                                                                                                                           |                                   |              |          NA |          NA |                                      |
| Crop coefficient in month 1                                                                                                                               | kc_1                              | posnorm      |        0.90 |        1.00 | kc_1                                 |
| Crop coefficient in month 2                                                                                                                               | kc_2                              | posnorm      |        0.90 |        1.00 | kc_2                                 |
| Crop coefficient in month 3                                                                                                                               | kc_3                              | posnorm      |        0.90 |        1.00 | kc_3                                 |
| Crop coefficient in month 4                                                                                                                               | kc_4                              | posnorm      |        0.90 |        1.00 | kc_4                                 |
| Crop coefficient in month 5                                                                                                                               | kc_5                              | posnorm      |        0.90 |        1.00 | kc_5                                 |
| Crop coefficient in month 6                                                                                                                               | kc_6                              | posnorm      |        0.90 |        1.00 | kc_6                                 |
| Crop coefficient in month 7                                                                                                                               | kc_7                              | posnorm      |        0.90 |        1.00 | kc_7                                 |
| Crop coefficient in month 8                                                                                                                               | kc_8                              | posnorm      |        0.90 |        1.00 | kc_8                                 |
| Crop coefficient in month 9                                                                                                                               | kc_9                              | posnorm      |        0.90 |        1.00 | kc_9                                 |
| Crop coefficient in month 10                                                                                                                              | kc_10                             | posnorm      |        0.90 |        1.00 | kc_10                                |
| Crop coefficient in month 11                                                                                                                              | kc_11                             | posnorm      |        0.90 |        1.00 | kc_11                                |
| Crop coefficient in month 12                                                                                                                              | kc_12                             | posnorm      |        0.90 |        1.00 | kc_12                                |
|                                                                                                                                                           |                                   |              |          NA |          NA |                                      |
| Effective rainfall - minimum threshold                                                                                                                    | effprec_low                       | posnorm      |        5.00 |       10.00 | effprec_low                          |
| Effective rainfall - maximum threshold                                                                                                                    | effprec_high                      | posnorm      |       90.00 |      200.00 | effprec_high                         |
|                                                                                                                                                           |                                   |              |          NA |          NA |                                      |
| Efficiency of water pumps                                                                                                                                 | effi_pump                         | tnorm_0\_1   |        0.70 |        0.90 | Efficiency of the water pumps        |
| Efficiency of irrigation scheduling and allocation                                                                                                        | effi_sched                        | tnorm_0\_1   |        0.60 |        0.90 | Efficiency of irrigation scheduling  |
| Coefficient of variation, ratio of the standard deviation to the mean (a measure of relative variability).                                                | var_CV                            | posnorm      |        5.00 |       20.00 | var_CV                               |
|                                                                                                                                                           |                                   |              |          NA |          NA |                                      |
| Total irrigable area                                                                                                                                      | available_area                    | posnorm      |      100.00 |      300.00 | Available area                       |
| Share of land that is not used because of socio-political obstacles                                                                                       | unused_sociopolit                 | tnorm_0\_1   |        0.20 |        0.40 | Share of unused lands                |
| Number of subsistence households                                                                                                                          | n_subsistence_farmers             | posnorm      |       30.00 |      200.00 | Number of subsistence farmers        |
| Farm size per subsistence households                                                                                                                      | necessary_farm_size_per_household | posnorm      |        1.50 |        2.50 | Needed farm size per household       |
|                                                                                                                                                           |                                   |              |          NA |          NA |                                      |
| eflow in month 1                                                                                                                                          | eflow_1                           | posnorm      |  1658637.36 |  2487956.04 | eflow_1                              |
| eflow in month 2                                                                                                                                          | eflow_2                           | posnorm      |  1953364.40 |  2930046.59 | eflow_2                              |
| eflow in month 3                                                                                                                                          | eflow_3                           | posnorm      |  2172764.83 |  3259147.25 | eflow_3                              |
| eflow in month 4                                                                                                                                          | eflow_4                           | posnorm      |  5094152.71 |  7641229.07 | eflow_4                              |
| eflow in month 5                                                                                                                                          | eflow_5                           | posnorm      | 12093593.23 | 18140389.85 | eflow_5                              |
| eflow in month 6                                                                                                                                          | eflow_6                           | posnorm      |  4593467.28 |  6890200.92 | eflow_6                              |
| eflow in month 7                                                                                                                                          | eflow_7                           | posnorm      |  2895912.09 |  4343868.13 | eflow_7                              |
| eflow in month 8                                                                                                                                          | eflow_8                           | posnorm      |  2484366.68 |  3726550.02 | eflow_8                              |
| eflow in month 9                                                                                                                                          | eflow_9                           | posnorm      |  2173592.97 |  3260389.45 | eflow_9                              |
| eflow in month 10                                                                                                                                         | eflow_10                          | posnorm      |  2052485.78 |  3078728.68 | eflow_10                             |
| eflow in month 11                                                                                                                                         | eflow_11                          | posnorm      |  1670297.91 |  2505446.86 | eflow_11                             |
| eflow in month 12                                                                                                                                         | eflow_12                          | posnorm      |  1419171.87 |  2128757.80 | eflow_12                             |
|                                                                                                                                                           |                                   |              |          NA |          NA |                                      |
| Minimum river flow that allows running the pumps (in m3/month)                                                                                            | minimum_flow_to_operate_pumps     | posnorm      |    50000.00 |   150000.00 | Minimum flow required by pumps       |
|                                                                                                                                                           |                                   |              |          NA |          NA |                                      |
| river flow in month 1 (Taken from base flow MCM data from 1920 to 2010 (Letaba River at EWR site EWR4 (Letaba Ranch upstream Little Letaba confluence) )) | river_flow_1                      | posnorm      |  3289641.29 | 14884566.58 | River flow in January                |
| river flow in month 2                                                                                                                                     | river_flow_2                      | posnorm      |  3552190.55 | 28211390.25 | River flow in February               |
| river flow in month 3                                                                                                                                     | river_flow_3                      | posnorm      |  3629341.05 | 24557111.18 | River flow in March                  |
| river flow in month 4                                                                                                                                     | river_flow_4                      | posnorm      |  3593958.87 | 18063311.23 | River flow in April                  |
| river flow in month 5                                                                                                                                     | river_flow_5                      | posnorm      |  3506617.70 | 11756278.83 | River flow in May                    |
| river flow in month 6                                                                                                                                     | river_flow_6                      | posnorm      |  3448532.21 |  8821373.46 | River flow in June                   |
| river flow in month 7                                                                                                                                     | river_flow_7                      | posnorm      |  3270609.32 |  7597819.59 | River flow in July                   |
| river flow in month 8                                                                                                                                     | river_flow_8                      | posnorm      |  2770310.63 |  6595355.44 | River flow in August                 |
| river flow in month 9                                                                                                                                     | river_flow_9                      | posnorm      |  2475234.52 |  5976080.25 | River flow in September              |
| river flow in month 10                                                                                                                                    | river_flow_10                     | posnorm      |  2195340.50 |  5425988.65 | River flow in October                |
| river flow in month 11                                                                                                                                    | river_flow_11                     | posnorm      |  2306113.10 |  6163707.61 | River flow in November               |
| river flow in month 12                                                                                                                                    | river_flow_12                     | posnorm      |  2699506.90 |  7293206.41 | River flow in December               |
|                                                                                                                                                           |                                   |              |          NA |          NA |                                      |
| livestock water need per month                                                                                                                            | livestock_water_need              | posnorm      |      300.00 |     2000.00 | livestock_water_need                 |

This table contains the estimate values used for the Monte Carlo
analysis

This document was generated using the `rmarkdown` (Allaire et al. 2022)
and `knitr` (Xie 2022) packages in the R programming language (R Core
Team 2022).

## References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-R-rmarkdown" class="csl-entry">

Allaire, JJ, Yihui Xie, Jonathan McPherson, Javier Luraschi, Kevin
Ushey, Aron Atkins, Hadley Wickham, Joe Cheng, Winston Chang, and
Richard Iannone. 2022. *Rmarkdown: Dynamic Documents for r*.
<https://CRAN.R-project.org/package=rmarkdown>.

</div>

<div id="ref-do_decision_2020" class="csl-entry">

Do, Hoa, Eike Luedeling, and Cory Whitney. 2020. “Decision Analysis of
Agroforestry Options Reveals Adoption Risks for Resource-Poor Farmers.”
*Agronomy for Sustainable Development* 40 (3): 20.
<https://doi.org/10.1007/s13593-020-00624-5>.

</div>

<div id="ref-R-Evapotranspiration" class="csl-entry">

Guo, Danlu, Seth Westra, and Tim Peterson. 2022. *Evapotranspiration:
Modelling Actual, Potential and Reference Crop Evapotranspiration*.
<https://CRAN.R-project.org/package=Evapotranspiration>.

</div>

<div id="ref-lanzanova_improving_2019" class="csl-entry">

Lanzanova, Denis, Cory Whitney, Keith Shepherd, and Eike Luedeling.
2019. “Improving Development Efficiency Through Decision Analysis:
Reservoir Protection in Burkina Faso.” *Environmental Modelling &
Software* 115 (May): 164–75.
<https://doi.org/10.1016/j.envsoft.2019.01.016>.

</div>

<div id="ref-R-decisionSupport" class="csl-entry">

Luedeling, Eike, Lutz Goehring, Katja Schiffers, Cory Whitney, and
Eduardo Fernandez. 2022. *decisionSupport: Quantitative Support of
Decision Making Under Uncertainty*. <http://www.worldagroforestry.org/>.

</div>

<div id="ref-R-patchwork" class="csl-entry">

Pedersen, Thomas Lin. 2020. *Patchwork: The Composer of Plots*.
<https://CRAN.R-project.org/package=patchwork>.

</div>

<div id="ref-R-base" class="csl-entry">

R Core Team. 2022. *R: A Language and Environment for Statistical
Computing*. Vienna, Austria: R Foundation for Statistical Computing.
<https://www.R-project.org/>.

</div>

<div id="ref-R-nasapower" class="csl-entry">

Sparks, Adam H. 2022. *Nasapower: NASA POWER API Client*.
<https://docs.ropensci.org/nasapower/>.

</div>

<div id="ref-whitney_probabilistic_2018" class="csl-entry">

Whitney, Cory, D. Lanzanova, C. Muchiri, K. Shepherd, T. Rosenstock, M.
Krawinkel, J. R. S. Tabuti, and E. Luedeling. 2018. “Probabilistic
Decision Tools for Determining Impacts of Agricultural Development
Policy on Household Nutrition.” *Earth’s Future* 6 (3): 359–72.
<https://doi.org/10.1002/2017EF000765/full>.

</div>

<div id="ref-whitney_decision_2018-1" class="csl-entry">

Whitney, C., K. Shepherd, and E. Luedeling. 2018. “Decision Analysis
Methods Guide; Agricultural Policy for Nutrition.” *World Agroforestry
(ICRAF)* Working Paper series (275): 40.

</div>

<div id="ref-R-tidyverse" class="csl-entry">

Wickham, Hadley. 2021. *Tidyverse: Easily Install and Load the
Tidyverse*. <https://CRAN.R-project.org/package=tidyverse>.

</div>

<div id="ref-R-plyr" class="csl-entry">

———. 2022. *Plyr: Tools for Splitting, Applying and Combining Data*.
<https://CRAN.R-project.org/package=plyr>.

</div>

<div id="ref-tidyverse2019" class="csl-entry">

Wickham, Hadley, Mara Averick, Jennifer Bryan, Winston Chang, Lucy
D’Agostino McGowan, Romain François, Garrett Grolemund, et al. 2019.
“Welcome to the <span class="nocase">tidyverse</span>.” *Journal of Open
Source Software* 4 (43): 1686. <https://doi.org/10.21105/joss.01686>.

</div>

<div id="ref-R-ggplot2" class="csl-entry">

Wickham, Hadley, Winston Chang, Lionel Henry, Thomas Lin Pedersen,
Kohske Takahashi, Claus Wilke, Kara Woo, Hiroaki Yutani, and Dewey
Dunnington. 2022. *Ggplot2: Create Elegant Data Visualisations Using the
Grammar of Graphics*. <https://CRAN.R-project.org/package=ggplot2>.

</div>

<div id="ref-R-dplyr" class="csl-entry">

Wickham, Hadley, Romain François, Lionel Henry, and Kirill Müller. 2022.
*Dplyr: A Grammar of Data Manipulation*.
<https://CRAN.R-project.org/package=dplyr>.

</div>

<div id="ref-wold_pls-regression_2001" class="csl-entry">

Wold, Svante, Michael Sjöström, and Lennart Eriksson. 2001.
“PLS-Regression: A Basic Tool of Chemometrics.” *Chemometrics and
Intelligent Laboratory Systems*, PLS Methods, 58 (2): 109–30.
<https://doi.org/10.1016/S0169-7439(01)00155-1>.

</div>

<div id="ref-R-knitr" class="csl-entry">

Xie, Yihui. 2022. *Knitr: A General-Purpose Package for Dynamic Report
Generation in r*. <https://yihui.org/knitr/>.

</div>

</div>
# meteorological and solar data
# load data from Evapotranspiration
data("constants")

# get global meteorology and surface solar energy climatology data
ag_d <- get_power(
  community = "ag",
  # Coordinates of the Letaba region
  lonlat = c(31.08, -23.7),
  pars = c("T2M_MAX", "T2M_MIN", "PRECTOTCORR"),
  dates = c("1981-01-01", "2020-12-31"),
  # Temporal API end-point for data being queried
  temporal_api = "daily"
)

# Test Check that the temperature and precipitation values make sense for the
# Letaba River region summary(ag_d$Tmax) # maximum temperature is high
# but within reason (low to mid 40's have been recorded)


# choose years of assessment
years <- 1981:2009

# name variables
colnames(ag_d)[c(3:5, 8, 9, 10)] <-
  c("Year", "Month", "Day", "Tmax", "Tmin", "Precipitation")

# Load raw date and climate data with Evapotranspiration
Inputs <- ReadInputs(c("Tmin", "Tmax"), ag_d, stopmissing = c(50, 50, 50))

# Implementing the Hargreaves-Samani formulation for estimating reference crop evapotranspiration
ET <-
  ET.HargreavesSamani(
    Inputs,
    constants,
    ts = "daily",
    message = "yes",
    AdditionalStats = "yes",
    save.csv = "no"
  )

# Test
# Review ET Output
# summary(ET$ET.Monthly)
# monthly ET values are within expected ranges for Letaba River region

# create data frame with years <- 1981:2009
ETdata <- data.frame(year = years)

# three-letter abbreviations for the English month names
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

# Test summary(rain) rainfall values are
# reasonable for Letaba River region While such extreme monthly rainfall is
# uncommon, it is not unprecedented, especially during periods of intense
# weather events like tropical cyclones or prolonged heavy rainfall. For
# instance, tropical cyclones have been known to bring substantial rainfall to
# the region

# 48 unique variable names, with 12 for each category (river_flow, ET0, prec, and eflow).
scenario_variables <-
  c(
    paste0("river_flow_", 1:12),
    paste0("ET0_", 1:12),
    paste0("prec_", 1:12),
    paste0("eflow_", 1:12)
  )

# Scenarios with two columns:
# Variable: Contains all the names from scenario_variables.
# param: Every row in this column is filled with the string "both".
Scenarios <- data.frame(Variable = scenario_variables, param = "both")

# Read the E-flows Data
eflows <- read.csv("data/Letaba_eflows_exceedence_m3_per_s.csv", fileEncoding = "UTF-8-BOM")

#Sort the columns of the eflows data frame so that the monthly columns are
#ordered from January to December.
eflowsort <-
  eflows[, c(1, order(unlist(sapply(colnames(eflows)[2:13], function(x)
    which(month.abb[1:12] == x)))) + 1)]
# Extract the names of the columns corresponding to the months & Match each
# month name to its corresponding index in the order January to December.

# Filter - only include rows with Exceedence == 80
eflow_exceedance <- eflowsort[which(eflowsort$Exceedence == 80), ]

# Test
# # eflow_exceedance Monthly e-flow (m3)=flow rate (m3/s) × number days×24×3600
# For example, for January (0.8 m³/s): 0.8 × 31 × 24 × 3600 = 2 , 142 , 720
# m³/month 0.8×31×24×3600=2,142,720m³/month matches the value in
# eflow_per_month = confirmed

# Convert the e-flow data from cubic meters per second (m³/s) to cubic meters per month (m³/month)
eflow_per_month <- eflow_exceedance[2:13] * c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31) *
  3600 * 24

# Test
# eflow_per_month
# conversion of e-flow rates from m³/s to m³/month is consistently across the months

# Calculate Monthly E-flows in m3 per Month
# read data of present data
present_flows <- read.csv("data/Letaba_modelled_present_flows_m3_per_s.csv",
                          fileEncoding = "UTF-8-BOM")
# Sort present flows
presentflowsort <-
  present_flows[, c(1, order(unlist(sapply(colnames(present_flows)[2:13], function(x)
    which(month.abb[1:12] == x)))) + 1)]

# Convert the present flow data from m³/s to m³/month
# Combine the year column with the converted flow values
presentflow_permonth <- data.frame(cbind(presentflowsort[, 1], t(
  t(presentflowsort[, 2:13]) *
    c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31) *
    3600 * 24
)))
# Test
# summary(presentflow_permonth)
# plot(presentflow_permonth$V1, presentflow_permonth$Jan, 
# type = "l", main = "January River Flow Over Time", xlab = "Year", ylab = "Flow (m³/month)")
# # Some very high values in January but within reason

colnames(presentflow_permonth)[1] <- "Year"

# Partners in SA are the source of local data #### The hydrological year in the
# input file starts in October and runs until September. We've reformatted in
# the file presentflow_permonth[2:nrow(presentflow_permonth), month.abb[1:9]] <-
# presentflow_permonth[1:(nrow(presentflow_permonth)-1), month.abb[1:9]]
# presentflow_permonth[1,month.abb[1:9]]<-NA

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


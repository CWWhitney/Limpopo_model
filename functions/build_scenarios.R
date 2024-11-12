# Load data from Evapotranspiration
data("constants")

# Get global meteorology and surface solar energy climatology data
meteo_clim_data <- get_power(
  community = "ag",
  lonlat = c(31.08, -23.7),
  pars = c("T2M_MAX", "T2M_MIN", "PRECTOTCORR"),
  dates = c("1981-01-01", "2020-12-31"),
  temporal_api = "daily"
)

# Create a data frame with years
years <- 1981:2009
ETdata <- data.frame(year = years)

# Add columns for dry season months (April to October)
ETdata[, month.abb[4:10]] <- NA

# Fill ET data for dry season months
if (!is.null(ET$ET.Monthly)) {
  for (yyyy in years) {
    ETdata[ETdata$year == yyyy, month.abb[4:10]] <- ET$ET.Monthly[as.character(yyyy + (3:9) / 12)]
  }
}

# Check if there are rows to aggregate
if (nrow(meteo_clim_data) > 0) {
  rain <- aggregate(
    meteo_clim_data$PRECTOTCORR,
    by = list(meteo_clim_data$YEAR, meteo_clim_data$MM),
    FUN = sum
  )
} else {
  stop("No data available to aggregate in meteo_clim_data")
}

# Aggregate and prepare rainfall data for dry season months
raindata <- data.frame(year = years)
raindata[, month.abb[4:10]] <- NA

for (yyyy in years) {
  month_data <- rain[rain$Group.1 == yyyy & rain$Group.2 %in% 4:10, 3]
  if (length(month_data) == 7) {
    raindata[raindata$year == yyyy, month.abb[4:10]] <- month_data
  }
}

# Read and process E-flows data
eflows <- read.csv("data/Letaba_eflows_exceedence_m3_per_s.csv", fileEncoding = "UTF-8-BOM")
eflow_exceedance <- eflows[eflows$Exceedence == 80, ]
eflow_per_month <- eflow_exceedance[2:8] * c(30, 31, 30, 31, 31, 30, 31) * 3600 * 24

# Read and process present flow data
present_flows <- read.csv("data/Letaba_modelled_present_flows_m3_per_s.csv", fileEncoding = "UTF-8-BOM")
presentflow_permonth <- data.frame(cbind(
  present_flows[, 1],
  t(t(present_flows[, 2:8]) * c(30, 31, 30, 31, 31, 30, 31) * 3600 * 24)
))
colnames(presentflow_permonth)[1] <- "Year"

# Create Scenarios data frame with only months 4 to 10
scenario_variables <- c(
  paste0("river_flow_", 4:10),
  paste0("ET0_", 4:10),
  paste0("prec_", 4:10),
  paste0("eflow_", 4:10)
)

Scenarios <- data.frame(Variable = scenario_variables, param = "both")

# Populate Scenarios with data for each year and month
for (yyyy in years) {
  Scenarios[, paste0("y_", yyyy)] <- NA
  for (mm in 4:10) {
    et_index <- which(Scenarios$Variable == paste0("ET0_", mm))
    rain_index <- which(Scenarios$Variable == paste0("prec_", mm))
    flow_index <- which(Scenarios$Variable == paste0("river_flow_", mm))
    eflow_index <- which(Scenarios$Variable == paste0("eflow_", mm))
    
    if (length(et_index) > 0) {
      Scenarios[et_index, paste0("y_", yyyy)] <- ETdata[ETdata$year == yyyy, month.abb[mm]]
    }
    if (length(rain_index) > 0) {
      Scenarios[rain_index, paste0("y_", yyyy)] <- raindata[raindata$year == yyyy, month.abb[mm]]
    }
    if (length(flow_index) > 0) {
      Scenarios[flow_index, paste0("y_", yyyy)] <- presentflow_permonth[presentflow_permonth$Year == yyyy, 1 + mm - 3]
    }
    if (length(eflow_index) > 0) {
      Scenarios[eflow_index, paste0("y_", yyyy)] <- eflow_per_month[mm - 3]
    }
  }
}

# Check the output
head(Scenarios)

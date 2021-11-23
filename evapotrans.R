# Evapotranspiration package Hargreaves Samani
library(Evapotranspiration)
data("constants")
data("processeddata")

library(nasapower)
ag_d <- get_power(
  community = "ag",
  lonlat = c(31.08, -23.7),
  pars = c("T2M_MAX","T2M_MIN","PRECTOTCORR"),
  dates = c("1981-01-01","2020-12-31"),
  temporal_api = "daily"
)

colnames(ag_d)[c(3:5,8,9,10)]<-c("Year","Month","Day","Tmax","Tmin","Precipitation")

Inputs<-ReadInputs(c("Tmin","Tmax"),ag_d,stopmissing=c(50,50,50))

ET<-ET.HargreavesSamani(Inputs, constants, ts="daily", message="yes",
                    AdditionalStats="yes", save.csv="no" )

yyyy<-1981
ETdata<-data.frame(year=1981:2021)
ETdata[,month.abb[1:12]]<-NA
for(yyyy in 1981:2020)
  ETdata[which(ETdata$year==yyyy),2:13]<-ET$ET.Monthly[as.character(yyyy+0:11/12)]

rain<-aggregate(ag_d$Precipitation,by=list(ag_d$Year,ag_d$Month),FUN=sum)
raindata<-data.frame(year=1981:2021)
raindata[,month.abb[1:12]]<-NA
for(yyyy in 1981:2020)
  raindata[which(raindata[,1]==yyyy),2:13]<-rain[which(rain[,1]==yyyy),3]



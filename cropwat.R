# thoughts for crop water modeling


# crop water needs, do we need to distinguish between different crops?

library(RMAWGEN)

farmed_area

reference_ET
data("constants")

library(chillR)
station_list<-handle_gsod("list_stations",location=c(lat=-24,long=32))
weather<-handle_gsod("download_weather",location=station_list$chillR_code[5],time_interval = c(2000,2021))
weather_processed<-weather2chillR(weather,drop_most=FALSE)

weather_processed$weather$Tmax<-interpolate_gaps(weather_processed$weather$Tmax)
weather_processed$weather$Tmin<-interpolate_gaps(weather_processed$weather$Tmin)
weather_processed$weather$Prec<-interpolate_gaps(weather_processed$weather$Prec)


ET.PenmanMonteith(list(Tmax=weather_processed$weather$Tmax,
                       Tmin=weather_processed$weather$Tmin,
                       RHmax=c(90,90,90,90),RHmin=c(60,60,60,60),
                       n=c(10,10,8,9),u2=c(1,1,1,1)),constants,wind="no",ts="monthly")

data("processeddata")
data("constants")

data("processeddata")
data("constants")

# Call ET.PenmanMonteith under the generic function ET
results <- ET.PenmanMonteith(processeddata, constants, ts="daily", solar="sunshine hours",
                             wind="yes", crop = "short", message="yes", AdditionalStats="yes", save.csv="no")




# Call ET.PenmanMonteith under the generic function ET
results <- ET.PenmanMonteith(processeddata, constants, ts="daily", solar="sunshine hours",
                             wind="yes", crop = "short", message="yes", AdditionalStats="yes", save.csv="no")


water_need_per_ha



# how much of that rain is actually usable (e.g. doesn't run off)



###########Pull input data###########

# gcc from ecoforecast.org
targets_gcc <- readr::read_csv("https://data.ecoforecast.org/targets/phenology/phenology-targets.csv.gz")

date <- format(max(targets_gcc$time), format = "%m-%d-%y")

write.csv(targets_gcc, 
          paste0("inputs_gcc/targets_gcc_", date, ".csv"), row.names = FALSE)

# weather forecast from NOAA
# If the version of noaa.R has changed and breaks the script, 
# Run git reset --hard 223672814042e652384a89b82d87b040c4763d78 to access the correct version
library(readr)
library(dplyr)
library(udunits2)
library(plantecophys)
source("~/neon4cast/R/noaa.R")

###########Download weather data###########
pheno_sites <- c("BART", "CLBJ", "DELA", "GRSM", 
                 "HARV", "MLBS", "SCBI", "SERC", 
                 "STEI", "UKFS", "CPER", "DSNY",
                 "JORN", "KONZ", "OAES", "WOOD", 
                 "ONAQ", "SRER")
download_noaa(siteID = pheno_sites, interval = "1hr", date = Sys.Date()-1)
noaa_fc <- stack_noaa()

###########Clean up weather data###########
# First, convert units
hourly <- noaa_fc %>% 
  tidyr::drop_na() %>% # the 36th day has NAs, exclude
  rename(radiation = surface_downwelling_shortwave_flux_in_air) %>%
  mutate(airtemp_C = ud.convert(air_temperature, "kelvin", "celsius"),
         precip = ud.convert(precipitation_flux, "s^-1", "d^-1"), #kg per m2 is equivalent to mm
         vpd = RHtoVPD(RH = relative_humidity, TdegC = airtemp_C),
         rad_Mj_hr = ud.convert(radiation*60*60, "joule", "megajoule"),
         date = as.Date(time)) 

# Next, summarize to daily by site and ensemble and drop ens00
daily <- hourly %>%
  group_by(siteID, ensemble, date) %>%
  summarize(radiation = sum(rad_Mj_hr),
            max_temp = max(airtemp_C),
            min_temp = min(airtemp_C),
            precip = max(precip),
            vpd = mean(vpd)) %>%
  ungroup() %>%
  filter(ensemble != "ens00")

###########Save weather csv###########
date <- min(daily$date)
ens <- unique(daily$ensemble)
for(e in ens){
  sub <- filter(daily, ensemble == e)
  write_csv(daily, file = paste0('inputs_weather/NOAA_GEFS_35d_', 
                                 date, '_', e, '.csv'))
}


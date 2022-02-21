###########Read in libraries###########
# devtools::install_github('eco4cast/neon4cast')
# install.packages('readr')
# install.packages('tidync')
# library(neon4cast) <- does not currently work, so clone the repo and source the noaa.R function
# If the version of noaa.R has changed and breaks the script, 
# Run git reset --hard 223672814042e652384a89b82d87b040c4763d78 to access the correct version
library(readr)
library(dplyr)
library(udunits2)
library(plantecophys)
source("~/neon4cast/R/noaa.R")

###########Download weather data###########
pheno_sites <- c("HARV", "BART", "SCBI", "STEI", "UKFS", "GRSM", "DELA", "CLBJ")
download_noaa(siteID = pheno_sites, interval = "1hr", date = Sys.Date() - 1)
noaa_fc <- stack_noaa()

###########Clean up weather data###########
# First, convert units and take median of 31 ensembles
hourly <- noaa_fc %>% 
  tidyr::drop_na() %>% # the 36th day has NAs, exclude
  mutate(airtemp_C = ud.convert(air_temperature, "kelvin", "celsius"),
         precip = ud.convert(precipitation_flux, "s^-1", "d^-1"), #kg per m2 is equivalent to mm
         vpd = RHtoVPD(RH = relative_humidity, TdegC = airtemp_C)) %>%
  group_by(siteID, time) %>%
  summarize(radiation = median(surface_downwelling_shortwave_flux_in_air),
            airtemp_C = median(airtemp_C),
            precip = median(precip),
            vpd = median(vpd),
            rad_Mj_hr = ud.convert(radiation*60*60, "joule", "megajoule")) %>%
  ungroup() %>%
  mutate(date = as.Date(time))

# Then, summarize to daily. Note that precipitation is cumulative, so take max rather than sum
daily <- hourly %>%
  group_by(siteID, date) %>%
  summarize(radiation = sum(rad_Mj_hr),
            max_temp = max(airtemp_C),
            min_temp = min(airtemp_C),
            precip = max(precip),
            vpd = mean(vpd)) %>%
  ungroup()

###########Save weather csv###########
if(!dir.exists('pheno_images/NOAA_forecasts')){
  dir.create('pheno_images/NOAA_forecasts')
}

write_csv(daily, file = paste0('pheno_images/NOAA_forecasts/NOAA_GEFS_35d_', Sys.Date() - 1, '.csv'))

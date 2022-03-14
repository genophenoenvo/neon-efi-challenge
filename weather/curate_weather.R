###########Read in libraries###########
library(daymetr)
library(dplyr)
library(udunits2)
library(plantecophys)

###########Download weather data###########
if(!file.exists("weather/neon_sites.csv")) {
  download.file("https://www.neonscience.org/sites/default/files/NEON_Field_Site_Metadata_20201204.csv", 
                "weather/neon_sites.csv")
}

efi_sites <- read.csv("weather/neon_sites.csv") %>% 
  select(field_site_id, field_latitude, field_longitude) %>% 
  filter(field_site_id %in% c("BART", "CLBJ", "DELA", "GRSM", 
                              "HARV", "MLBS", "SCBI", "SERC", 
                              "STEI", "UKFS", "CPER", "DSNY",
                              "JORN", "KONZ", "OAES", "WOOD", 
                              "ONAQ", "SRER"))

all_daymet <- c()
for(site in 1:nrow(efi_sites)){
  raw_daymet <- download_daymet(site = efi_sites$field_site_id[site], 
                                lat = efi_sites$field_latitude[site], 
                                lon = efi_sites$field_longitude[site], 
                                start = 2016, 
                                end = 2021, 
                                internal = TRUE)
  df_daymet <- as.data.frame(raw_daymet$data) %>% 
    mutate(site = raw_daymet$site)
  all_daymet <- bind_rows(df_daymet, all_daymet)
}

###########Clean up weather data###########
#To calculate daily total shortwaves, multiply srad by daylength and convert to Megajoules m^-2 d^-1
#Additionally, calculate gdd
clean_daymet <- all_daymet %>% 
  mutate(origin_year = year - 1, 
         origin_date = paste0(origin_year, "-12-31"), 
         date = as.Date(yday, origin = origin_date)) %>% 
  rename(siteID = site,
         max_temp = tmax..deg.c.,
         min_temp = tmin..deg.c.,
         precip = prcp..mm.day.) %>%
  relocate(siteID, date) %>%
  mutate(radiation = ud.convert(dayl..s.*srad..W.m.2., "joule", "megajoule"),) %>%
  select(siteID, date, radiation, max_temp, min_temp, precip) %>%
  arrange(siteID)

clean_daymet_gdd <- clean_daymet %>%
  mutate(temp = (min_temp + max_temp) /2,
         temp2 = ifelse(temp > 10, temp, 0),
         year = lubridate::year(date))  %>%
  group_by(siteID, year) %>%
  mutate(gdd = cumsum(temp2)) %>%
  select(siteID, date, radiation, max_temp, min_temp, precip, gdd)

#### Write out only weather data file ####
write.csv(clean_daymet_gdd, file = "weather/Daymet_weather.csv", row.names = F)


###########Join weather data to GCC data###########

targets_gcc <- readr::read_csv("https://data.ecoforecast.org/targets/phenology/phenology-targets.csv.gz") %>%
  mutate(time = as.Date(time)) %>%
  rename(date = time)

gcc_weather <- left_join(targets_gcc, clean_daymet_gdd, 
                         by = c("siteID" = "siteID", "date" = "date"))

write.csv(gcc_weather, "weather/gcc_weather.csv", row.names = FALSE)

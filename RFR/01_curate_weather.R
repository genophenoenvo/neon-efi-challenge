###########Read in libraries###########
library(daymetr)
library(dplyr)

###########Download weather data###########
download.file("https://www.neonscience.org/sites/default/files/NEON_Field_Site_Metadata_20201204.csv", 
              "pheno_images/neon_sites.csv")

efi_sites <- read.csv("pheno_images/neon_sites.csv") %>% 
  select(field_site_id, field_latitude, field_longitude) %>% 
  filter(field_site_id %in% c("HARV", "BART", "SCBI", "STEI", "UKFS", "GRSM", "DELA", "CLBJ"))

all_daymet <- c()
for(site in 1:nrow(efi_sites)){
  raw_daymet <- download_daymet(site = efi_sites$field_site_id[site], 
                                lat = efi_sites$field_latitude[site], 
                                lon = efi_sites$field_longitude[site], 
                                start = 2016, 
                                end = 2020, 
                                internal = TRUE)
  df_daymet <- as.data.frame(raw_daymet$data) %>% 
    mutate(site = raw_daymet$site)
  all_daymet <- bind_rows(df_daymet, all_daymet)
}

###########Clean up weather data###########
clean_daymet <- all_daymet %>% 
  mutate(origin_year = year - 1, 
         origin_date = paste0(origin_year, "-12-31"), 
         date = as.Date(yday, origin = origin_date)) %>% 
  select(-year, -yday, -origin_year, -origin_date)

###########Join weather data to GCC data###########
pheno_images <- read.csv("pheno_images/targets_gcc.csv") %>% 
  mutate(time = as.Date(time))

gcc_weather <- left_join(pheno_images, clean_daymet, 
                         by = c("siteID" = "site", "time" = "date")) %>% 
  rename(daylength = dayl..s., 
         precipitation = prcp..mm.day., 
         radiation = srad..W.m.2., 
         snow_water_equiv = swe..kg.m.2., 
         max_temp = tmax..deg.c., 
         min_temp = tmin..deg.c., 
         vapor_pressure = vp..Pa.)

write.csv(gcc_weather, "pheno_images/gcc_weather.csv", row.names = FALSE)

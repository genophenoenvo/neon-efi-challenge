###########Read in libraries###########
library(neonstore)
library(dplyr)
library(udunits2)
library(plantecophys)

###########Clean weather data###########
forecast_sites <- c("HARV", "BART", "SCBI", "STEI", "UKFS", "GRSM", "DELA", "CLBJ")

# Precipitation
# secPrecipBulk is in mm, which is desired unit
precip_product_id <- "DP1.00006.001"
neon_download(product = precip_product_id, 
              site = forecast_sites, 
              type = "expanded", 
              start_date = "2021-01-01")

precip <- neon_read(table = "SECPRE_30min-expanded", 
                    product = precip_product_id, 
                    site = forecast_sites)

mean_daily_precip <- precip %>% 
  filter(!is.na(secPrecipBulk)) %>% 
  tidyr::separate(startDateTime, c("startDate", "startTime"), sep = " ") %>% 
  group_by(siteID, startDate) %>% 
  summarize(count = n(), daily_precip = sum(secPrecipBulk)) %>% 
  filter(count == 48) %>% 
  select(-count)

# Temperature
# tempRHMean is in celsius, which is desired unit
ht_product_id <- "DP1.00098.001"
neon_download(product = ht_product_id, 
              site = forecast_sites, 
              type = "expanded", 
              start_date = "2021-01-01")

temp <- neon_read(table = "RH_30min-expanded", 
                  product = ht_product_id, 
                  site = forecast_sites)

summary_temp <- temp %>% 
  filter(!is.na(tempRHMean)) %>% 
  filter(horizontalPosition == "000") %>% 
  select(startDateTime, tempRHMean, siteID) %>% 
  tidyr::separate(startDateTime, c("startDate", "startTime"), sep = " ") %>% 
  group_by(siteID, startDate) %>% 
  summarize(count = n(), min_daily_temp = min(tempRHMean), max_daily_temp = max(tempRHMean)) %>% 
  filter(count == 48) %>% 
  select(-count)

# VPD
#RHMean is in % and tempRHMean is in C, which are desired units
summary_vpd <- temp %>% 
  filter(!is.na(RHMean), !is.na(tempRHMean)) %>% 
  filter(horizontalPosition == "000") %>% 
  select(startDateTime, RHMean, tempRHMean, siteID) %>% 
  mutate(vpd = RHtoVPD(RHMean, tempRHMean)) %>% 
  tidyr::separate(startDateTime, c("startDate", "startTime"), sep = " ") %>% 
  group_by(siteID, startDate) %>% 
  summarize(count = n(), mean_daily_vpd = mean(vpd)) %>% 
  filter(count == 48) %>% 
  select(-count)

# Radiation
# inSWMean is in watts/m2, convert to megajoules/day
rad_product_id <- "DP1.00023.001"
neon_download(product = rad_product_id, 
              site = forecast_sites, 
              type = "expanded", 
              start_date = "2021-01-01")

radiation <- neon_read(table = "SLRNR_30min-expanded", 
                       product = rad_product_id, 
                       site = forecast_sites)

summary_radiation <- radiation %>% 
  filter(!is.na(inSWMean)) %>% 
  select(startDateTime, inSWMean, siteID) %>% 
  tidyr::separate(startDateTime, c("startDate", "startTime"), sep = " ") %>% 
  mutate(rad = ud.convert(inSWMean * 30 * 60, "joule", "megajoule")) %>% 
  group_by(siteID, startDate) %>% 
  summarize(count = n(), sum_daily_rad = sum(rad)) %>% 
  filter(count == 48) %>% 
  select(-count)

###########Combine into final csv###########
two_weather_vars <- full_join(mean_daily_precip, summary_temp, 
                              by = c("siteID", "startDate"))

three_weather_vars <- full_join(two_weather_vars, summary_vpd, 
                                by = c("siteID", "startDate"))

four_weather_vars <- full_join(three_weather_vars, summary_radiation, 
                                by = c("siteID", "startDate"))

write.csv(three_weather_vars, "models/weather/efi_forecast_weather_validation.csv", 
          row.names = FALSE)

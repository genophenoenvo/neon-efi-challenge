###########Read in libraries###########
library(neonstore)
library(dplyr)

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

###########Combine into final csv###########
all_weather_vars <- full_join(mean_daily_precip, summary_temp, 
                              by = c("siteID", "startDate"))
write.csv(all_weather_vars, "models/weather/efi_forecast_weather_validation.csv", 
          row.names = FALSE)

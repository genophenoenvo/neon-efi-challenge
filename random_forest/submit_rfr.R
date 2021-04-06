library(readr)
library(tidyr)
library(dplyr)
preds <- readr::read_csv('prediction_interpolation_0325.csv') %>% 
  filter(!time <= Sys.Date()) %>% 
  mutate(forecast = 1, data_assimilation = 0) %>% 
  rename(mean = gcc_90, sd = gcc_sd) %>% 
  pivot_longer(cols = c('mean', 'sd'), names_to = 'statistic', values_to = 'gcc_90')



pred_filename <- paste('phenology', Sys.Date(), 'PEG_RFR.csv', sep = '-')
readr::write_csv(preds, file = pred_filename)
aws.s3::put_object(pred_filename, 
                   bucket = "submissions", 
                   region="data", 
                   base_url = "ecoforecast.org")

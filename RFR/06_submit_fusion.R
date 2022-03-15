.libPaths(c("/home/kristinariemer/r_libs/", .libPaths()))
### Submission script for the Fall 2021 EFI Challenge: Phenology
# remotes::install_github("eco4cast/neon4cast")
# library(neon4cast)
library(readr)
library(tidyr)
library(dplyr)

# loop to read, clean, score, validate, and submit prediction
version <- c("PEG_FUSION_0", "PEG_FUSION_1")


for(v in version){
  if(!dir.exists(paste0(v, '/submissions'))) {
    dir.create(paste0(v, '/submissions'))
  }
  
  # Read in latest date
  out <- list.files(path = paste0("./", v, "/outputs/"))
  dates <- as.Date(stringr::str_extract(out, "[0-9]{2}\\-[0-9]{2}\\-[0-9]{2}"), format = "%m-%d-%y")
  ind <- which.max(dates)
  
  # Clean and format
  if(v == "PEG_FUSION_0"){
    preds <- readr::read_csv(file.path(v, "outputs", out[ind])) %>%
      filter(!time <= Sys.Date()) %>%
      relocate(gcc_sd, rcc_sd, .after = rcc_90) %>%
      pivot_longer(cols = c('gcc_90', 'rcc_90', 'gcc_sd', 'rcc_sd'),
                   names_to = c("variable", "statistic"),
                   names_pattern = "(.*)_(.*)",
                   values_to = 'value') %>%
      mutate(statistic = recode(statistic, `90` = "mean")) %>%
      pivot_wider(names_from = variable, values_from = value) %>%
      rename(gcc_90 = gcc, rcc_90 = rcc)
  } else if(v == "PEG_FUSION_1"){
    preds <- readr::read_csv(file.path(v, "outputs", out[ind])) %>%
      filter(!time <= Sys.Date()) %>%
      mutate(time = as.Date(time, format = "%m/%d/%Y")) %>%
      select(-gcc_sd, -rcc_sd) %>%
      group_by(time, siteID) %>%
      summarize(gcc_mean = mean(gcc_90),
                gcc_sd = sd(gcc_90),
                rcc_mean = mean(rcc_90),
                rcc_sd = sd(rcc_90)) %>%
      pivot_longer(cols = c('gcc_mean', 'gcc_sd', 'rcc_mean', 'rcc_sd'),
                   names_to = c("variable", "statistic"),
                   names_pattern = "(.*)_(.*)",
                   values_to = 'value') %>%
      pivot_wider(names_from = variable, values_from = value) %>%
      rename(gcc_90 = gcc, rcc_90 = rcc)
  }
  
  
  # Score
  # scores <- score(preds, theme = "phenology")
  
  # Write out
  pred_filename <- paste('phenology', Sys.Date(), paste0(v, '.csv'), sep = '-')
  readr::write_csv(preds, file = file.path(".", v, "submissions", pred_filename))
  
  # Validate
  # forecast_output_validator(file.path(".", v, "submit", pred_filename))
  
  # Submit
  aws.s3::put_object(file.path(".", v, "submissions", pred_filename), 
                     bucket = "submissions", 
                     region="data", 
                     base_url = "ecoforecast.org")
}

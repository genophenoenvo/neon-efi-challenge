### Submission script for the Fall 2021 EFI Challenge: Phenology
# remotes::install_github("eco4cast/neon4cast")
# library(neon4cast)
library(readr)
library(tidyr)
library(dplyr)

# loop to read, clean, score, validate, and submit prediction
version <- c("PEG_FUSION_0")
for(v in version){
  # Read in latest date
  out <- list.files(path = paste0("./", v, "/outputs/"))
  dates <- as.Date(stringr::str_extract(out, "[0-9]{2}\\-[0-9]{2}\\-[0-9]{2}"), format = "%m-%d-%y")
  ind <- which.max(dates)
  
  # Clean and format
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

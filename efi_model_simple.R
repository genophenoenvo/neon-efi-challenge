library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)
library(data.table)


file <- 'https://data.ecoforecast.org/targets/phenology/phenology-targets.csv.gz'

gcc_raw <- fread(file)

i <- 1
#for(i in 0){
now <- Sys.Date() + days(i)

this_month <- month(now)
this_day <- day(now)

end <- now + days(180)
end_month <- month(end)
end_day <- day(end)

middle_month <- ifelse(end_month - this_month == 2, this_month + 1, 0)

gcc <- gcc_raw %>% 
  mutate(month = month(time), year = year(time), day = day(time), doy = yday(time))
preds <- data.frame(date = now + days(1:180))


# BEGIN Simple Seasonal + Exponential Smoothing Model
library(forecast)
library(hts)
library(tidyr)
gcc_wide <- gcc %>% 
  select(time, siteID, gcc_90) %>% 
  pivot_wider(id_cols = time, names_from = siteID, values_from = gcc_90)

gcc_ts <- ts(gcc_wide, frequency = 365)

gcc_future <- forecast(gcc_ts, h = 180, level = c(0.3, 0.7))

preds_wide <- gcc_future %>% as.data.frame %>% filter(!Series == 'time') %>% 
  mutate(sd = (`Hi 30` - `Lo 30`)/2) %>% 
  rename(siteID = Series, mean = `Point Forecast`) %>% 
  mutate(time = rep(now + days(1:180), 8)) %>% 
  select(time, siteID, mean, sd)
# END Simple Seasonal + Exponential Smoothing Model

# BEGIN historical mean + window model used through 2021-03-17
# means <- gcc %>% 
#   filter(!is.na(gcc_90) & !is.na(gcc_sd)) %>% 
#   group_by(month, day, siteID) %>% 
#   summarise(n = n(),
#             time =  ymd(paste(2021, sprintf("%02d", month), sprintf("%02d", min(day)), 
#                               sep = '-')),
#             gcc_sd =  median(gcc_sd)*4,
#             gcc_90 =  median(gcc_90)) %>% 
#   select(time, siteID, gcc_90, gcc_sd) %>% 
#   arrange(siteID, time) %>% 
#   unique() %>% 
#   ungroup()
# 
# ## create predictions
# preds_wide <- means %>% 
#   mutate(gcc_90 = frollmean(gcc_90, n = 16, align = 'center', na.rm = TRUE), 
#          gcc_sd = frollmean(gcc_sd*2.5, n = 20, align = 'center', na.rm = TRUE)) %>% 
#   filter((month == this_month & day > this_day) | (month == end_month & day <= end_day  ) | (month > this_month & month < end_month)) %>% 
#   mutate(forecast = 1, data_assimilation = 0, mean = signif(gcc_90, 2), sd = signif(gcc_sd, 1)) %>% 
#   select(time, siteID, forecast, data_assimilation, mean, sd)
# END historical mean + window model

preds <- preds_wide %>%  
  tidyr::pivot_longer(cols = c('mean', 'sd'), names_to = 'statistic', values_to = 'gcc_90')

pred_filename <- paste('phenology', year(now),  sprintf("%02d", this_month),  sprintf("%02d", this_day), 'PEG.csv', sep = '-')
readr::write_csv(preds, file = pred_filename)

## TODO: Add Forecast output validator https://github.com/eco4cast/neon4cast#validate-a-forecast-file

## metadata
## from https://github.com/eco4cast/EFIstandards/blob/master/vignettes/logistic-metadata-example.Rmd
## TODO: Replace w/ helper functions (when available) https://github.com/eco4cast/neon4cast#generate-forecast-metadata-in-eml
library(EML)
library(emld)
emld::eml_version("eml-2.2.0")


template_eml <- EML::read_eml('https://raw.githubusercontent.com/eco4cast/neon4cast-beetles/c7e76a2585c55f6141e4b51a081edee65b8ea82a/meta/eml.xml')

attributes <- tibble::tribble(
  ~attributeName,     ~attributeDefinition,                          ~unit,                  ~formatString, ~numberType, ~definition,
  "time",              "[dimension]{time}",                          "year",                 "YYYY-MM-DD",  "numberType", NA,
  "siteID",            "[dimension]{depth in reservior}",            "dimensionless",         NA,           "character",  NA,
  "gcc_90",            "[observation]{Predicted GCC}",               "proportion",            NA,           "integer",    NA,
  "gcc_sd",            "[process_error]{observation error}",         "proportion",            NA,           "integer",    NA
) 

attributes
attrList <- set_attributes(attributes, 
                           col_classes = c("Date", "character", "numeric","numeric"))

physical <- set_physical(pred_filename,
                         recordDelimiter='\n')

dataTable <- eml$dataTable(
  entityName = "forecast",  
  entityDescription = "Forecast of GCC",
  physical = physical,
  attributeList = attrList)

me <- list(
  individualName = list(givenName = "David", 
                        surName = "LeBauer"),
  electronicMailAddress = "dlebauer@arizona.edu",
  id = "https://orcid.org/0000-0001-7228-053X")


keywordSet <- list(
  list(
    keywordThesaurus = "EFI controlled vocabulary",
    keyword = list("forecast",
                   "phenology",
                   "timeseries")
  ))

abstract_text <- 'a secret way of predicting gcc'

plant_cover <- readr::read_csv('plant_cover/plant_cover.csv')

neon_sites <- c("HARV", "BART", "SCBI", "STEI", "UKFS", "GRSM", "DELA", "CLBJ")
coverage <- 
  set_coverage(begin = now, 
               end = end,
               geographicDescription = paste(c("NEON Sites:", neon_sites), sep = ' ', collapse = ' '),
               west = min(plant_cover$lon), east = max(plant_cover$lon), 
               north = max(plant_cover$lat), south = min(plant_cover$lat)
  )

dataset = eml$dataset(
  title = "PEG phenology prediction",
  creator = me,
  contact = list(references="https://orcid.org/0000-0001-7228-053X"),
  pubDate = Sys.Date(),
  intellectualRights = "http://www.lternet.edu/data/netpolicy.html.",
  abstract =  "A Secret Sauce Prediction",
  dataTable = dataTable,
  keywordSet = keywordSet,
  coverage = coverage
)

forecast_iteration_id = as.numeric(now)
additionalMetadata <- eml$additionalMetadata(
  metadata = list(
    forecast = list(
      ## Basic elements
      timestep = "1 day", ## should be udunits parsable; already in coverage -> temporalCoverage?
      forecast_horizon = "35 days",
      forecast_issue_time = now,
      forecast_iteration_id = forecast_iteration_id,
      forecast_project_id = "PEG",
      metadata_standard_version = "0.3",
      model_description = list(
        forecast_model_id = 'Secret Sauce',
        name = "mean of prev. obs on date + inflated error",
        type = "process-based",
        repository = "https://github.com/genophenoenvo/EFI-phenology"
      ),
      ## MODEL STRUCTURE & UNCERTAINTY CLASSES
      initial_conditions = list(
        # Possible values: absent, present, data_driven, propagates, assimilates
        status = "data_driven",
        # Number of parameters / dimensionality
        complexity = 1  ## [species 1, species 2] per depth
      ),
      drivers = list(
        status = "data_driven"
      ),
      parameters = list(
        status = "present",
        complexity = 1  ## [r, K, alpha] x 2 spp
      ),
      random_effects = list(
        status = "absent"
      ),
      process_error = list(
        status = "absent"
      ),
      obs_error = list(
        status = "absent"
      )
    ) # forecast
  ) # metadata
) # eml$additionalMetadata

my_eml <- eml$eml(dataset = dataset,
                  additionalMetadata = additionalMetadata,
                  packageId = forecast_iteration_id , 
                  system = "datetime"  ## system used to generate packageId
)

eml_validate(my_eml)
meta_data_filename <- gsub(pattern = 'csv', replacement = 'xml', pred_filename)
write_eml(my_eml, meta_data_filename)

## TODO: replace with neon4cast::submit(pred_filename, metadata = meta_data_filename) 
## https://github.com/eco4cast/neon4cast#submit-a-forecast
aws.s3::put_object(pred_filename, 
                   bucket = "submissions", 
                   region="data", 
                   base_url = "ecoforecast.org")
aws.s3::put_object(meta_data_filename, 
                   bucket = "submissions", 
                   region="data", 
                   base_url = "ecoforecast.org")
# need to add line to submit gcc_predictions.R


# set up Cron
# library(cronR)
# f <- 'pheno_images/efi_model_simple.R'
# cmd <- cron_rscript(f)
# cron_add(command = cmd, frequency = 'daily', at='5PM', id = 'gcc_welsch')

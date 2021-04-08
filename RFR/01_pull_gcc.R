###########Pull data from ecoforecast###########

targets_gcc <- readr::read_csv("https://data.ecoforecast.org/targets/phenology/phenology-targets.csv.gz")

date <- format(max(targets_gcc$time), format = "%m-%d-%y")

write.csv(targets_gcc, 
          paste0("inputs/targets_gcc_", date, ".csv"), row.names = FALSE)
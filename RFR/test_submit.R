.libPaths(c("/home/kristinariemer/r_libs/", .libPaths()))
### Submission script for the Fall 2021 EFI Challenge: Phenology
# remotes::install_github("eco4cast/neon4cast")
library(readr)
library(tidyr)
library(dplyr)

# loop to read, clean, score, validate, and submit prediction
version <- c("PEG_FUSION_0", "PEG_FUSION_1")

# Submit
Sys.setenv("AWS_DEFAULT_REGION" = "data",
           "AWS_S3_ENDPOINT" = "ecoforecast.org")

aws.s3::put_object(file = file.path(".", version[1], "submissions", "phenology-2022-05-05-PEG_FUSION_0.csv"),
                   bucket = "submissions")

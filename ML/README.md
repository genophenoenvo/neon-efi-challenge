# Random Forest Regressor

This folder contains the scripts, models, and data needed to forecast phenology (as measured by gcc_90) using machine learning methods for the [NEON Ecological Forecast Challenge](https://ecoforecast.org/efi-rcn-forecast-challenges/). The challenge requires gcc_90 predictions for the next 35 days for 8 NEON sites. Three versions using random forest regressor are used here. 

## Modeling approach
Two models use the previous 5 days gcc value and (t-5) to (t+19)th days' gcc value from last year in order to predict gcc for t to (t+36)th day. 

* `PEG_RFR0/` folder:
  - `models/` site-specific models wherein missing values of gcc_90 have been removed during training
  - `outputs/` daily predictions of the following 35 days of gcc_90 for each site
  - `submissions/` formatted for EFI submission
  
* `PEG_RFR/` folder:
  - `models/` site-specific models wherein missing values of gcc_90 have ____
  - `outputs` daily predictions of the following 35 days of gcc_90 for each site
  - `submissions/` formatted for EFI submission
  
One model uses the (t-7) to (t+7)th days' gcc value from last year and the max_temp, min_temp, radiation, and precipitation of the same day to predict gcc (for 1 day at a time). For past data, weather variables were obtained from [Daymet](https://daymet.ornl.gov/overview). For future predictions, hourly [NOAA weather forecasts](https://www.ncdc.noaa.gov/data-access/model-data/model-datasets/global-ensemble-forecast-system-gefs) were obtained via the EFI website, summarized as the median across 21 model ensembles, and summarized as the mean or sum into daily variables. 

  * `PEG_RFR2/` folder:
    - `models/` site-specific models trained on the full existing dataset
    - `outputs` daily predictions of the following 35 days of gcc_90 for each site
    - `submissions/` formatted for EFI submission
  
## Forecasting pipeline
Our goal is to produce and submit daily forecasts. `forecast_gcc.sh` is a shell script that will run the R and python scripts needed to accomplish this goal. 
1. `01_pull_gcc_weather.R` downloads the latest gcc data and saves the .csv file in the `inputs` folder with the date of the most recent gcc value
2. `02_PEG_RFR0_gcc_predictions.py` ingests the most recent gcc data, gapfills if necessary, runs the 8 site-specific models in `PEG_RFR0/models`, and outputs csv file to `PEG_RFR0/outputs` with the run date
3. `03_PEG_RFR_gcc_predictions_with_interpolation.py` ingests the most recent gcc data, gapfills if necessary, runs the 8 site-specific models in `PEG_RFR/models`, and outputs csv file to `PEG_RFR/outputs` with the run date 
4. `04_PEG_RFR2_gcc_predictions_with_weather_variables.py` ingests the most recent gcc and weather forecast data, runs the 8 site-specific models in `PEG_RFR2/models`, and outputs csv file to `PEG_RFR2/outputs` with the run date
5. `05_submit_rfr.R` takes the latest output from `PEG_RFR0/outputs`, `PEG_RFR/outputs`, and `PEG_RFR2/outputs`, formats for submission, saves into respective `submissions/` folders, and submits to EFI competition website. 

## Forecasting submission

Daily forecasts are submitted automatically once per day using a chron job to run all the forecasting pipeline scripts on a CyVerse OpenStack server. 

Can log into server using `ssh -i [ssh key path] [username]@128.196.65.173`. It contains a copy of this repository, all of the required R and Python packages, and the following chron job: 

```
 SHELL=/bin/bash
 MAILTO=kristinariemer@email.arizona.edu
 00 22 * * * cd /home/kristinariemer/neon-datasets/models/RFR && bash forecast_gcc.sh && echo `date` >> /home/kristinariemer/cron.txt
 ```

Confirmation of submissions are in `cron.txt`. 

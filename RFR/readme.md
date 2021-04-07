# Random Forest Regressor

This folder contains the scripts, models, and data needed to forecast phenology (as measured by gcc_90) using machine learning methods for the [NEON Ecological Forecast Challenge](https://ecoforecast.org/efi-rcn-forecast-challenges/). The challenge requires gcc_90 predictions for the next 35 days for 8 NEON sites. Two versions using random forest regressor are used here. 

## Modeling approach
These models use the previous 5 days gcc value and (t-5) to (t+19)th days' gcc value from last year in order to predict gcc for t to (t+36)th day. 

* `PEG_RFR0/` folder:
  - `models/` site-specific models wherein missing values of gcc_90 have been removed during training
  - `outputs` daily predictions of the following 35 days of gcc_90 for each site
  
* `PEG_RFR/` folder:
  - `models/` site-specific models wherein missing values of gcc_90 have ____
  - `outputs` daily predictions of the following 35 days of gcc_90 for each site
  
## Forecasting pipeline
Our goal is to produce and submit daily forecasts. `forecast_gcc.txt` is a shell script that will run the R and python scripts needed to accomplish this goal. 
1. `01_pull_gcc.R` downloads the latest gcc data and saves the .csv file in the `inputs` folder with the date of the most recent gcc value
2. `02_rfr0.py` ingests the most recent gcc data, gapfills if necessary, runs the 8 site-specific models in `PEG_RFR0/models`, and outputs csv file to `PEG_RFR0/outputs` with the run date
3. `03_rfr.py` ingests the most recent gcc data, gapfills if necessary, runs the 8 site-specific models in `PEG_RFR/models`, and outputs csv file to `PEG_RFR/outputs` with the run date   
4. `04_submit_rfr.R` takes the latest output from `PEG_RFR0/outputs` and `PEG_RFR/outputs`, formats for submission, and submits to EFI competition website. 


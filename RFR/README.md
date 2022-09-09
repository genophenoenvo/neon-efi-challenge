---
editor_options: 
  markdown: 
    wrap: 72
---

# Machine Learning Models

This folder contains the scripts, models, and data needed to forecast
phenology (as measured by gcc_90 and/or rcc_90) using machine learning
models for the [NEON Ecological Forecast
Challenge](https://ecoforecast.org/efi-rcn-forecast-challenges/). The
challenges included: \* <b>Spring 2021</b>: gcc_90 and gcc_sd
predictions for the next 35 days for 8 NEON sites. Three versions using
random forest regression (PEG_RFR0, PEG_RFR, PEG_RFR2) were submitted.

-   <b>Fall 2021:</b> gcc_90, gcc_sd, rcc_90, rcc_sd predictions for the
    next 35 days for 8 NEON sites. Continued submissions of the previous
    three versions of models using Random Forest Regressor for gcc_90
    and gcc_sd, and developed a new model incorporating an ensemble ML
    approach (PEG_FUSION_0) to predict gcc_90, gcc_sd, rcc_90 and
    rcc_sd.

-   <b>Spring 2022:</b> gcc_90, gcc_sd, rcc_90, rcc_sd predictions for
    the next 35 days for 18 NEON sites. Continued submission of
    PEG_FUSION_0 from the previous season after extending it to 18 sites
    and developed a new idea using identical PEG_FUSION_0 models and
    submitted a new forecast (PEG_FUSION_1).

## Modeling approach

### Spring 2021

The following models predict gcc_90 of next 35 days. For gcc_sd, last
years' gcc_sd value was submitted as forecast for current year.

-   <b>PEG_RFR0 (Prediction based on immediate past gcc_90 and last year
    gcc_90 values):</b>

    -   <b>Input:</b> gcc_90 values of immediate past (last 5 days) and
        gcc_90 values from the last year (25 days), i.e., to predict t
        to (t+35) days of gcc_90, we used gcc_90 value from (t-1)th to
        (t-5)th day and gcc_90 value from (t-5)th to (t+19)th day of
        last year

    -   <b>Output:</b> gcc_90 of total 36 days i.e., t to (t+35) days

    -   <b>Model Description:</b> Random Forest Regressor is trained
        individually for each of the sites to predict gcc_90 using
        3-fold cross-validation after dropping all the missing values of
        past gcc_90 while training.

    The folder structure of PEG_RFR0 is given below:

    -   `models/` site-specific models wherein missing values of gcc_90
        have been removed during training

-   <b>PEG_RFR (Prediction based on immediate past gcc_90 and last year
    gcc_90 using interpolation):</b>

    -   <b>Input:</b> gcc_90 values of immediate past (last 5 days) as
        well as gcc_90 values from the last year (20 days), i.e., to
        predict t to (t+35) days of gcc_90, we used gcc_90 value from
        (t-1)th to (t-5)th day and gcc_90 value from (t-5)th to (t+14)th
        day of last year

    -   <b>Output:</b> gcc_90 of total 36 days i.e., t to (t+35) days

    -   <b>Model Description:</b> Random Forest Regressor is trained
        individually for each of the sites to predict gcc_90 using
        3-fold cross-validation after using linear interpolation
        strategy to fill in all the missing values of past gcc_90.

    The folder structure of PEG_RFR/ is given below:

    -   `models/` site-specific models wherein missing values of gcc_90
        have

-   <b>PEG_RFR2 (Prediction based on last year gcc_90 values and current
    weather data):</b>

    -   <b>Input:</b> gcc_90 values from the last year (15 days) and
        current weather data, i.e., to predict gcc_90 value of tth day,
        we use (t-7)th to (t+7)th days' gcc_90 values from last year and
        weather variables (max_temp, min_temp, radiation, precipitation)
        of tth day. Weather data extracted from Daymet is used to train
        the model. To forecast gcc_90 for future days, NOAA forecasted
        weather parameters are being used.

    -   <b>Output:</b> gcc_90 of next 35 days i.e., (t+1) to (t+35) days

    -   <b>Model Description:</b> Random Forest Regressor is trained
        individually for each of the sites to predict gcc_90 using
        3-fold cross-validation after dropping all the missing values of
        input parameters.

    The folder structure of `PEG_RFR2/` is given below:

    -   `models/` site-specific models trained on the full existing
        dataset

<b>Notes:</b>:

-   Since gcc_90 is not getting updated daily, the models using
    immediate past gcc_90 values (PEG_RFR0 and PEG_RFR) use forward fill
    strategy to fill in immediate past gcc_90 values while submitting
    the forecast for next 35 days
-   Forecasted weather parameters used for submission of forecast for
    next 35 days are the median of 30 forecasted ensenle weather
    parameter files extrated from NOAA.

### Fall 2021

-   <b>PEG_FUSION_0 (Prediction based on last year gcc_90 values and
    current weather data using ensemble approach):</b>

    -   <b>Input:</b> gcc_90/rcc_90 data of 20 days from last year i.e.,
        (t-10)th to (t+9)th day of last year and weather variables of
        tth day (Max. temp, Min. temp, Radiation, Precipitation).
        Weather data extracted from Daymet is used to train the model.
        To forecast gcc_90 for future days, NOAA forecasted weather
        parameters are being used.

    -   <b>Output:</b> gcc_90/rcc_90 of next 35 days

    -   <b>Model Description:</b> Ensemble machine learning approach is
        taken to predict gcc90/rcc_90, as part of which four models
        (Random Forest Regressor (RFR), ElasticNet Regressor, Extreme
        Gradient Boosting (XgBoost), K-Nearest Neighbor Regressor (KNN))
        are trained individually for each of the sites to predict rcc_90
        and three models (Random Forest Regressor (RFR), ElasticNet
        Regressor, Extreme Gradient Boosting (XgBoost)) are trained
        individually for each of the sites to predict gcc_90. Finally,
        rcc_90 and rcc_sd is predicted by taking the average and
        standard deviation of the predicted outputs by the four models
        and gcc_90 and gcc_sd are predicted by taking the average and
        standard deviation of the predicted outputs by the three models.

    The folder structure of PEG_FUSION_0 is given below:

    -   `models/` site-specific models wherein missing values of gcc_90
        have been removed during training
    -   `outputs/` daily predictions of the following 35 days of gcc_90
        for each site
    -   `submissions/` formatted for EFI submission

### Spring 2022

-   <b>PEG_FUSION_1 (Prediction based on last year gcc_90 values and
    current weather data):</b> Herein, we use identical models developed
    as part of PEG_FUSION_0, however, the forecast of gcc_90, rcc_90,
    gcc_sd and rcc_sd were submitted by predicting the values
    individually from 30 forecasted weather parameter files

## Forecasting pipeline

Our goal is to produce and submit daily forecasts. `forecast_gcc.sh` is
a shell script that will run the R and python scripts needed to
accomplish this goal. 

1. `01_pull_gcc_weather.R` downloads the latest
gcc data and saves the .csv file in the `inputs` folder with the date of
the most recent gcc value 
2. `02_PEG_RFR0_gcc_predictions.py` ingests
the most recent gcc data, gapfills if necessary, runs the 8
site-specific models in `PEG_RFR0/models`, and outputs csv file to
`PEG_RFR0/outputs` with the run date 
3.
`03_PEG_RFR_gcc_predictions_with_interpolation.py` ingests the most
recent gcc data, gapfills if necessary, runs the 8 site-specific models
in `PEG_RFR/models`, and outputs csv file to `PEG_RFR/outputs` with the
run date 
4. `04_PEG_RFR2_gcc_predictions_with_weather_variables.py`
ingests the most recent gcc and weather forecast data, runs the 8
site-specific models in `PEG_RFR2/models`, and outputs csv file to
`PEG_RFR2/outputs` with the run date 
5. `05_submit_rfr.R` takes the
latest output from `PEG_RFR0/outputs`, `PEG_RFR/outputs`, and
`PEG_RFR2/outputs`, formats for submission, saves into respective
`submissions/` folders, and submits to EFI competition website.

## Forecasting submission

Daily forecasts are submitted automatically once per day using a chron
job to run all the forecasting pipeline scripts on a CyVerse OpenStack
server.

Can log into server using
`ssh -i [ssh key path] [username]@128.196.65.173`. It contains a copy of
this repository, all of the required R and Python packages, and the
following chron job:

     SHELL=/bin/bash
     MAILTO=kristinariemer@email.arizona.edu
     00 22 * * * cd /home/kristinariemer/neon-datasets/models/RFR && bash forecast_gcc.sh && echo `date` >> /home/kristinariemer/cron.txt

Confirmation of submissions are in `cron.txt`.

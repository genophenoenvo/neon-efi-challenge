## Models for EFI Challenge


### Background

- EFI videos 
  - EFI Challenge overview https://youtu.be/deWuTLGspJg
  - Infrastructure https://youtu.be/-tH4dG3yO3U
  - NEON data streams https://youtu.be/3viG7QNGvK8
- the phenomics section of https://ecoforecast.org/efi-rcn-forecast-challenges/, 
- challenge description https://docs.google.com/document/d/1IulWHTRNS2u8rb3cQMaGg4cI11sdOUNZGOr0NFVWnMQ/edit
- the two Richardson et al papers
  - Richardson et al 2018 Nature Scientific Data https://doi.org/10.1038/sdata.2018.28
  - Richardson et al 2019 New Phytologist https://doi.org/10.1111/nph.15591

### Contents

#### Simple (Team PEG)

Lead: David LeBauer

Primary aim is to work out the mechanisms of the forecast challenge - and if a simple seasonal forecast wins the yipee!

- `models/simple`
  - `ets_forecast.R`
An exponential smoothing model with seasonality using the `forecast` package in R. 

TODO: separate out interpolation code and model from notebook into python script(s) that can be run each day

https://otexts.com/fpp3/holt-winters.html

### Random Forest Regressor without Interpolation (Team PEG_RFR0)

todo

### Random Forest Regressor with Interpolation (Team PEG_RFR)

Leads: Arun Ross and Debashmita Pal

- `/models/random_forest/`
  - `gcc_predictions_model_interpolating_missing_data.ipynb` generates predictions
  - `submit_rfr.R` submits output of interpolation code

TODO: separate out data download and submission from model



### Another

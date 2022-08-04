# Models for EFI Challenge

The [GenoPhenoEnvo team](https://genophenoenvo.github.io/) submitted machine learning models to predict GCC and RCC to the [EFI Spring 2021 and Fall 2021 Challenge](https://ecoforecast.org/efi-rcn-forecast-challenges/). 

## Background

- EFI videos 
  - EFI Challenge overview: https://youtu.be/deWuTLGspJg
  - Infrastructure: https://youtu.be/-tH4dG3yO3U
  - NEON data streams: https://youtu.be/3viG7QNGvK8
- Phenomics section of https://ecoforecast.org/efi-rcn-forecast-challenges/, 
- challenge description https://docs.google.com/document/d/1IulWHTRNS2u8rb3cQMaGg4cI11sdOUNZGOr0NFVWnMQ/edit
- Richardson et al. papers
  - Richardson et al. 2018 Nature Scientific Data: https://doi.org/10.1038/sdata.2018.28
  - Richardson et al. 2019 New Phytologist: https://doi.org/10.1111/nph.15591

## Folder Contents

### Simple Model (Team PEG)

Lead: David LeBauer

Primary aim is to work out the mechanisms of the forecast challenge - and if a simple seasonal forecast wins then yipee!

- `simple`folder
  - `ets_forecast.R`
An exponential smoothing model with seasonality using the `forecast` package in R. 

#### TODO

- separate out interpolation code and model from notebook into python script(s) that can be run each day
- implement [Holts-Winter seasonality model](https://otexts.com/fpp3/holt-winters.html)
- get EML metadata working

### Machine Learning Models (Team PEG_RFR, PEG_FUSION)

Leads: Arun Ross and Debashmita Pal

- `ML` folder
  - See details in that folder's README

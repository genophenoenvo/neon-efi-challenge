# PEG Models used in the EFI-NEON Forecasting Challenge

The [GenoPhenoEnvo team](https://genophenoenvo.github.io/) submitted forecasts of forest phenology inferred from webcams to the [EFI Spring 2021, Fall 2021, and Spring 2022 Challenge](https://ecoforecast.org/efi-rcn-forecast-challenges/)s. Results for submitted forecasts can be viewed on the EFI-NEON Ecological Forecasting Challenge Dashboard, [here](https://shiny3.ecoforecast.org/), where you can explore results such as:

![Screenshot of the EFI Forecasting Challenge Results showing forecasts from models in this repository.](figures/efi_results_image.jpeg)

## Background

> "The Ecological Forecasting Initiative is a grassroots consortium aimed at building and supporting an interdisciplinary community of practice around near-term (daily to decadal) ecological forecasts." - [ecoforecast.org/about](https://ecoforecast.org/about/){.uri}

The EFI-NEON Forecasting Challenge

> The National Science Foundation funded Ecological Forecasting Initiative Research Coordination Network (EFI-RCN) is hosting a NEON Ecological Forecast Challenge with the goal to create a community of practice that builds capacity for ecological forecasting by leveraging NEON data products. - [projects.ecoforecast.org/neon4cast-docs](https://projects.ecoforecast.org/neon4cast-docs)

This repository contains models used in the Phenology challenge, described in more detail the "Phenology" chapter of the [EFI-NEON Ecological Forecasting Challenge documentation](https://projects.ecoforecast.org/neon4cast-docs/Phenology.html).

EFI and the Phenology challenge are best described in the links above. In addition, you may be interested in the following resources:

-   The EFI [YouTube channel](https://www.youtube.com/channel/UCZ2KQdo1-FhNRtEBYxai5Aw), including the [Phenology challenge description](https://youtu.be/deWuTLGspJg) and an [overview of NEON data streams](https://youtu.be/3viG7QNGvK8).

-   Publications by Andrew Richardson et al. on the phenocams:

    -   Richardson, A., Hufkens, K., Milliman, T. et al. Tracking vegetation phenology across diverse North American biomes using PhenoCam imagery. Sci Data 5, 180028 (2018). <https://doi.org/10.1038/sdata.2018.28>

    -   Richardson, A.D. (2019), Tracking seasonal rhythms of plants in diverse ecosystems with digital camera imagery. New Phytol, 222: 1742-1750. <https://doi.org/10.1111/nph.15591>

## Repository Contents

### A Simple Model (PEG)

Lead: David LeBauer

The original aim of having a 'simple model' was work out the mechanisms of the forecast challenge. Although it started as a 'simple' predictions, we later implemented an seasonal plus exponential smoothing model using the R forecast package.

-   `simple`folder:
    -   `ets_forecast.R` An exponential smoothing model with seasonality using the `forecast` package in R. The original moving window model is in the comments

#### Ideas for future improvement / additional models

-   [Holts-Winter seasonality model](https://otexts.com/fpp3/holt-winters.html)
-   Use the `forecast::auto.arima` function to fit ARIMA parameters.

### Machine Learning Models (Team PEG_RFR, PEG_FUSION)

Leads: Arun Ross and Debashmita Pal

-   `ML` folder
    -   See details in that folder's [README](https://github.com/genophenoenvo/neon-efi-challenge/tree/master/ML/#machine-learning-models)

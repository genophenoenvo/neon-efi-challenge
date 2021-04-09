#!/bin/bash

Rscript 01_pull_gcc.R
python3 02_PEG_RFR0_gcc_predictions.py
python3 03_PEG_RFR_gcc_predictions_with_interpolation.py
Rscript 04_submit_rfr.R
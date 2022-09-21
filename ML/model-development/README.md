# Machine Learning Model Development

This folder contains the python notebooks (.ipynb) for each of the models (PEG_RFR0, PEG_RFR, PEG_RFR2, PEG_FUSION_0) sumitted as part of the challenge, and a corresponding pdf file containing all the plots. The notebooks primarily contain the following sections:

  <b>1. Data Preparation:</b> Includes the feature creation to train the model and pre-processing of the data
  
  <b>2. Training:</b> Train the model for each of the sites individually as per the proposed approach. Initially, the training is done for all the sites except UKFS, as sufficient data is not available for the split of train data and test data. Later, UKFS is trained with all the available data without testing.  
  
  <b>3. Performance Evaluation:</b> Performance of the trained models are evaluated on test dataset, and different plots have been created to demonstrate the performance. All the plots are saved in a pdf file.
  
  <b>4. Saving the model:</b> Save the trained models as .pkl file to use it for submission of the forecasts.


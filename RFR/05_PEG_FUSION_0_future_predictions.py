import pandas as pd
from datetime import date
import pickle
import glob
import os
import numpy as np

# Getting current working directory
dirname = os.path.abspath(os.getcwd())

# Getting latest phenology from 'inputs_gss' folder
inputs_path = os.path.join(dirname, 'inputs_gcc')
file_type = '/*csv'
files = glob.glob(inputs_path + file_type)
latest_file = max(files, key=os.path.getctime)
dataset = pd.read_csv(latest_file)

# Getting latest forecasted weather parameters from 'inputs_weather' folder
forecasted_weather_path = os.path.join(dirname, 'inputs_weather')
file_type = '/*csv'
forecasted_weather_files = glob.glob(forecasted_weather_path + file_type)
latest_forecasted_weather_file = max(forecasted_weather_files, key=os.path.getctime)

forecasted_weather_data = pd.read_csv(latest_forecasted_weather_file)

dataset['time'] = pd.to_datetime(dataset['time'])
forecasted_weather_data['date'] = pd.to_datetime(forecasted_weather_data['date'])
forecasted_weather_data = forecasted_weather_data.rename(columns={"date":"time"})

# Merging phenology and forecasted weather data
phenology_forecasted_weather_data = pd.merge(left = dataset, right = forecasted_weather_data, how='outer', left_on=['time','siteID'], right_on=['time','siteID'])

# Creating columns year, month, day and setting the time as index to use 'shift' funtion() 
phenology_forecasted_weather_data['year'] = pd.DatetimeIndex(phenology_forecasted_weather_data['time']).year
phenology_forecasted_weather_data['month'] = pd.DatetimeIndex(phenology_forecasted_weather_data['time']).month
phenology_forecasted_weather_data['day'] = pd.DatetimeIndex(phenology_forecasted_weather_data['time']).day
phenology_forecasted_weather_data['year_month']= phenology_forecasted_weather_data['year'].map(str) + "-" + phenology_forecasted_weather_data['month'].map(str)

phenology_forecasted_weather_data = phenology_forecasted_weather_data.set_index("time")

# Storing the sites in a list object
site_list = phenology_forecasted_weather_data["siteID"].unique()
num_sites = len(site_list)
# Breaking the data site-wise into separate dataframes
future_pred_site_wise = phenology_forecasted_weather_data.groupby("siteID")
future_pred_df_gcc = []
future_pred_df_rcc = []
for k in range(0,num_sites):
    future_pred_df_gcc.append(future_pred_site_wise.get_group(site_list[k]))
    future_pred_df_rcc.append(future_pred_site_wise.get_group(site_list[k]))

input_features_gcc = ['radiation', 'max_temp', 'min_temp', 'precip']
input_features_rcc = ['radiation', 'max_temp', 'min_temp', 'precip']

todays_date = pd.Timestamp(date.today())

# Creating the gcc related features using 'shift' funtion() and keep only the records required for predictions  
for k in range(0,num_sites):    
    for i in range(1,11):     #Creating features columns for last 10 days from last year
        col_name_last_year = "last_year_gcc_90_(t-"+str(i)+")"
        future_pred_df_gcc[k].loc[:,col_name_last_year] = future_pred_df_gcc[k].loc[:,"gcc_90"].shift(i+365)
        future_pred_df_gcc[k].loc[:,col_name_last_year] = future_pred_df_gcc[k].loc[:,col_name_last_year].fillna(future_pred_df_gcc[k].loc[:,"gcc_90"].shift(i+365*2))
        future_pred_df_gcc[k].loc[:,col_name_last_year] = future_pred_df_gcc[k].loc[:,col_name_last_year].fillna(future_pred_df_gcc[k].loc[:,"gcc_90"].shift(i+365*3))
        future_pred_df_gcc[k].loc[:,col_name_last_year] = future_pred_df_gcc[k].loc[:,col_name_last_year].ffill(axis=0)
        if(k == 0):
            input_features_gcc.append(col_name_last_year)

    for i in range(0,10):     #Creating features columns for t to (t+9) days from last year
        col_name_last_year_ahead = "last_year_gcc_90_(t+"+str(i)+")"
        future_pred_df_gcc[k].loc[:,col_name_last_year_ahead] = future_pred_df_gcc[k].loc[:,"gcc_90"].shift(365-i)
        future_pred_df_gcc[k].loc[:,col_name_last_year_ahead] = future_pred_df_gcc[k].loc[:,col_name_last_year_ahead].fillna(future_pred_df_gcc[k].loc[:,"gcc_90"].shift(365*2-i))
        future_pred_df_gcc[k].loc[:,col_name_last_year_ahead] = future_pred_df_gcc[k].loc[:,col_name_last_year_ahead].fillna(future_pred_df_gcc[k].loc[:,"gcc_90"].shift(365*3-i))
        future_pred_df_gcc[k].loc[:,col_name_last_year_ahead] = future_pred_df_gcc[k].loc[:,col_name_last_year_ahead].ffill(axis=0)
        if(k == 0):
            input_features_gcc.append(col_name_last_year_ahead)

    future_pred_df_gcc[k].reset_index(inplace=True)
    future_pred_df_gcc[k] = future_pred_df_gcc[k].loc[future_pred_df_gcc[k]["time"] >= todays_date]    
    future_pred_df_gcc[k].dropna(subset = input_features_gcc, inplace = True)
    future_pred_df_gcc[k].set_index("time", inplace = True, drop = True)
    future_pred_df_gcc[k] = future_pred_df_gcc[k][future_pred_df_gcc[k].columns.intersection(input_features_gcc)] 

# Creating the rcc related features using 'shift' funtion() and keep only the records required for predictions
for k in range(0,num_sites):    
    for i in range(1,11):     #Creating features columns for last 10 days from last year
        col_name_last_year = "last_year_rcc_90_(t-"+str(i)+")"
        future_pred_df_rcc[k].loc[:,col_name_last_year] = future_pred_df_rcc[k].loc[:,"rcc_90"].shift(i+365)
        future_pred_df_rcc[k].loc[:,col_name_last_year] = future_pred_df_rcc[k].loc[:,col_name_last_year].fillna(future_pred_df_rcc[k].loc[:,"rcc_90"].shift(i+365*2))
        future_pred_df_rcc[k].loc[:,col_name_last_year] = future_pred_df_rcc[k].loc[:,col_name_last_year].fillna(future_pred_df_rcc[k].loc[:,"rcc_90"].shift(i+365*3))
        future_pred_df_rcc[k].loc[:,col_name_last_year] = future_pred_df_rcc[k].loc[:,col_name_last_year].ffill(axis=0)
        if(k == 0):
            input_features_rcc.append(col_name_last_year)

    for i in range(0,10):     #Creating features columns for t to (t+9) days from last year
        col_name_last_year_ahead = "last_year_rcc_90_(t+"+str(i)+")"
        future_pred_df_rcc[k].loc[:,col_name_last_year_ahead] = future_pred_df_rcc[k].loc[:,"rcc_90"].shift(365-i)
        future_pred_df_rcc[k].loc[:,col_name_last_year_ahead] = future_pred_df_rcc[k].loc[:,col_name_last_year_ahead].fillna(future_pred_df_rcc[k].loc[:,"rcc_90"].shift(365*2-i))
        future_pred_df_rcc[k].loc[:,col_name_last_year_ahead] = future_pred_df_rcc[k].loc[:,col_name_last_year_ahead].fillna(future_pred_df_rcc[k].loc[:,"rcc_90"].shift(365*3-i))
        future_pred_df_rcc[k].loc[:,col_name_last_year_ahead] = future_pred_df_rcc[k].loc[:,col_name_last_year_ahead].ffill(axis=0)
        if(k == 0):
            input_features_rcc.append(col_name_last_year_ahead)

    future_pred_df_rcc[k].reset_index(inplace=True)
    future_pred_df_rcc[k] = future_pred_df_rcc[k].loc[future_pred_df_rcc[k]["time"] >= todays_date]    
    future_pred_df_rcc[k].dropna(subset = input_features_rcc, inplace = True)
    future_pred_df_rcc[k].set_index("time", inplace = True, drop = True)
    future_pred_df_rcc[k] = future_pred_df_rcc[k][future_pred_df_rcc[k].columns.intersection(input_features_rcc)] 


# Predicting gcc_90, gcc_sd, rcc_90 and rcc_sd value
future_predictions = pd.DataFrame(columns = ['time', 'siteID', 'gcc_90', 'gcc_sd', 'rcc_90', 'rcc_sd'])
models_path = os.path.join(dirname, 'PEG_FUSION_0', 'models/')


for k in range(0,num_sites):
    gcc_pred = [] 
    RFR_model = pickle.load(open(models_path + "PEG_FUSION_0_gcc_model_RFR_"+site_list[k]+".pkl",'rb'))
    gcc_pred.append(RFR_model.predict(future_pred_df_gcc[k]))

    ElasticNet_model = pickle.load(open(models_path + "PEG_FUSION_0_gcc_model_ElasticNet_"+site_list[k]+".pkl",'rb'))
    gcc_pred.append(ElasticNet_model.predict(future_pred_df_gcc[k]))

    XGB_model = pickle.load(open(models_path + "PEG_FUSION_0_gcc_model_XGB_"+site_list[k]+".pkl",'rb'))
    gcc_pred.append(XGB_model.predict(future_pred_df_gcc[k]))
    
    predicted_gcc_90 = np.array(gcc_pred).mean(axis = 0)
    predicted_gcc_sd = np.array(gcc_pred).std(axis = 0)

    rcc_pred = []
    RFR_model = pickle.load(open(models_path + "PEG_FUSION_0_rcc_model_RFR_"+site_list[k]+".pkl",'rb'))
    rcc_pred.append(RFR_model.predict(future_pred_df_gcc[k]))

    ElasticNet_model = pickle.load(open(models_path + "PEG_FUSION_0_rcc_model_ElasticNet_"+site_list[k]+".pkl",'rb'))
    rcc_pred.append(ElasticNet_model.predict(future_pred_df_gcc[k]))

    XGB_model = pickle.load(open(models_path + "PEG_FUSION_0_rcc_model_XGB_"+site_list[k]+".pkl",'rb'))
    rcc_pred.append(XGB_model.predict(future_pred_df_gcc[k]))
    
    KNN_model = pickle.load(open(models_path + "PEG_FUSION_0_rcc_model_KNN_"+site_list[k]+".pkl",'rb'))
    rcc_pred.append(KNN_model.predict(future_pred_df_gcc[k]))

    predicted_rcc_90 = np.array(rcc_pred).mean(axis = 0)
    predicted_rcc_sd = np.array(rcc_pred).std(axis = 0)
    
    
    future_predictions = future_predictions.append(pd.DataFrame({'time': pd.Series(future_pred_df_gcc[k].index), 
                                                  'siteID': site_list[k],
                                                  'gcc_90': pd.Series(predicted_gcc_90),
                                                  'gcc_sd': pd.Series(predicted_gcc_sd),
                                                  'rcc_90': pd.Series(predicted_rcc_90),
                                                  'rcc_sd': pd.Series(predicted_rcc_sd)
                                                        }))


# Generating output csv files with predictions
outputs_path = os.path.join(dirname, 'PEG_FUSION_0', 'outputs/')
output_file_name= "PEG_FUSION_0_predictions_" + str(date.today().strftime("%m-%d-%y"))+ ".csv"
future_predictions.to_csv(outputs_path + output_file_name, index=False, header = True)

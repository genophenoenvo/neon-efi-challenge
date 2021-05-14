import pandas as pd
from datetime import date
import pickle
import glob
import os

# Getting current working directory
dirname = os.path.abspath(os.getcwd())

# Getting latest targets_gcc.csv file from 'inputs_gcc' folder
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
forecasted_weather_data.columns = ['siteID', 'time', 'radiation', 'max_temp', 'min_temp', 'precip', 'vpd']

# Merging gcc and forecasted weather data
gcc_forecasted_weather_data = pd.merge(left = dataset, right = forecasted_weather_data, how='outer', left_on=['time','siteID'], right_on=['time','siteID'])

# Creating columns year, month, day and setting the time as index to use 'shift' funtion() 
gcc_forecasted_weather_data['time'] = pd.to_datetime(gcc_forecasted_weather_data['time'])
gcc_forecasted_weather_data['year'] = pd.DatetimeIndex(gcc_forecasted_weather_data['time']).year
gcc_forecasted_weather_data['month'] = pd.DatetimeIndex(gcc_forecasted_weather_data['time']).month
gcc_forecasted_weather_data['day'] = pd.DatetimeIndex(gcc_forecasted_weather_data['time']).day
gcc_forecasted_weather_data['year_month']= gcc_forecasted_weather_data['year'].map(str) + "-" + gcc_forecasted_weather_data['month'].map(str)
gcc_forecasted_weather_data = gcc_forecasted_weather_data.set_index("time")

# Storing the sites in a list object
site_list = gcc_forecasted_weather_data["siteID"].unique()

# Breaking the data site-wise into separate dataframes
future_pred_site_wise = gcc_forecasted_weather_data.groupby("siteID")
future_pred_df = []
for k in range(0,8):
    future_pred_df.append(future_pred_site_wise.get_group(site_list[k]))

input_features = ['radiation', 'max_temp', 'min_temp', 'precip']

# Creating the gcc related features using 'shift' funtion() and keep only the records required for predictions
todays_date = pd.Timestamp("2021-04-21")  # date.today()
for k in range(0,8):    
    for i in range(1,8):     #Creating features columns for last 7 days from last year
        col_name_last_year = "last_year_gcc_90_(t-"+str(i)+")"
        future_pred_df[k].loc[:,col_name_last_year] = future_pred_df[k].loc[:,"gcc_90"].shift(i+365)
        future_pred_df[k].loc[:,col_name_last_year] = future_pred_df[k].loc[:,col_name_last_year].fillna(future_pred_df[k].loc[:,"gcc_90"].shift(i+365*2))
        future_pred_df[k].loc[:,col_name_last_year] = future_pred_df[k].loc[:,col_name_last_year].fillna(future_pred_df[k].loc[:,"gcc_90"].shift(i+365*3))
        future_pred_df[k].loc[:,col_name_last_year] = future_pred_df[k].loc[:,col_name_last_year].ffill(axis=0)
        if(k == 0):
            input_features.append(col_name_last_year)

    for i in range(0,8):     #Creating features columns for t to (t+7) days from last year
        col_name_last_year_ahead = "last_year_gcc_90_(t+"+str(i)+")"
        future_pred_df[k].loc[:,col_name_last_year_ahead] = future_pred_df[k].loc[:,"gcc_90"].shift(365-i)
        future_pred_df[k].loc[:,col_name_last_year_ahead] = future_pred_df[k].loc[:,col_name_last_year_ahead].fillna(future_pred_df[k].loc[:,"gcc_90"].shift(365*2-i))
        future_pred_df[k].loc[:,col_name_last_year_ahead] = future_pred_df[k].loc[:,col_name_last_year_ahead].fillna(future_pred_df[k].loc[:,"gcc_90"].shift(365*3-i))
        future_pred_df[k].loc[:,col_name_last_year_ahead] = future_pred_df[k].loc[:,col_name_last_year_ahead].ffill(axis=0)
        if(k == 0):
            input_features.append(col_name_last_year_ahead)

    future_pred_df[k].reset_index(inplace=True)
    future_pred_df[k] = future_pred_df[k].loc[future_pred_df[k]["time"] >= todays_date]    
    future_pred_df[k].dropna(subset = input_features, inplace = True)
    future_pred_df[k].set_index("time", inplace = True, drop = True)
    future_pred_df[k] = future_pred_df[k][future_pred_df[k].columns.intersection(input_features)] 



# Predicting gcc_90 value
future_predictions = pd.DataFrame(columns = ['time', 'siteID', 'gcc_90'])
models_path = os.path.join(dirname, 'PEG_RFR2', 'models/')

for k in range(0,8):
    file_name = "model_"+site_list[k]+".pkl"
    model = pickle.load(open(models_path + file_name,'rb'))
    pred = model.predict(future_pred_df[k])
    
    future_predictions = future_predictions.append(pd.DataFrame({'time': pd.Series(future_pred_df[k].index), 
                                                  'siteID': site_list[k],
                                                  'gcc_90': pd.Series(pred)
                                                        }))

# Adding gcc_sd from last year data
last_year_df = gcc_forecasted_weather_data[gcc_forecasted_weather_data.columns.intersection(['siteID', 'gcc_sd'])].loc['2020',:].reset_index()
last_year_df['time'] = last_year_df['time'].mask(last_year_df['time'].dt.year == 2020, 
                             last_year_df['time'] + pd.offsets.DateOffset(year=2021))
last_year_df = last_year_df.ffill(axis=0)

# Generating output csv files with predictions
outputs_path = os.path.join(dirname, 'PEG_RFR2', 'outputs/')
output_file_name= "PEG_RFR2_predictions_" + str(date.today().strftime("%m-%d-%y"))+ ".csv"
final_output = pd.merge(left = future_predictions, right = last_year_df, how='left', left_on=['time','siteID'], right_on=['time','siteID'])
final_output.to_csv(outputs_path + output_file_name, index=False, header = True)

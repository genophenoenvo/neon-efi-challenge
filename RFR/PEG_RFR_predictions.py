import pandas as pd
from datetime import date
import datetime
import pickle

# Importing the dataset gcc_weather.csv
url = "https://raw.githubusercontent.com/genophenoenvo/neon-datasets/main/pheno_images/targets_gcc.csv"
dataset = pd.read_csv(url)

# Creating columns year, month, day and setting the time as index to use 'shift' funtion() 
dataset['time'] = pd.to_datetime(dataset['time'])
dataset['year'] = pd.DatetimeIndex(dataset['time']).year
dataset['month'] = pd.DatetimeIndex(dataset['time']).month
dataset['day'] = pd.DatetimeIndex(dataset['time']).day
dataset['year_month']= dataset['year'].map(str) + "-" + dataset['month'].map(str)
dataset = dataset.set_index("time")

# Selecting the required columns for prediction: siteID and gcc90 and date related columns
gcc_data = dataset[["siteID", "gcc_90", "year", "month", "day", "year_month"]]
print("Shape:" + str(gcc_data.shape))
site_list = gcc_data["siteID"].unique()
print("Sites:")
print(site_list)

# Create dataframes for each of the sites
gcc_data_by_site = gcc_data.groupby("siteID")

future_pred_df = []
input_features = []

# Creating list of dataframes for each of the sites
for i in range(0,8):
    future_pred_df.append(gcc_data_by_site.get_group(site_list[i]))
    future_pred_df[i].reset_index(inplace=True)

# Adding the missing date indices (if any)
for i in range(0,8):
    date_range = pd.date_range(start=future_pred_df[i]["time"].max() + datetime.timedelta(1), 
                               end = date.today() + datetime.timedelta(1) , freq='D')
    future_pred_df[i] = future_pred_df[i].append(pd.DataFrame({'time': date_range, 
                                                               'siteID': site_list[i]}))
    future_pred_df[i].reset_index(inplace = True, drop = True)

# Creating the features for future predictions
for k in range(0,8):
    for i in range(1,6):     #Creating features columns for last 5 days
        col_name = "gcc_90_(t-"+str(i)+")"
        future_pred_df[k].loc[:,col_name] = future_pred_df[k].loc[:,"gcc_90"].shift(i)
        future_pred_df[k].loc[:,col_name] = future_pred_df[k].loc[:,col_name].fillna(future_pred_df[k].loc[:,"gcc_90"].shift(365*i))
        future_pred_df[k].loc[:,col_name] = future_pred_df[k].loc[:,col_name].fillna(future_pred_df[k].loc[:,"gcc_90"].shift(365*2*i))
        future_pred_df[k].loc[:,col_name] = future_pred_df[k].loc[:,col_name].fillna(future_pred_df[k].loc[:,"gcc_90"].shift(365*3*i))
        future_pred_df[k].loc[:,col_name] = future_pred_df[k].loc[:,col_name].ffill(axis = 0)
        if(k == 0):
            input_features.append(col_name)
        
    for i in range(1,6):     #Creating features columns for last 5 days from last year
        col_name_last_year = "last_year_gcc_90_(t-"+str(i)+")"
        future_pred_df[k].loc[:,col_name_last_year] = future_pred_df[k].loc[:,"gcc_90"].shift(i+365)
        future_pred_df[k].loc[:,col_name_last_year] = future_pred_df[k].loc[:,col_name_last_year].fillna(future_pred_df[k].loc[:,"gcc_90"].shift(i+365*2))
        future_pred_df[k].loc[:,col_name_last_year] = future_pred_df[k].loc[:,col_name_last_year].fillna(future_pred_df[k].loc[:,"gcc_90"].shift(i+365*3))
        future_pred_df[k].loc[:,col_name_last_year] = future_pred_df[k].loc[:,col_name_last_year].ffill(axis=0)
        if(k == 0):
            input_features.append(col_name_last_year)
            
    for i in range(0,15):     #Creating features columns for t to (t+14) days from last year
        col_name_last_year_ahead = "last_year_gcc_90_(t+"+str(i)+")"
        future_pred_df[k].loc[:,col_name_last_year_ahead] = future_pred_df[k].loc[:,"gcc_90"].shift(365-i)
        future_pred_df[k].loc[:,col_name_last_year_ahead] = future_pred_df[k].loc[:,col_name_last_year_ahead].fillna(future_pred_df[k].loc[:,"gcc_90"].shift(365*2-i))
        future_pred_df[k].loc[:,col_name_last_year_ahead] = future_pred_df[k].loc[:,col_name_last_year_ahead].fillna(future_pred_df[k].loc[:,"gcc_90"].shift(365*3-i))
        future_pred_df[k].loc[:,col_name_last_year_ahead] = future_pred_df[k].loc[:,col_name_last_year_ahead].ffill(axis=0)
        if(k == 0):
            input_features.append(col_name_last_year_ahead)

date_index = pd.Timestamp(date.today())
future_pred_date_range = pd.date_range(date_index, periods=36, freq='D')
future_pred_35 = pd.DataFrame(columns = ['time', 'siteID', 'gcc_90'])

# Predicting gcc_90 value for next 35 days
for k in range(0,8):
    input_record = future_pred_df[k][future_pred_df[k]["time"] == date_index]
    if(input_record[input_features].isnull().values.any()):
        print("Missing values present in the input features for" + site_list[k])
    
    file_name = "model_"+site_list[k]+".pkl"
    model = pickle.load(open(file_name,'rb'))
    future_pred = model.predict(input_record[input_features])
    
    future_pred_35 = future_pred_35.append(pd.DataFrame({'time': future_pred_date_range, 
                                                  'siteID': site_list[k],
                                                  'gcc_90': pd.Series(future_pred[0])
                                                        }))

# Adding gcc_sd from last year data
last_year_df = dataset[dataset.columns.intersection(['siteID', 'gcc_sd'])].loc['2020',:].reset_index()
last_year_df['time'] = last_year_df['time'].mask(last_year_df['time'].dt.year == 2020, 
                             last_year_df['time'] + pd.offsets.DateOffset(year=2021))
last_year_df = last_year_df.ffill(axis=0)

# Generating output csv files with predictions
path = 'C:/Users/palde/Documents/PhD - Michigan State University/Research Work/Greenness Predictions/ML Models/Deployment/PEG_RFR/outputs/'
output_file_name= "PEG_RFR_predictions_" + str(date.today().strftime("%m-%d-%y"))+ ".csv"
final_output = pd.merge(left=future_pred_35, right=last_year_df, how='left', left_on=['time','siteID'], right_on=['time','siteID'])
final_output.to_csv(path + output_file_name, index=False, header = True)
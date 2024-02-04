from Autos import Library, Hyper

dic = globals()

# Parameters
Learning_Rate = Hyper.Learning_Rate
Activation_Type = Hyper.Activation_Type

# Get data
Num_Label, \
Data_Train_FeaLab_Raw, Data_Test_FeaLab_Raw, \
Num_Data_Train, Num_Data_Test, \
Name_FeaLab, Name_Feature, Name_Label, \
Data_Train_FeaLab, Data_Train_Feature, Data_Train_Label, \
Data_Test_FeaLab, Data_Test_Feature, Data_Test_Label = Library.Get_Data()

# Train BNN or DNN
DNN, Train_History_DNN = Library.Train_DNN(Data_Train_Feature, Data_Train_Label)
#
# Test for BMDN or DNN
Eva_Realization, \
Eva_Prediction_Mean_DNN, \
Error_DNN, MAE_DNN, MAPE_DNN, RMSE_DNN = Library.Predict_and_Evaluate_DNN(DNN, Data_Test_Feature, Data_Test_Label)

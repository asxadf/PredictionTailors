import tensorflow as tf
import pandas as pd
from Autos import Hyper
import numpy as np
import math

dic = globals()

def Get_Data():
    print('Getting data...')
    # Parameters
    Data_Train_Path = Hyper.Data_Train_Path
    Data_Test_Path = Hyper.Data_Test_Path
    Num_Label = Hyper.Num_Label
    # TraTes/Train/Test ----> FeaLab/Feature/Label
    # Loading
    Data_Train_FeaLab_Raw = pd.read_csv(Data_Train_Path)
    Data_Test_FeaLab_Raw = pd.read_csv(Data_Test_Path)

    Num_Data_Train = len(Data_Train_FeaLab_Raw)
    Num_Data_Test = len(Data_Test_FeaLab_Raw)

    # Get data
    Name_FeaLab = Data_Train_FeaLab_Raw.columns.tolist()
    Name_Feature = Name_FeaLab[1:-Num_Label]
    Name_Label = Name_FeaLab[-Num_Label:]

    # For training data
    Data_Train_FeaLab = Data_Train_FeaLab_Raw[Name_Feature + Name_Label]
    Data_Train_Feature = Data_Train_FeaLab[Name_Feature]
    Data_Train_Label = Data_Train_FeaLab[Name_Label]

    # For testing data
    Data_Test_FeaLab = Data_Test_FeaLab_Raw[Name_Feature + Name_Label]
    Data_Test_Feature = Data_Test_FeaLab[Name_Feature]
    Data_Test_Label = Data_Test_FeaLab[Name_Label]

    return Num_Label, \
           Data_Train_FeaLab_Raw, Data_Test_FeaLab_Raw, \
           Num_Data_Train, Num_Data_Test, \
           Name_FeaLab, Name_Feature, Name_Label, \
           Data_Train_FeaLab, Data_Train_Feature, Data_Train_Label, \
           Data_Test_FeaLab, Data_Test_Feature, Data_Test_Label

def Train_DNN(Data_Train_Feature, Data_Train_Label):
    print('Training...')
    # Parameters
    Name_Feature = Data_Train_Feature.columns.tolist()
    Name_Label = Data_Train_Label.columns.tolist()

    Hidden_Unit_Structure = Hyper.Hidden_Unit_Structure
    Activation_Type = Hyper.Activation_Type
    Learning_Rate = Hyper.Learning_Rate
    Num_Batch = Hyper.Num_Batch
    Num_Epoch = Hyper.Num_Epoch
    Num_Data_Train = len(Data_Train_Feature)
    Num_Label = len(Name_Label)

    # Prepare data for training
    Data_Train_TF = tf.data.Dataset.from_tensor_slices((Data_Train_Feature, Data_Train_Label))
    Data_Train_TF = Data_Train_TF.shuffle(buffer_size=Num_Data_Train).batch(Num_Batch)

    # Create input layer
    Input = tf.keras.Input(shape=(len(Name_Feature),),
                           name='Input_Layer',
                           dtype=tf.float32
                           )

    # Create hidden layers with weight uncertainty using the DenseVariational layer
    # Create hidden layer
    # The 1st hidden layer
    Hidden = tf.keras.layers.Dense(units=Hidden_Unit_Structure[0],
                                   activation=Activation_Type,
                                   )(Input)

    # The middle:last hidden layers
    for Unit in Hidden_Unit_Structure[1:]:
        Hidden = tf.keras.layers.Dense(units=Unit,
                                       activation=Activation_Type,
                                       )(Hidden)

    # Create output layer
    Output = tf.keras.layers.Dense(units=Num_Label)(Hidden)

    # Create NN
    NN = tf.keras.Model(inputs=Input,
                        outputs=Output
                        )

    NN.summary()

    NN.compile(optimizer=tf.keras.optimizers.RMSprop(learning_rate=Learning_Rate),
               loss=Cus_Loss)
    Train_History = NN.fit(Data_Train_TF,
                           epochs=Num_Epoch)
    print("Training finished.")
    return NN, Train_History

def Predict_and_Evaluate_DNN(DNN, Data_Test_Feature, Data_Test_Label):
    print('Predicting...')
    # Parameters
    Name_Label = Data_Test_Label.columns.tolist()
    Num_Data_Test = len(Data_Test_Feature)
    Num_Label = len(Name_Label)

    Prediction_Datapoint_Wise = []
    for idx_Data in range(Num_Data_Test):
        print('Data', str(idx_Data))
        Prediction_Datapoint_Wise.append(DNN(tf.convert_to_tensor(Data_Test_Feature.iloc[[idx_Data]])))

    # Reverse normalizations
    Eva_Prediction_Mean = pd.DataFrame(data=np.zeros((Num_Data_Test, Num_Label)),
                                       columns=Name_Label)

    Eva_Realization = pd.DataFrame(data=np.zeros((Num_Data_Test, Num_Label)),
                                   columns=Name_Label)

    for idx_Data in range(Num_Data_Test):
        for idx_Label in range(Num_Label):
            # Reverse
            Rea = Data_Test_Label.loc[idx_Data].loc[Name_Label[idx_Label]]
            Mean = Prediction_Datapoint_Wise[idx_Data].numpy()[0, idx_Label]
            # Record
            Eva_Prediction_Mean.loc[idx_Data].loc['Label_' + str(idx_Label)] = Mean
            Eva_Realization.loc[idx_Data].loc['Label_' + str(idx_Label)] = Rea
    # Save All-in-One
    np.savetxt("/Applications/Project_PyCharm/CPO_Response/Results/Prediction_Point.csv", Eva_Prediction_Mean, delimiter=",")
    np.savetxt("/Applications/Project_PyCharm/CPO_Response/Results/Prediction_Realization.csv", Eva_Realization, delimiter=",")
    #
    Error = Eva_Prediction_Mean - Eva_Realization
    MAE = abs(Error).values.mean()
    MAPE = 100*abs(Error / Eva_Realization).values.mean()
    RMSE = np.sqrt(np.square(abs(Error).values).mean())

    return Eva_Realization,\
           Eva_Prediction_Mean, \
           Error, MAE, MAPE, RMSE

def Cus_Loss(y_true, y_pred):
    # Avoid division by zero
    epsilon = tf.keras.backend.epsilon()
    y_true = tf.cast(y_true, dtype=tf.float32)
    y_pred = tf.cast(y_pred, dtype=tf.float32)

    # Calculate percentage difference
    MPE = 100*tf.reduce_mean((y_true - y_pred) / (y_true + epsilon))
    # 12-15
    Cost_Oriented_Loss = 0.0012*tf.math.pow(MPE, 2) - 0.0791*tf.math.pow(MPE, 1) + 0.1074
    # 12-16
    # Cost_Oriented_Loss = 2.9703*tf.math.pow(MPE, 2) + 1.4027*tf.math.pow(MPE, 1) - 0.3433
    # 12-17
    # Cost_Oriented_Loss = 0.6565*tf.math.pow(MPE, 2) + 0.1846*tf.math.pow(MPE, 1) - 0.0097
    # 12-18
    # Cost_Oriented_Loss = 6.0497*tf.math.pow(MPE, 2) + 3.2362*tf.math.pow(MPE, 1) - 0.610
    return Cost_Oriented_Loss

    # 12-15
    # Cost_Oriented_Loss = 0.0012*tf.math.pow(MPE, 2) - 0.0791*tf.math.pow(MPE, 1) + 0.1074
    #
    # 12-16
    # Cost_Oriented_Loss = 2.9703*tf.math.pow(MPE, 2) + 1.4027*tf.math.pow(MPE, 1) - 0.3433
    #
    # 12-17
    # Cost_Oriented_Loss = 0.6565*tf.math.pow(MPE, 2) + 0.1846*tf.math.pow(MPE, 1) - 0.0097
    #
    # 12-18
    # Cost_Oriented_Loss = 6.0497*tf.math.pow(MPE, 2) + 3.2362*tf.math.pow(MPE, 1) - 0.610
    #

    # return tf.reduce_mean(tf.square(y_true - y_pred))

# Example Usage with a Keras Model
# model.compile(optimizer='adam', loss=quadratic_loss)
# model.fit(x_train, y_train, epochs=10, batch_size=32)

clc;
clear;
close all;
%% ------------------------------ Setting ------------------------------ %%
NT = 4;
%
NH     = 7;
Period = 28;
lambda = 100000; % Large lambda is quick
M_P = 100000;
M_D = 25000;
% Default
Update_Freq   = 7;
Iteration_Max = 5;
Gap_Desired   = 1;
Num_Update = Period/Update_Freq;
Num_Hour = 24;
Num_RES  = 5;
%
% Day of week 1
Day_1st_Week1 = 35;
Day_end_Week1 = 41;
% Day of week 2
Day_1st_Week2 = 180;
Day_end_Week2 = 186;
% Day of week 3
Day_1st_Week3 = 233;
Day_end_Week3 = 239;
% Day of week 4
Day_1st_Week4 = 347;
Day_end_Week4 = 353;
%
%% ------------------------------- Path -------------------------------- %%
Case = strcat('NT', num2str(NT));
Ini_Path = which('Location_CPO_v9.m');
Ini_Size = size('Location_CPO_v9.m', 2);
if ispc == 1
    Link = '\';
elseif ismac == 1
    Link = '/';
end
Path_Root = Ini_Path(1:end - Ini_Size - 1);
Path_Data = strcat(Path_Root, Link, 'Database');
Path_Case = strcat(Path_Root, Link, 'Case_Studies', Link, 'CPO_W', Link, Case);
%% ---------------------------- Initialize ----------------------------- %%
Date_All_List = importdata(strcat(Path_Data, Link, 'Date_All_List', '.mat'));
Date_Week1 = Date_All_List(Day_1st_Week1:Day_end_Week1);
Date_Week2 = Date_All_List(Day_1st_Week2:Day_end_Week2);
Date_Week3 = Date_All_List(Day_1st_Week3:Day_end_Week3);
Date_Week4 = Date_All_List(Day_1st_Week4:Day_end_Week4);

Date_Dispatch_List = [Date_Week1;
                      Date_Week2;
                      Date_Week3;
                      Date_Week4];
save(strcat(Path_Case, Link, 'Date_Dispatch_List.mat'), 'Date_Dispatch_List');
%
Date_Update_List = [Date_Week1(1);
                    Date_Week2(1);
                    Date_Week3(1);
                    Date_Week4(1)];
for d = 1:size(Date_Update_List, 1)
    Day_Update_List(d, 1) = find(Date_All_List == Date_Update_List(d));
end
%
%% ------------------------ Prepare Box: Useless ------------------------ %%
Enu_I             = cell(Num_Update, 1);
Enu_I_SU          = cell(Num_Update, 1);
Enu_I_SD          = cell(Num_Update, 1);
Enu_I_RC          = cell(Num_Update, 1);
Bound_Upper       = cell(Num_Update, 1);
Date_Tra_Selected = cell(Num_Update, 1);
Bound_Lower       = cell(Num_Update, 1);
Gap               = cell(Num_Update, 1);
Training_Time_SP  = cell(Num_Update, 1);
Training_Time_MP  = cell(Num_Update, 1);
Flag_Fail         = zeros(Num_Update, 1);
OVar_Phi_RES      = cell(Num_Update, 1);
OVar_Phi_R_H      = cell(Num_Update, 1);
OVar_Phi_R_C      = cell(Num_Update, 1);
%
%% ------------------------- Find TRA scenario ------------------------- %%
[Day_Tra_All, Date_Tra_All] = Find_Latest_v9(NH, Link, Path_Data);
%
%% ------------------------------ Training ----------------------------- %%
for Update = 1:Num_Update
    OVar_Phi_RES{Update, 1}{1} = ones(Num_Hour, Num_RES);
    OVar_Phi_R_H{Update, 1}{1} = 0.25*ones(Num_Hour, 1);
    OVar_Phi_R_C{Update, 1}{1} = 0.25*ones(Num_Hour, 1);
    Bound_Lower{Update, 1}(1)  = -inf;
    Current_Gap(Update, 1)     = inf;
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    disp(['Updating ', num2str(Update)]);
    disp(['Day: ', num2str(Day_Update_List(Update))]);
    disp(['Date: ', datestr(Date_Update_List(Update))]);
    disp(['Remaining updating: ', num2str(Num_Update - Update)]);
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    for Iteration = 1:Iteration_Max
        % Step 01: Solve SP
        [Enu_I{Update}(:, Iteration),...
         Enu_I_SU{Update}(:, Iteration),...
         Enu_I_SD{Update}(:, Iteration),...
         Enu_I_RC{Update}(:, Iteration),...
         Bound_Upper{Update}(1, Iteration),...
         Date_Tra_Selected{Update},...
         Training_Time_SP{Update}(1, Iteration)]...
         = CPO_Step01_SP_Auto_v9(Day_Update_List(Update),...
                                 Date_Update_List(Update),...
                                 NT,...
                                 lambda,...
                                 Iteration,...
                                 OVar_Phi_RES{Update}{end},...
                                 OVar_Phi_R_H{Update}{end},...
                                 OVar_Phi_R_C{Update}{end},...
                                 Date_Tra_All,...
                                 M_P,...
                                 Current_Gap(Update),...
                                 Link,...
                                 Path_Data);
         %
         % Check Gap
         Gap{Update}(1, Iteration)...
             = 100*(min(Bound_Upper{Update}) - max(Bound_Lower{Update}))/min(Bound_Upper{Update});
         Current_Gap(Update) = Gap{Update}(end);
         if Gap_Desired >= Gap{Update}(end)
             disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
             disp(['Boom! The gap is ', num2str(Gap{Update}(end)), '%!']);
             disp(['Updating #', num2str(Update)]);
             disp(['Day: ', num2str(Day_Update_List(Update))]);
             disp(['Date: ', datestr(Date_Update_List(Update))]);
             disp(['Remaining updating: ', num2str(Num_Update - Update)]);
             disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
             break
         else
             disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
             disp(['Go to next iteration: The gap is ', num2str(Gap{Update}(end)), '%...']);
             disp(['Updating #', num2str(Update)]);
             disp(['Day: ', num2str(Day_Update_List(Update))]);
             disp(['Date: ', datestr(Date_Update_List(Update))]);
             disp(['Remaining updating: ', num2str(Num_Update - Update)]);
             disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
         end
         %
         % Step 02: Solve MP
         [OVar_Phi_RES{Update}{end+1},...
          OVar_Phi_R_H{Update}{end+1},...
          OVar_Phi_R_C{Update}{end+1},...
          Bound_Lower{Update}(end+1),...
          Training_Time_MP{Update}(end+1)]...
          = CPO_Step02_MP_Auto_W_v9(Day_Update_List(Update),...
                                    Date_Update_List(Update),...
                                    NT,...
                                    NH,...
                                    lambda,...
                                    Iteration,...
                                    Enu_I{Update},...
                                    Enu_I_SU{Update},...
                                    Enu_I_SD{Update},...
                                    Enu_I_RC{Update},...
                                    Date_Tra_All,...
                                    M_P,...
                                    M_D,...
                                    Current_Gap(Update),...
                                    Link,...
                                    Path_Data);
         %
         if Bound_Lower{Update}(end) < 99
             disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
             OVar_Phi_RES{Update}{end} = OVar_Phi_RES{Update}{end-1};
             OVar_Phi_R_H{Update}{end} = OVar_Phi_R_H{Update}{end-1};
             OVar_Phi_R_C{Update}{end} = OVar_Phi_R_C{Update}{end-1};
             Flag_Fail(Update) = 1;
             disp(['Failed: #', num2str(Update), ' updating']);
             disp(['Updating #', num2str(Update)]);
             disp(['Day: ', num2str(Day_Update_List(Update))]);
             disp(['Date: ', datestr(Date_Update_List(Update))]);
             disp(['Remaining updating: ', num2str(Num_Update - Update)]);
             disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
            break
         end
    end
    OVar_Phi_RES_Best_Trained{Update} = OVar_Phi_RES{Update}{end};
    OVar_Phi_R_H_Best_Trained{Update} = OVar_Phi_R_H{Update}{end};
    OVar_Phi_R_C_Best_Trained{Update} = OVar_Phi_R_C{Update}{end};
    Training_Time_SP_SUM(Update) = sum(Training_Time_SP{Update});
    Training_Time_MP_SUM(Update) = sum(Training_Time_MP{Update});
end
for Update = 1:Num_Update
    OVar_Phi_RES_Final((Update-1)*Update_Freq + 1:Update_Freq*Update, 1) = OVar_Phi_RES_Best_Trained(Update);
    OVar_Phi_R_H_Final((Update-1)*Update_Freq + 1:Update_Freq*Update, 1) = OVar_Phi_R_H_Best_Trained(Update);
    OVar_Phi_R_C_Final((Update-1)*Update_Freq + 1:Update_Freq*Update, 1) = OVar_Phi_R_C_Best_Trained(Update);
end
save(strcat(Path_Case, Link, 'OVar_Phi_RES.mat'), 'OVar_Phi_RES_Final');
save(strcat(Path_Case, Link, 'OVar_Phi_R_H.mat'), 'OVar_Phi_R_H_Final');
save(strcat(Path_Case, Link, 'OVar_Phi_R_C.mat'), 'OVar_Phi_R_C_Final');
save(strcat(Path_Case, Link, 'Training.mat'));
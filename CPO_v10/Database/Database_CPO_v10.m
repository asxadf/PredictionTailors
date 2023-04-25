%% -------------------------------- RES -------------------------------- %%
% RES #01 Bus #49   [0, 0205]  Scaled Capacity: 200MW Flanders Elia
% RES #02 Bus #100  [0, 0789]  Scaled Capacity: 200MW Flanders DSO
% RES #03 Bus #59   [0, 0144]  Scaled Capacity: 200MW Wallonia Elia
% RES #04 Bus #92   [0, 0669]  Scaled Capacity: 200MW Wallonia DSO
% RES #05 Bus #70   [0, 2144]  Scaled Capacity: 200MW OFFSHORE
%
%
%% ---------------------------- RES_Farm_DAF --------------------------- %%
%  Column  #1         ... #5
%  Data    RES_01_DAF ... RES_05_DAF
%
%% ---------------------------- RES_Farm_ACT --------------------------- %%
%  Column  #1         ... #5
%  Data    RES_01_ACT ... RES_05_ACT
%
%% ----------------------------- Load_City ----------------------------- %%
%  Column  #1                    ... #91
%  Data    City_01 (24-1 Vector) ... City_91 (24-1 Vector)
%
%% --------------------------- Gen_Capacity ---------------------------- %%
%  Column  #1           #2            #3          #4          #5        
%  Data    Number       Location_bus  Max_output  Min_output  Minimal_on
%  Column  #6           #7            #8          #9          #10
%  Data    Minimal_off  Ramp_up       Ramp_down   SU_rampup   SD_rampdown  
%  Column  #11          #12           
%  Data    R_H_max      R_C_max  
%
%% ----------------------------- Gen_Price ----------------------------- %%
%  Column  #1        #2        #3         #4         #5        #6
%  Data    Number    c0        c1         c2         SU_price  SD_price   
%
%% ------------------------------- Branch ------------------------------ %%
%  Column  #1    #2    #3         #4          
%  Data    Fbus  Tbus  Reactance  Capacity
%
%% --------------------------- Start function -------------------------- %%
function...
[Num_Gen,...
 Num_Branch,...
 Num_Bus,...
 Num_City,...
 Num_Hour,...
 Num_RES,...
 Gen_Capacity,...
 Gen_Price,...
 Branch,...
 Load_Gro_SUM_All_ACT,...
 Load_Gro_SUM_All_DAF,...
 Load_Gro_SUM_Dis_ACT,...
 Load_Gro_SUM_Dis_DAF, Load_Gro_SUM_Dis_DAF_UB, Load_Gro_SUM_Dis_DAF_LB,...
 Load_Net_SUM_All_ACT,...
 Load_Net_SUM_All_DAF,...
 Load_Net_SUM_Dis_ACT,...
 Load_Net_SUM_Dis_DAF,...
 Load_City_All_ACT,...
 Load_City_All_DAF,...
 Load_City_Dis_ACT,...
 Load_City_Dis_DAF,...
 RES_SUM_All_ACT,...
 RES_SUM_All_DAF, RES_SUM_All_DAF_UB, RES_SUM_All_DAF_LB,...
 RES_SUM_Dis_ACT,...
 RES_SUM_Dis_DAF, RES_SUM_Dis_DAF_UB, RES_SUM_Dis_DAF_LB,...
 RES_Farm_All_ACT,...
 RES_Farm_All_DAF, RES_Farm_All_DAF_UB, RES_Farm_All_DAF_LB,...
 RES_Farm_Dis_ACT,...
 RES_Farm_Dis_DAF, RES_Farm_Dis_DAF_UB, RES_Farm_Dis_DAF_LB,...
 R_Sys_Req_All,...
 R_Sys_Req_Dis,...
 R_H_Req_All,...
 R_H_Req_Dis,...
 R_C_Req_All,...
 R_C_Req_Dis,...
 PTDF_Gen,...
 PTDF_City,...
 PTDF_RES,...
 GS_Price,...
 LS_Price,...
 BS_Price,...
 Date_All_List,...
 Day, Pre_W_UB, Pre_W_LB,...
 Unit_Quick,...
 Unit_Thermal] = Database_CPO_v10(Date_Dispatch, Link, Path_Data)
%
%% ------------------------------ Loading ------------------------------ %%
disp('Loading...');
Load_Gro_SUM_ACT    = round(readmatrix(strcat(Path_Data, Link, 'Load_Gro_SUM_ACT', '.csv')));
Load_Gro_SUM_DAF    = round(readmatrix(strcat(Path_Data, Link, 'Load_Gro_SUM_DAF', '.csv')));
Load_Gro_SUM_DAF_UB = readmatrix(strcat(Path_Data, Link, Link, 'Load_Gro_SUM_DAF_UB', '.csv')); 
Load_Gro_SUM_DAF_LB = readmatrix(strcat(Path_Data, Link, Link, 'Load_Gro_SUM_DAF_LB', '.csv'));
RES_01_ACT          = round(readmatrix(strcat(Path_Data, Link, 'RES_01_ACT',   '.csv')));
RES_01_DAF          = round(readmatrix(strcat(Path_Data, Link, 'RES_01_DAF',   '.csv')));
RES_01_DAF_UB       = round(readmatrix(strcat(Path_Data, Link, 'RES_01_DAF_UB','.csv')));
RES_01_DAF_LB       = round(readmatrix(strcat(Path_Data, Link, 'RES_01_DAF_LB','.csv')));
RES_02_ACT          = round(readmatrix(strcat(Path_Data, Link, 'RES_02_ACT',   '.csv')));
RES_02_DAF          = round(readmatrix(strcat(Path_Data, Link, 'RES_02_DAF',   '.csv')));
RES_02_DAF_UB       = round(readmatrix(strcat(Path_Data, Link, 'RES_02_DAF_UB','.csv')));
RES_02_DAF_LB       = round(readmatrix(strcat(Path_Data, Link, 'RES_02_DAF_LB','.csv')));
RES_03_ACT          = round(readmatrix(strcat(Path_Data, Link, 'RES_03_ACT',   '.csv')));
RES_03_DAF          = round(readmatrix(strcat(Path_Data, Link, 'RES_03_DAF',   '.csv')));
RES_03_DAF_UB       = round(readmatrix(strcat(Path_Data, Link, 'RES_03_DAF_UB','.csv')));
RES_03_DAF_LB       = round(readmatrix(strcat(Path_Data, Link, 'RES_03_DAF_LB','.csv')));
RES_04_ACT          = round(readmatrix(strcat(Path_Data, Link, 'RES_04_ACT',   '.csv')));
RES_04_DAF          = round(readmatrix(strcat(Path_Data, Link, 'RES_04_DAF',   '.csv')));
RES_04_DAF_UB       = round(readmatrix(strcat(Path_Data, Link, 'RES_04_DAF_UB','.csv')));
RES_04_DAF_LB       = round(readmatrix(strcat(Path_Data, Link, 'RES_04_DAF_LB','.csv')));
RES_05_ACT          = round(readmatrix(strcat(Path_Data, Link, 'RES_05_ACT',   '.csv')));
RES_05_DAF          = round(readmatrix(strcat(Path_Data, Link, 'RES_05_DAF',   '.csv')));
RES_05_DAF_UB       = round(readmatrix(strcat(Path_Data, Link, 'RES_05_DAF_UB','.csv')));
RES_05_DAF_LB       = round(readmatrix(strcat(Path_Data, Link, 'RES_05_DAF_LB','.csv')));
Gen_Capacity        = readmatrix(strcat(Path_Data, Link, 'Gen_Capacity', '.csv'));
Gen_Price           = readmatrix(strcat(Path_Data, Link, 'Gen_Price',    '.csv'));
Branch              = readmatrix(strcat(Path_Data, Link, 'Branch',       '.csv'));
City_Bus            = readmatrix(strcat(Path_Data, Link, 'City_Bus',     '.csv'));
City_Weight         = readmatrix(strcat(Path_Data, Link, 'City_Weight',  '.csv'));
Date_All_List       = importdata(strcat(Path_Data, Link, 'Date_All_List','.mat'));
Pre_W_UB            = readmatrix(strcat(Path_Data, Link, 'Pre_W_UB',     '.csv'));
Pre_W_LB            = readmatrix(strcat(Path_Data, Link, 'Pre_W_LB',     '.csv'));
%
%% ---------------------------- Basic Data ----------------------------- %%
% Number of element
Num_Gen    = size(Gen_Capacity, 1);
Num_Branch = size(Branch, 1);
Num_Bus    = max(max(Branch(:, 2:3)));
Num_City   = 91;
Num_RES    = 5;
Num_Hour   = 24;
Num_Day    = size(Load_Gro_SUM_DAF, 2);
%
% For SF
Ref_Bus = 69;
PTDF = Calculate_PTDF(Branch, Ref_Bus);
PTDF = round(PTDF, 2);
%
% Unit types
Unit_Gas  = [1;2;3;6;8;9;12;13;15;17;18];
Unit_Oil  = [31;32;33;38;41;42;46;49;50;54];
Unit_Coal = [4;5;7;10;11;14;16;19;20;21;22;23;24;25;26;27;28;29;30;34;35;...
             36;37;39;40;43;44;45;47;48;51;52;53];
Unit_Quick   = sort([Unit_Gas; Unit_Oil]);
Unit_Thermal = sort([Unit_Coal]);
%
% Find dispatch day
Day = find(Date_All_List == Date_Dispatch);
%
% Linearized price
Gen_Price(:, 3) = [71.74; 71.74; 71.74; 84.39; 56.89; 75.24; 34.07; 71.74;
                   71.74; 16.89; 24.26; 73.84; 73.84; 34.07; 73.84; 34.07;
                   73.84; 73.84; 34.07; 18.33; 18.33; 34.07; 34.07; 23.29; 
                   23.29; 105.32;65.54; 65.54; 54.69; 66.07; 54.24; 50.74;
                   44.70; 34.07; 34.07; 82.39; 34.07; 54.24; 36.26; 84.39;
                   45.54; 29.94; 56.89; 56.89; 56.89; 45.54; 34.07; 34.07;
                   45.54; 30.44; 34.07; 34.07; 34.07; 30.44 ];
%
% Penalty price
LS_Price = 2000;
GS_Price = 2000;
BS_Price = 2000;
%
% RES bus
RES_01_Bus = 49;
RES_02_Bus = 100;
RES_03_Bus = 59;
RES_04_Bus = 92;
RES_05_Bus = 70;

RES_Bus = [RES_01_Bus; RES_02_Bus; RES_03_Bus; RES_04_Bus; RES_05_Bus];
%
% Scaler 
Scaler_Load   = 0.31;
Scaler_RES_01 = 1.00;
Scaler_RES_02 = 0.30;
Scaler_RES_03 = 1.50;
Scaler_RES_04 = 0.35;
Scaler_RES_05 = 0.10;
%
% Reserve level
R_for_Load_Net = 0.3*ones(Num_Hour, 1);
R_H_Ratio = 0.3;
R_C_Ratio = 1 - R_H_Ratio;
Phi_R_H = R_H_Ratio*R_for_Load_Net;
Phi_R_C = R_C_Ratio*R_for_Load_Net;
%
% Confirm subhour
Subhour = 'hh:00';
if Subhour == 'hh:00'
    for i = 1:24
        Point(i, 1) = (i-1)*4+1;
    end
end
if Subhour == 'hh:15'
    for i = 1:24
        Point(i, 1) = (i-1)*4+2;
    end
end
if Subhour == 'hh:30'
    for i = 1:24
        Point(i, 1) = (i-1)*4+3;
    end
end
if Subhour == 'hh:45'
    for i = 1:24
        Point(i, 1) = (i-1)*4+4;
    end
end
% Tailoring transmission capacity
% Path for G4
Branch(7,   5) = 500;
Branch(9,   5) = 500;
% Path for G32
Branch(113, 5) = 30;
% Path for G39
Branch(133, 5) = 650;
Branch(134, 5) = 650;
% Path for G51
Branch(176, 5) = 100;
% Path for G52
Branch(177, 5) = 100;
% Path for G54
Branch(183, 5) = 50;
% Special branches
Branch(129, 5) = 600;
Branch(25,  5) = 500;
Branch(27,  5) = 500;
Branch(28,  5) = 500;
Branch(29,  5) = 500;
% Path between Zone1 and Zone2
Branch(45,  5) = 629;
Branch(54,  5) = 629;
Branch(108, 5) = 629;
Branch(116, 5) = 629;
Branch(120, 5) = 629;
Branch(185, 5) = 629;
% Path between Zone2 and Zone3
Branch(128, 5) = 754;
Branch(148, 5) = 754;
Branch(157, 5) = 754;
Branch(158, 5) = 754;
Branch(159, 5) = 754;
%
%% --------------------------- Load_Gro_SUM ---------------------------- %%
Load_Gro_SUM_All_ACT    = Scaler_Load*Load_Gro_SUM_ACT(Point, :);
Load_Gro_SUM_All_DAF    = Scaler_Load*Load_Gro_SUM_DAF(Point, :);
Load_Gro_SUM_Dis_ACT    = Load_Gro_SUM_All_ACT(:, Day);
Load_Gro_SUM_Dis_DAF    = Load_Gro_SUM_All_DAF(:, Day);
Load_Gro_SUM_Dis_DAF_UB = Load_Gro_SUM_DAF_UB(:, Day).*Load_Gro_SUM_Dis_DAF;
Load_Gro_SUM_Dis_DAF_LB = Load_Gro_SUM_DAF_LB(:, Day).*Load_Gro_SUM_Dis_DAF;
%
%% ----------------------------- Load_City ----------------------------- %%
for d = 1:Num_Day
    Load_City_All_ACT{1, d} = repmat(Load_Gro_SUM_All_ACT(:, d), 1, Num_City);
    Load_City_All_DAF{1, d} = repmat(Load_Gro_SUM_All_DAF(:, d), 1, Num_City);
    for c = 1:Num_City
        % For ACT
        Load_City_All_ACT{d}(:, c) = round(City_Weight(c)*Load_City_All_ACT{d}(:, c), 2);
        % For DAF
        Load_City_All_DAF{d}(:, c) = round(City_Weight(c)*Load_City_All_DAF{d}(:, c), 2);
    end
end
Load_City_Dis_ACT = Load_City_All_ACT{Day};
Load_City_Dis_DAF = Load_City_All_DAF{Day};
%
%% -------------------------------- RES -------------------------------- %%
% For ACT
RES_01_All_ACT = Scaler_RES_01*RES_01_ACT(Point, :);
RES_02_All_ACT = Scaler_RES_02*RES_02_ACT(Point, :);
RES_03_All_ACT = Scaler_RES_03*RES_03_ACT(Point, :);
RES_04_All_ACT = Scaler_RES_04*RES_04_ACT(Point, :);
RES_05_All_ACT = Scaler_RES_05*RES_05_ACT(Point, :);
% For DAF
RES_01_All_DAF = Scaler_RES_01*RES_01_DAF(Point, :);
RES_02_All_DAF = Scaler_RES_02*RES_02_DAF(Point, :);
RES_03_All_DAF = Scaler_RES_03*RES_03_DAF(Point, :);
RES_04_All_DAF = Scaler_RES_04*RES_04_DAF(Point, :);
RES_05_All_DAF = Scaler_RES_05*RES_05_DAF(Point, :);
% For DAF UB
RES_01_All_DAF_UB = Scaler_RES_01*RES_01_DAF_UB(Point, :);
RES_02_All_DAF_UB = Scaler_RES_02*RES_02_DAF_UB(Point, :);
RES_03_All_DAF_UB = Scaler_RES_03*RES_03_DAF_UB(Point, :);
RES_04_All_DAF_UB = Scaler_RES_04*RES_04_DAF_UB(Point, :);
RES_05_All_DAF_UB = Scaler_RES_05*RES_05_DAF_UB(Point, :);
% For DAF LB
RES_01_All_DAF_LB = Scaler_RES_01*RES_01_DAF_LB(Point, :);
RES_02_All_DAF_LB = Scaler_RES_02*RES_02_DAF_LB(Point, :);
RES_03_All_DAF_LB = Scaler_RES_03*RES_03_DAF_LB(Point, :);
RES_04_All_DAF_LB = Scaler_RES_04*RES_04_DAF_LB(Point, :);
RES_05_All_DAF_LB = Scaler_RES_05*RES_05_DAF_LB(Point, :);
%
for d = 1:Num_Day
    % For ACT
    RES_Farm_All_ACT{d, 1} = [ RES_01_All_ACT(:, d)...
                               RES_02_All_ACT(:, d)...
                               RES_03_All_ACT(:, d)...
                               RES_04_All_ACT(:, d)...
                               RES_05_All_ACT(:, d) ];
    RES_SUM_All_ACT(:, d) = sum(RES_Farm_All_ACT{d}, 2);
    % For DAF
    RES_Farm_All_DAF{d, 1} = [ RES_01_All_DAF(:, d)...
                               RES_02_All_DAF(:, d)...
                               RES_03_All_DAF(:, d)...
                               RES_04_All_DAF(:, d)...
                               RES_05_All_DAF(:, d) ];
    RES_SUM_All_DAF(:, d) = sum(RES_Farm_All_DAF{d}, 2);
    % For DAF UB
    RES_Farm_All_DAF_UB{d, 1} = [ RES_01_All_DAF_UB(:, d)...
                                  RES_02_All_DAF_UB(:, d)...
                                  RES_03_All_DAF_UB(:, d)...
                                  RES_04_All_DAF_UB(:, d)...
                                  RES_05_All_DAF_UB(:, d) ];
    RES_SUM_All_DAF_UB(:, d) = sum(RES_Farm_All_DAF_UB{d}, 2);
    % For DAF LB
    RES_Farm_All_DAF_LB{d, 1} = [ RES_01_All_DAF_LB(:, d)...
                                  RES_02_All_DAF_LB(:, d)...
                                  RES_03_All_DAF_LB(:, d)...
                                  RES_04_All_DAF_LB(:, d)...
                                  RES_05_All_DAF_LB(:, d) ];
    RES_SUM_All_DAF_LB(:, d) = sum(RES_Farm_All_DAF_LB{d}, 2);

end
RES_SUM_Dis_ACT     = RES_SUM_All_ACT(:, Day);
RES_SUM_Dis_DAF     = RES_SUM_All_DAF(:, Day);
RES_SUM_Dis_DAF_UB  = RES_SUM_All_DAF_UB(:, Day);
RES_SUM_Dis_DAF_LB  = RES_SUM_All_DAF_LB(:, Day);
%
RES_Farm_Dis_ACT    = RES_Farm_All_ACT{Day};
RES_Farm_Dis_DAF    = RES_Farm_All_DAF{Day};
RES_Farm_Dis_DAF_UB = RES_Farm_All_DAF_UB{Day};
RES_Farm_Dis_DAF_LB = RES_Farm_All_DAF_LB{Day};

Pre_W_UB = Pre_W_UB(:, 1:Num_RES);
Pre_W_LB = Pre_W_LB(:, 1:Num_RES);
%
%% --------------------------- Load_Net_SUM ---------------------------- %%
Load_Net_SUM_All_ACT = Load_Gro_SUM_All_ACT - RES_SUM_All_ACT;
Load_Net_SUM_All_DAF = Load_Gro_SUM_All_DAF - RES_SUM_All_DAF;
Load_Net_SUM_Dis_ACT = Load_Gro_SUM_Dis_ACT - RES_SUM_Dis_ACT;
Load_Net_SUM_Dis_DAF = Load_Gro_SUM_Dis_DAF - RES_SUM_Dis_DAF;
%
%% --------------------------- Reserve Level --------------------------- %%
for d = 1:Num_Day
    R_H_Req_All(:, d)  = Phi_R_H.*Load_Net_SUM_All_DAF(:, d);
    R_C_Req_All(:, d)  = Phi_R_C.*Load_Net_SUM_All_DAF(:, d);
end
R_H_Req_Dis = R_H_Req_All(:, Day);
R_C_Req_Dis = R_C_Req_All(:, Day);
%
R_Sys_Req_All = R_H_Req_All + R_C_Req_All;
R_Sys_Req_Dis = R_H_Req_Dis + R_C_Req_Dis;
%
%% ------------------------------- PTDF -------------------------------- %%
for i = 1:Num_Gen
    PTDF_Gen(:,i) = PTDF(:, Gen_Capacity(i, 2));
end
for i = 1:Num_City
    PTDF_City(:,i) = PTDF(:, City_Bus(i, 1));
end
for i = 1:Num_RES
    PTDF_RES(:,i) = PTDF(:, RES_Bus(i, 1));
end
disp('Modeling...');
%
end
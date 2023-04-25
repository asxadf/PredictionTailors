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
%  Column  #1                    ... #11
%  Data    City_01 (24-1 Vector) ... City_11 (24-1 Vector)
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
%  Column  #1        #2        #3         #4
%  Data    Number    c0        c1         c2
%  Column  #5        #6
%  Data    SU_price  SD_price   
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
 Unit_Thermal] = Database_CPO_v9(Date_Dispatch, Link, Path_Data)
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
Num_City   = 11;
Num_RES    = 5;
Num_Hour   = 24;
Num_Day    = size(Load_Gro_SUM_DAF, 2);
%
% For SF
Ref_Bus = 1;
PTDF = Calculate_PTDF(Branch, Ref_Bus);
PTDF = round(PTDF, 2);
%
% Branch capacity could be too tight
Branch(:, 5) = [500;...1:  1-2
                500;...2:  1-5
                500;...3:  2-3
                500;...4:  2-4
                500;...5:  2-5
                500;...6:  3-4
                500;...7:  4-5
                500;...8:  4-7
                500;...9:  4-9
                500;...10: 5-6
                500;...11: 6-11
                500;...12: 6-12
                500;...13: 6-13
                500;...14: 7-8
                500;...15: 7-9
                500;...16: 9-10
                500;...17: 9-14
                500;...18: 10-11
                500;...19: 13-12
                500]; %20: 13-14
%

% Branch(:, 5) = [400;...1:  1-2
%                 200;...2:  1-5
%                 175;...3:  2-3
%                 200;...4:  2-4
%                 200;...5:  2-5
%                 249;...6:  3-4
%                 200;...7:  4-5
%                 200;...8:  4-7
%                 200;...9:  4-9
%                 200;...10: 5-6
%                 200;...11: 6-11
%                 200;...12: 6-12
%                 200;...13: 6-13
%                 200;...14: 7-8
%                 200;...15: 7-9
%                 200;...16: 9-10
%                 200;...17: 9-14
%                 200;...18: 10-11
%                 200;...19: 13-12
%                 200]; %20: 13-14
% %
% Unit types
Unit_Gas  = [4; 5];
Unit_Oil  = [6; 7];
Unit_Coal = [1; 2; 3];
Unit_Quick   = sort([Unit_Gas; Unit_Oil]);
Unit_Thermal = sort(Unit_Coal);
%
% Find dispatch day
Day = find(Date_All_List == Date_Dispatch);
%
% Linearized price
%
% Penalty price
LS_Price = 2000;
GS_Price = 2000;
BS_Price = 2000;
%
% RES bus
RES_01_Bus = 3;
RES_02_Bus = 4;
RES_03_Bus = 6;
RES_04_Bus = 13;
RES_05_Bus = 1;
RES_Bus = [RES_01_Bus; RES_02_Bus; RES_03_Bus; RES_04_Bus; RES_05_Bus];
%
% Scaler 
Scaler_Load   = 0.06;
Scaler_RES_01 = 0.4;
Scaler_RES_02 = 0.1;
Scaler_RES_03 = 0.5;
Scaler_RES_04 = 0.10;
Scaler_RES_05 = 0.04;
%
% Reserve level
R_for_Load_Net = 0.5*ones(Num_Hour, 1);
R_H_Ratio = 0.5;
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


% Linearized operation cost
% for t = 1:Num_Hour
    % for i = 1:Num_Gen
        % Generation
        % Con = Con...
            % + [   Var_UC_P(i, t)...
               % == Point_Gen(i, 1)*Var_UC_I(i, t)...
                % + ones(1,Num_SG)*Var_UC_P_SG(i, (t-1)*Num_SG+1:t*Num_SG)'];
        %
        % Generation cost
        % Con = Con...
            % + [   Var_UC_P_Cost(i, t)...
               % == Point_Cost(i, 1)*Var_UC_I(i, t)...
                % + SG_Slope(i, :)*Var_UC_P_SG(i, (t-1)*Num_SG+1:t*Num_SG)'];
        %
        % Segment limit
        % Con = Con...
            % + [ 0 <= Var_UC_P_SG(i, (t-1)*Num_SG+1:t*Num_SG)...
                  % <= SG_Length(i)*Var_UC_I(i, t) ];
    % end
% end

% Get quadratic function of gen cost
% Cut segment length
% SG_Length = round((Gen_Capacity(:, 3) - Gen_Capacity(:, 4))/Num_SG, 2);
%
% Get points of generation and cost
% for i = 1:Num_Gen
    % for kk = 1:Num_SG+1
        % Point_Gen(i, kk) = Gen_Capacity(i, 4) + (kk-1)*SG_Length(i, 1);
        % Point_Cost(i, kk) = Gen_Price(i, 2)...
                          % + Gen_Price(i, 3).*Point_Gen(i, kk)...
                          % + Gen_Price(i, 4).*Point_Gen(i, kk).^2;
    % end
% end
%
% Get slope
% for i = 1:Num_Gen
    % for k = 1:Num_SG
        % SG_Slope(i, k) = (Point_Cost(i, k+1) - Point_Cost(i, k))/SG_Length(i);
    % end
% end
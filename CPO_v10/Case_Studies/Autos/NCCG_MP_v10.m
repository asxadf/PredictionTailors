function[Recorder_Updated, Flag_Out_Converge] = NCCG_MP_v10(Season, Recorder_Text, Recorder_Old)
%% ----------------------------- Root Path ----------------------------- %%
Ini_Path = which('Location_CPO_v10.m');
Ini_Size = size('Location_CPO_v10.m', 2);
if ispc == 1
    Link = '\';
elseif ismac == 1
    Link = '/';
end
Path_Root = Ini_Path(1:end - Ini_Size - 1);
Path_Data = strcat(Path_Root, Link, 'Database');
Peak_Day_List = readmatrix(strcat(Path_Data, Link, 'Peak_Day_List', '.csv'));
Date_All_List = importdata(strcat(Path_Data, Link, 'Date_All_List', '.mat'));
City_Weight   = readmatrix(strcat(Path_Data, Link, 'City_Weight', '.csv'));
Day_Dispatch  = Peak_Day_List(Season);
Date_Dispatch = Date_All_List(Day_Dispatch);
%
%% ----------------------------- Database ------------------------------ %%
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
 Unit_Thermal] = Database_CPO_v10(Date_Dispatch, Link, Path_Data);
%
%% --------------------------- Load Recorder --------------------------- %%
Recorder       = Recorder_Old;
Recorder(:, 1) = [];
Num_Scenario   = size(Recorder, 2);
%
%% --------------------------- Load Scenario --------------------------- %%
for h = 1:Num_Scenario
    Out_W_UB_History{h} = round(Recorder{3, h});
    Out_W_LB_History{h} = round(Recorder{4, h});
    Out_L_UB_History{h} = round(Recorder{5, h});
    Out_L_LB_History{h} = round(Recorder{6, h});
end
%
%% -------------------------- Uncertainty Set -------------------------- %%
for h = 1:Num_Scenario
    % For RES
    RES_Farm_Dis_ACT_Scens{h} = RES_Farm_Dis_DAF...
                              + Out_W_UB_History{h}.*(RES_Farm_Dis_DAF_UB - RES_Farm_Dis_DAF)...
                              + Out_W_LB_History{h}.*(RES_Farm_Dis_DAF_LB - RES_Farm_Dis_DAF);
    %
    % For load SUM
    Load_SUM_Dis_ACT_Scens{h} = Load_Gro_SUM_Dis_DAF...
                              + Out_L_UB_History{h}.*(Load_Gro_SUM_Dis_DAF_UB - Load_Gro_SUM_Dis_DAF)...
                              + Out_L_LB_History{h}.*(Load_Gro_SUM_Dis_DAF_LB - Load_Gro_SUM_Dis_DAF);
    % For load city
    for c = 1:Num_City
        Load_City_Dis_ACT_Scens{h}(:, c) = City_Weight(c)*Load_SUM_Dis_ACT_Scens{h};
    end
end
%
%% ----------------------------- Variables ----------------------------- %%
% UC
Var_UC_I    = binvar(Num_Gen, Num_Hour);
Var_UC_I_SU = binvar(Num_Gen, Num_Hour);
Var_UC_I_SD = binvar(Num_Gen, Num_Hour);
Var_UC_I_RC = binvar(Num_Gen, Num_Hour);
Var_UC_P    = sdpvar(Num_Gen, Num_Hour);
Var_UC_W    = sdpvar(Num_Hour, Num_RES);
Var_UC_R_H  = sdpvar(Num_Gen, Num_Hour);
Var_UC_R_C  = sdpvar(Num_Gen, Num_Hour);
% ED
for h = 1:Num_Scenario
    Var_ED_I{h}    = binvar(Num_Gen, Num_Hour);
    Var_ED_I_SU{h} = binvar(Num_Gen, Num_Hour);
    Var_ED_I_SD{h} = binvar(Num_Gen, Num_Hour);
    Var_ED_P{h}    = sdpvar(Num_Gen, Num_Hour);
    Var_ED_W{h}    = sdpvar(Num_Hour, Num_RES);
    Var_ED_S1{h}   = sdpvar(Num_Hour, 1);
    Var_ED_S2{h}   = sdpvar(Num_Hour, 1);
    Var_ED_S3{h}   = sdpvar(Num_Hour, Num_Branch);
    Var_ED_S4{h}   = sdpvar(Num_Hour, Num_Branch);
    Var_ED_Z1{h}   = sdpvar(Num_Gen, Num_Hour);
    Var_ED_Z2{h}   = sdpvar(Num_Gen, Num_Hour);
end
% Others
Var_eta = sdpvar(1, 1);
%
%% ----------------------------- Objective ----------------------------- %%
% UC cost
Cost_UC_SU = Gen_Price(:, 5)'*sum(Var_UC_I_SU, 2);
Cost_UC_NL = Gen_Price(:, 2)'*sum(Var_UC_I, 2);
Cost_UC_P  = Gen_Price(:, 3)'*sum(Var_UC_P, 2);
Cost_UC_All = Cost_UC_SU + Cost_UC_NL + Cost_UC_P;
%
% ED cost
for h = 1:Num_Scenario
    Cost_ED_SU(h) = Gen_Price(:, 5)'*sum(Var_ED_I_SU{h}, 2);
    Cost_ED_NL(h) = Gen_Price(:, 2)'*sum(Var_ED_I{h}, 2);
    Cost_ED_P(h)  = Gen_Price(:, 3)'*sum(Var_ED_P{h}, 2);
    Cost_ED_S1(h) = LS_Price*sum(Var_ED_S1{h});
    Cost_ED_S2(h) = GS_Price*sum(Var_ED_S2{h});
    Cost_ED_S3(h) = BS_Price*sum(Var_ED_S3{h}(:));
    Cost_ED_S4(h) = BS_Price*sum(Var_ED_S4{h}(:));
end
Cost_ED_All = Cost_ED_SU + Cost_ED_NL...
            + Cost_ED_P...
            + Cost_ED_S1 + Cost_ED_S2 + Cost_ED_S3 + Cost_ED_S4;
%
% Obj
Obj = Cost_UC_All + Var_eta;
%
%% -------------------------- Constraints: UC -------------------------- %%
Con = [];
% UC: Generation limit
for t = 1:Num_Hour
    Con = Con...
        + [   Var_UC_P(:, t) - Var_UC_R_H(:, t)...
           >= Gen_Capacity(:, 4).* Var_UC_I(:, t) ];
    Con = Con...
        + [   Var_UC_P(:, t) + Var_UC_R_H(:, t)...
           <= Gen_Capacity(:, 3).* Var_UC_I(:, t) ];
end
%
% UC: Segment limit
for t = 1:Num_Hour
    Con = Con...
        + [ 0 <= Var_UC_P(:, t)...
              <= Gen_Capacity(:, 3).*Var_UC_I(:, t) ];
end
%
% UC: Hot reserve limit
for t = 1:Num_Hour
    Con = Con...
        + [ 0 <= Var_UC_R_H(:, t)...
              <= Gen_Capacity(:, 11).*Var_UC_I(:, t) ];
end
%
% UC: Cool reserve limit
for t = 1:Num_Hour
    Con = Con...
        + [   Var_UC_R_C(:, t)...
           >= Gen_Capacity(:, 4).*Var_UC_I_RC(:, t) ];
    Con = Con...
        + [   Var_UC_R_C(:, t)...
           <= Gen_Capacity(:,12).*Var_UC_I_RC(:, t) ];
end
%
% UC: Cool reserve flag
Con = Con + [ Var_UC_I_RC + Var_UC_I <= 1 ];
%
% UC: Logical relationship
for t = 1:Num_Hour
    if t == 1
        Con = Con...
            + [   Var_UC_I_SU(:, t) - Var_UC_I_SD(:, t)...
               == Var_UC_I(:, t) ];
    end
    if t >= 2
        Con = Con...
            + [   Var_UC_I_SU(:, t) - Var_UC_I_SD(:, t)...
               == Var_UC_I(:, t) - Var_UC_I(:, t-1) ];
    end
end
%
% UC: Min ON/OFF
for i = 1:Num_Gen
    % Min ON
    for t = Gen_Capacity(i, 5):Num_Hour
        Con = Con...
            + [   sum(Var_UC_I_SU(i, t-Gen_Capacity(i, 5)+1:t))...
               <= Var_UC_I(i, t) ];
    end
    % Min OFF
    for t = Gen_Capacity(i, 6):Num_Hour
        Con = Con...
            + [   sum(Var_UC_I_SD(i, t-Gen_Capacity(i, 6)+1:t))...
               <= 1 - Var_UC_I(i, t) ];
    end
end
%
% UC: Ramping limit
for t = 2:Num_Hour
    Con = Con...
        + [   Var_UC_P(:, t) - Var_UC_P(:, t-1)...
           <= Gen_Capacity(:, 7).*     Var_UC_I(:, t-1)...
            + Gen_Capacity(:, 9).*(    Var_UC_I(:, t)...
            - Var_UC_I(:, t-1))...
            + Gen_Capacity(:, 3).*(1 - Var_UC_I(:, t)) ];
    Con = Con...
        + [   Var_UC_P(:, t-1) - Var_UC_P(:, t)...
           <= Gen_Capacity(:, 8).*     Var_UC_I(:, t)...
            + Gen_Capacity(:,10).*(    Var_UC_I(:, t-1)...
            - Var_UC_I(:, t))...
            + Gen_Capacity(:, 3).*(1 - Var_UC_I(:, t-1)) ];
end
%
% UC: RES curtailment limit
Con = Con...
    + [ 0 <= Var_UC_W <= RES_Farm_Dis_DAF ];
%
% UC: Thermal untis
for i = Unit_Thermal
    Con = Con...
        + [ Var_UC_I_RC(i, :) == 0];
end
%
% UC: Power balance
for t = 1:Num_Hour
    Con = Con...
        + [   sum(Var_UC_P(:, t))...
            + sum(Var_UC_W(t, :))...
           == sum(Load_City_Dis_DAF(t, :)) ];
end
%
% UC: Transmission limit
for t = 1:Num_Hour
    Con = Con...
        + [ - Branch(:, 5)...
           <= PTDF_Gen*Var_UC_P(:, t)...
            + PTDF_RES*Var_UC_W(t, :)'...
            - PTDF_City*Load_City_Dis_DAF(t, :)'...
           <= Branch(:, 5) ];
end
%
%% ------------------------- Constraints: Cuts ------------------------- %%
for h = 1:Num_Scenario
    % Cuts
    Con = Con + [ Var_eta >= Cost_ED_All(h) ];
end
%
%% -------------------------- Constraints: ED -------------------------- %%
for h = 1:Num_Scenario
    % ED: Online or Offline?
    Con = Con + [ Var_UC_I + Var_ED_I{h} <= 1 ];
    %
    % ED: Logical relationship
    for t = 1:Num_Hour
        if t == 1
            Con = Con...
                 + [   Var_ED_I_SU{h}(:, t) - Var_ED_I_SD{h}(:, t)...
                    == Var_ED_I{h}(:, t) ];
        end
        if t >= 2
            Con = Con...
                 + [   Var_ED_I_SU{h}(:, t) - Var_ED_I_SD{h}(:, t)...
                    == Var_ED_I{h}(:, t) - Var_ED_I{h}(:, t-1) ];
        end
    end
    %
    % ED: Segment limit
    for t = 1:Num_Hour
        Con = Con...
             + [ 0 <= Var_ED_P{h}(:, t)...
                   <= Gen_Capacity(:, 3)...
                      .*(Var_UC_I(:, t) + Var_ED_I{h}(:, t)) ];
    end
    %
    % ED: Generation limit
    for t = 1:Num_Hour
        Con = Con...
             + [   Var_ED_P{h}(:, t)...
                >= Gen_Capacity(:, 4)...
                   .*(Var_UC_I(:, t) + Var_ED_I{h}(:, t)) ];
    end
    % ------------------------ Linearized part 1 ------------------------ %
    % Before
%     for t = 1:Num_Hour
%         Con = Con...
%             + [   Var_ED_P{h}(:, t)...
%                <= Gen_Capacity(:, 3).*Var_UC_I(:, t)...
%                 + Var_UC_R_C(:, t).*Var_ED_I{h}(:, t) ];
%     end
    % After
    for t = 1:Num_Hour
        Con = Con...
             + [   Var_ED_P{h}(:, t)...
                <= Gen_Capacity(:, 3).*Var_UC_I(:, t)...
                 + Var_ED_Z1{h}(:, t) ];
    end
    % Linearize
    Con = Con + [ Var_ED_Z1{h} <= Var_ED_I{h}*1000 ];
    Con = Con + [ Var_ED_Z1{h} >= 0 ];
    Con = Con + [ Var_ED_Z1{h} <= Var_UC_R_C ];
    Con = Con + [ Var_ED_Z1{h} >= Var_UC_R_C...
                                - (1 - Var_ED_I{h})*1000 ];
    %
    % ------------------------ Linearized part 1 ------------------------ %
    %
    % ------------------------ Linearized part 2 ------------------------ %
    % ED: Adjustment limit based on Hot reserve
    % Before
%     for t = 1:Num_Hour
%         Con = Con...
%             + [   Var_ED_P{h}(:, t) - Var_UC_P(:, t)...
%                <=  Var_UC_R_H(:, t).*Var_UC_I(:, t)...
%                 + Gen_Capacity(:, 3).*Var_ED_I{h}(:, t) ];
%         Con = Con...
%             + [   Var_ED_P{h}(:, t) - Var_UC_P(:, t)...
%                >= -Var_UC_R_H(:, t).*Var_UC_I(:, t)...
%                 - Gen_Capacity(:, 3).*Var_ED_I{h}(:, t) ];
%     end
    % After
    for t = 1:Num_Hour
        Con = Con...
             + [   Var_ED_P{h}(:, t) - Var_UC_P(:, t)...
                <=  Var_ED_Z2{h}(:, t)...
                 + Gen_Capacity(:, 3).*Var_ED_I{h}(:, t) ];
        Con = Con...
             + [   Var_ED_P{h}(:, t) - Var_UC_P(:, t)...
                >= -Var_ED_Z2{h}(:, t)...
                 - Gen_Capacity(:, 3).*Var_ED_I{h}(:, t) ];
    end
    % Linearize
    Con = Con + [ Var_ED_Z2{h} <= Var_UC_I*1000 ];
    Con = Con + [ Var_ED_Z2{h} >= 0 ];
    Con = Con + [ Var_ED_Z2{h} <= Var_UC_R_H ];
    Con = Con + [ Var_ED_Z2{h} >= Var_UC_R_H...
                                - (1 - Var_UC_I)*1000 ];
    % ------------------------ Linearized part 2 ------------------------ %
    %
    % ED: Ramping limit
    for t = 2:Num_Hour
        Con = Con...
             + [   Var_ED_P{h}(:, t) - Var_ED_P{h}(:, t-1)...
                <= Gen_Capacity(:, 7).*     Var_UC_I(:, t-1)...
                 + Gen_Capacity(:, 9).*(    Var_UC_I(:, t)...
                                          - Var_UC_I(:, t-1))...
                 + Gen_Capacity(:, 3).*(1 - Var_UC_I(:, t)) ];
        Con = Con...
             + [   Var_ED_P{h}(:, t-1) - Var_ED_P{h}(:, t)...
                <= Gen_Capacity(:, 8).*     Var_UC_I(:, t)...
                 + Gen_Capacity(:,10).*(    Var_UC_I(:, t-1)...
                                          - Var_UC_I(:, t))...
                 + Gen_Capacity(:, 3).*(1 - Var_UC_I(:, t-1)) ];
    end
    %
    % ED: RES curtailment limit
    Con = Con + [ 0 <= Var_ED_W{h} <= RES_Farm_Dis_ACT_Scens{h} ];
    %
    % ED: Power balance
    for t = 1:Num_Hour
        Con = Con...
             + [   sum(Var_ED_P{h}(:, t))...
                 + sum(Var_ED_W{h}(t, :))...
                 + Var_ED_S1{h}(t)...
                == sum(Load_City_Dis_ACT_Scens{h}(t, :))...
                 + Var_ED_S2{h}(t) ];
    end
    % ED: Transmission limit
    for t = 1:Num_Hour
        for b = 1:Num_Branch
            Con = Con...
                 + [   PTDF_Gen(b, :)*Var_ED_P{h}(:, t)...
                     + PTDF_RES(b, :)*Var_ED_W{h}(t, :)'...
                     - PTDF_City(b, :)*Load_City_Dis_ACT_Scens{h}(t, :)'...
                     - Var_ED_S3{h}(t, b)...
                    <= Branch(b, 5) ];
            Con = Con...
                 + [   PTDF_Gen(b, :)*Var_ED_P{h}(:, t)...
                     + PTDF_RES(b, :)*Var_ED_W{h}(t, :)'...
                     - PTDF_City(b, :)*Load_City_Dis_ACT_Scens{h}(t, :)'...
                     + Var_ED_S4{h}(t, b)...
                    >= -Branch(b, 5) ];
        end
    end
    %
    % ED: Non-negative
    Con = Con + [ Var_ED_S1{h} >= 0 ]...
              + [ Var_ED_S2{h} >= 0 ]...
              + [ Var_ED_S3{h} >= 0 ]...
              + [ Var_ED_S4{h} >= 0 ];
end
%
%% ------------------------------ Solve it ----------------------------- %%
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('Solving Outer MP: Get the Outer LB.');
disp(['Day ', num2str(Day_Dispatch)]);
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
ops = sdpsettings('solver', 'gurobi');
ops.gurobi.MIPGap = 0.01;
optimize(Con, Obj, ops);
%
%% ------------------------------ Value it ----------------------------- %%
% UC
Var_UC_I    = round(value(Var_UC_I));
Var_UC_I_SU = round(value(Var_UC_I_SU));
Var_UC_I_SD = round(value(Var_UC_I_SD));
Var_UC_I_RC = round(value(Var_UC_I_RC));
Var_UC_P    = round(value(Var_UC_P), 4);
Var_UC_W    = round(value(Var_UC_W), 4);
Var_UC_R_H  = round(value(Var_UC_R_H), 4);
Var_UC_R_C  = round(value(Var_UC_R_C), 4);
%
% ED
for h = 1:Num_Scenario
    Var_ED_I{h}    = round(value(Var_ED_I{h}));
    Var_ED_I_SU{h} = round(value(Var_ED_I_SU{h}));
    Var_ED_I_SD{h} = round(value(Var_ED_I_SD{h}));
    Var_ED_P{h}    = value(Var_ED_P{h});
    Var_ED_W{h}    = value(Var_ED_W{h});
    Var_ED_S1{h}   = value(Var_ED_S1{h});
    Var_ED_S2{h}   = value(Var_ED_S2{h});
    Var_ED_S3{h}   = value(Var_ED_S3{h});
    Var_ED_S4{h}   = value(Var_ED_S4{h});
    Var_ED_Z1{h}   = value(Var_ED_Z1{h});
    Var_ED_Z2{h}   = value(Var_ED_Z2{h});
end
%
% Others
Var_eta = value(Var_eta);
% UC Cost
Cost_UC_SU = value(Cost_UC_SU);
Cost_UC_NL = value(Cost_UC_NL);
Cost_UC_P  = value(Cost_UC_P);
Cost_UC_All = value(Cost_UC_All);% a.k.a Cost_SYS_EXP
Cost_UC_ACT = Cost_UC_SU + Cost_UC_NL;
Cost_1st_Stage = Cost_UC_All;
%
% ED cost
Cost_ED_SU = value(Cost_ED_SU);
Cost_ED_NL = value(Cost_ED_NL);
Cost_ED_P  = value(Cost_ED_P);
Cost_ED_S1 = value(Cost_ED_S1);
Cost_ED_S2 = value(Cost_ED_S2);
Cost_ED_S3 = value(Cost_ED_S3);
Cost_ED_S4 = value(Cost_ED_S4);
Cost_ED_All = value(Cost_ED_All);
%
% Obj
Obj = value(Obj);
Out_Obj_LB = Obj;
%
%% ----------------- Update Recorder: Outer Information ---------------- %%
Recorder{8, end}  = Out_Obj_LB;
Recorder{10, end} = Var_UC_I;
Recorder{11, end} = Var_UC_I_SU;
Recorder{12, end} = Var_UC_I_SD;
Recorder{13, end} = Var_UC_I_RC;
Recorder{14, end} = Var_UC_P;
Recorder{15, end} = Var_UC_W;
Recorder{16, end} = Var_UC_R_H;
Recorder{17, end} = Var_UC_R_C;
Recorder{18, end} = Cost_1st_Stage;
% Check OUT Convergence
if max(Recorder{28, end}) ~= 0 % If OUT SP has been done before?
    Cost_2nd_Stage = max(Recorder{28, end});
    for it = 1:size(Recorder, 2)
        Out_Obj_UB_Temp(it) = Recorder{7, it};
        Out_Obj_LB_Temp(it) = Recorder{8, it};
    end
    Out_Obj_UB            = min(Out_Obj_LB_Temp);
    Out_Obj_LB            = max(Out_Obj_LB_Temp);
    Out_Obj_Gap_Threshold = Recorder{30, end};
    Out_Obj_Gap           = 100*(Out_Obj_UB - Out_Obj_LB)/Out_Obj_UB;
    if Out_Obj_Gap <= Out_Obj_Gap_Threshold
        Flag_Out_Converge = 1;
    else
        Flag_Out_Converge = 0;
    end
    Recorder{9, end} = Out_Obj_Gap;
else
    Flag_Out_Converge = 0;
end
%
Recorder_Updated = [Recorder_Text Recorder];
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('Please do SP...');
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
end
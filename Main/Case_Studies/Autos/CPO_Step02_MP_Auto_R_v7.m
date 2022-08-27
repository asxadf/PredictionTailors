function...
[OVar_Phi_RES,...
 OVar_Phi_R_H,...
 OVar_Phi_R_C,...
 Bound_Lower,...
 Training_Time_MP]...
 = CPO_Step02_MP_Auto_R_v7...
 (Day_Dispatch,...
  Date_Dispatch,...
  NT,...
  NB,...
  NH,...
  lambda,...
  Iteration,...
  Enu_I,...
  Enu_I_SU,...
  Enu_I_SD,...
  Enu_I_RC,...
  Date_Tra_All,...
  M_P,...
  M_D,...
  Current_Gap,...
  Link,...
  Path_Data)
%
%% ---------------------------- Initialize ----------------------------- %%
Num_Enu = size(Enu_I, 2);
%
%% ------------------------------ Loading ------------------------------ %%
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
 Unit_Thermal] = Database_CPO_v7(Date_Dispatch, Link, Path_Data);
%
%% ----------------------------- Pick Data ----------------------------- %%
Date_Tra_Selected = Date_Tra_All{Day_Dispatch}(1:NT);
for s = 1:NT
    Day_Tra_Selected(s, 1)     = find(Date_All_List == Date_Tra_Selected(s));
    Load_Gro_SUM_Tra_ACT(:, s) = Load_Gro_SUM_All_ACT(:, Day_Tra_Selected(s));
    Load_Gro_SUM_Tra_DAF(:, s) = Load_Gro_SUM_All_DAF(:, Day_Tra_Selected(s));
    Load_City_Tra_ACT(:, s)    = Load_City_All_ACT(Day_Tra_Selected(s));
    Load_City_Tra_DAF(:, s)    = Load_City_All_DAF(Day_Tra_Selected(s));
    RES_SUM_Tra_ACT(:, s)      = RES_SUM_All_ACT(:, Day_Tra_Selected(s));
    RES_SUM_Tra_DAF(:, s)      = RES_SUM_All_DAF(:, Day_Tra_Selected(s));
    RES_Farm_Tra_ACT{s, 1}     = RES_Farm_All_ACT{Day_Tra_Selected(s)};
    RES_Farm_Tra_DAF{s, 1}     = RES_Farm_All_DAF{Day_Tra_Selected(s)};
    R_H_Req_Tra(:, s)          = R_H_Req_All(:, Day_Tra_Selected(s));
    R_C_Req_Tra(:, s)          = R_C_Req_All(:, Day_Tra_Selected(s));
    Load_Net_SUM_Tra_ACT(:, s) = Load_Net_SUM_All_ACT(:, Day_Tra_Selected(s));
    Load_Net_SUM_Tra_DAF(:, s) = Load_Net_SUM_All_DAF(:, Day_Tra_Selected(s));
end
Load_Net_SUM_AE  = abs(Load_Net_SUM_All_ACT - Load_Net_SUM_All_DAF);
Load_Net_SUM_AE  = Load_Net_SUM_AE(:, Day_Dispatch-NH : Day_Dispatch-1);
Load_Net_SUM_APE = Load_Net_SUM_AE./Load_Net_SUM_All_ACT(:, Day_Dispatch-NH : Day_Dispatch-1);

Load_Net_SUM_OE = Load_Net_SUM_All_DAF - Load_Net_SUM_All_ACT;
Load_Net_SUM_OE = Load_Net_SUM_OE(:, Day_Dispatch-NH : Day_Dispatch-1);
Load_Net_SUM_OE(Load_Net_SUM_OE < 0) = 0;
Load_Net_SUM_OPE = Load_Net_SUM_OE./Load_Net_SUM_All_ACT(:, Day_Dispatch-NH : Day_Dispatch-1);
Load_Net_SUM_OPE = Load_Net_SUM_OPE(:);
Load_Net_SUM_OPE(Load_Net_SUM_OPE == 0) = [];

Quantile_For_RH = quantile(Load_Net_SUM_OPE, 0.90);
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
for t = 1:Num_Hour
    Quantile_For_RC(t, 1) = quantile(Load_Net_SUM_APE(t, :), 0.75);
    disp(['Hour', num2str(t), ': Non-Spinning reserve predictor bound is ',  num2str(Quantile_For_RC(t, 1))]);
end
if max(Quantile_For_RC(:)) >= 0.15
    Quantile_For_RC = 0.15;
end
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp(['Final spinning reserve predictor bound is ', num2str(Quantile_For_RH)]);
disp(['Final non-spinning reserve predictor bound is ',  num2str(max(Quantile_For_RC(:)))]);
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
%
%% ------------------- Outer Training & ED: Variable ------------------- %%
% Predictors
OVar_Phi_RES = sdpvar(Num_Hour, Num_RES);
OVar_Phi_R_H = sdpvar(Num_Hour, 1);
OVar_Phi_R_C = sdpvar(Num_Hour, 1);
% Predictions
for s = 1:NT
    OVar_Pre_RES_Avai{s, 1} = sdpvar(Num_Hour, Num_RES);
    OVar_Pre_R_H_Need{s, 1} = sdpvar(Num_Hour, 1);
    OVar_Pre_R_C_Need{s, 1} = sdpvar(Num_Hour, 1);
end
%
% ED
for s = 1:NT
    OVar_ED_I{s, 1}    = binvar(Num_Gen, Num_Hour);
    OVar_ED_I_SU{s, 1} = binvar(Num_Gen, Num_Hour);
    OVar_ED_I_SD{s, 1} = binvar(Num_Gen, Num_Hour);
    OVar_ED_P{s, 1}    = sdpvar(Num_Gen, Num_Hour);
    OVar_ED_W{s, 1}    = sdpvar(Num_Hour, Num_RES);
    OVar_ED_S1{s, 1}   = sdpvar(Num_Hour, 1);
    OVar_ED_S2{s, 1}   = sdpvar(Num_Hour, 1);
    OVar_ED_S3{s, 1}   = sdpvar(Num_Hour, Num_Branch);
    OVar_ED_S4{s, 1}   = sdpvar(Num_Hour, Num_Branch);
    OVar_ED_Z1{s, 1}   = sdpvar(Num_Gen, Num_Hour);
    OVar_ED_Z2{s, 1}   = sdpvar(Num_Gen, Num_Hour);
end
%
%% --------------------- Duplication UC: Variables --------------------- %%
for s = 1:NT
    DVar_UC_I{s, 1}    = binvar(Num_Gen, Num_Hour);
    DVar_UC_I_SU{s, 1} = binvar(Num_Gen, Num_Hour);
    DVar_UC_I_SD{s, 1} = binvar(Num_Gen, Num_Hour);
    DVar_UC_I_RC{s, 1} = binvar(Num_Gen, Num_Hour);
    DVar_UC_P{s, 1}    = sdpvar(Num_Gen, Num_Hour);
    DVar_UC_W{s, 1}    = sdpvar(Num_Hour, Num_RES);
    DVar_UC_R_H{s, 1}  = sdpvar(Num_Gen, Num_Hour);
    DVar_UC_R_C{s, 1}  = sdpvar(Num_Gen, Num_Hour);
end
%
%% ------------------- Inner UC: Variable Generation ------------------- %%
for s = 1:NT
    for e = 1:Num_Enu
        % UC: Enumerated binary variable (Fixed)
        IVar_UC_I{s, e}    = Enu_I{s, e};
        IVar_UC_I_SU{s, e} = Enu_I_SU{s, e};
        IVar_UC_I_SD{s, e} = Enu_I_SD{s, e};
        IVar_UC_I_RC{s, e} = Enu_I_RC{s, e};
        % UC: Generated continue variable (TBD)
        IVar_UC_P{s, e}   = sdpvar(Num_Gen, Num_Hour);
        IVar_UC_W{s, e}   = sdpvar(Num_Hour, Num_RES);
        IVar_UC_R_H{s, e} = sdpvar(Num_Gen, Num_Hour);
        IVar_UC_R_C{s, e} = sdpvar(Num_Gen, Num_Hour);
    end
end
%
%% ------------------ Outer Training & ED: Objective ------------------- %%
% Actual system cost
for s = 1:NT
    OObj_Cost_UC_SU(s, 1) = Gen_Price(:, 5)'*sum(DVar_UC_I_SU{s}, 2);
    OObj_Cost_UC_NL(s, 1) = Gen_Price(:, 2)'*sum(DVar_UC_I{s}, 2);
    OObj_Cost_UC_RH(s, 1) = Gen_Price(:, 7)'*sum(DVar_UC_R_H{s}, 2);
    OObj_Cost_UC_RC(s, 1) = Gen_Price(:, 8)'*sum(DVar_UC_R_C{s}, 2);
    OObj_Cost_ED_SU(s, 1) = Gen_Price(:, 5)'*sum(OVar_ED_I_SU{s}, 2);
    OObj_Cost_ED_NL(s, 1) = Gen_Price(:, 2)'*sum(OVar_ED_I{s}, 2);
    OObj_Cost_ED_P(s, 1)  = Gen_Price(:, 3)'*sum(OVar_ED_P{s}, 2);
    OObj_Cost_ED_S1(s, 1) = LS_Price*sum(OVar_ED_S1{s});
    OObj_Cost_ED_S2(s, 1) = GS_Price*sum(OVar_ED_S2{s});
    OObj_Cost_ED_S3(s, 1) = BS_Price*sum(OVar_ED_S3{s}(:));
    OObj_Cost_ED_S4(s, 1) = BS_Price*sum(OVar_ED_S4{s}(:));
    OObj_Cost_UC_ACT(s, 1) = OObj_Cost_UC_SU(s)...
                           + OObj_Cost_UC_NL(s)...
                           + OObj_Cost_UC_RH(s)...
                           + OObj_Cost_UC_RC(s);
    OObj_Cost_ED_ACT(s, 1) = OObj_Cost_ED_SU(s)...
                           + OObj_Cost_ED_NL(s)...
                           + OObj_Cost_ED_P(s)...
                           + OObj_Cost_ED_S1(s)...
                           + OObj_Cost_ED_S2(s)...
                           + OObj_Cost_ED_S3(s)...
                           + OObj_Cost_ED_S4(s);
end
OObj_Cost_SYS_ACT = OObj_Cost_UC_ACT + OObj_Cost_ED_ACT;
OObj_Reg = lambda*norm(OVar_Phi_RES, 1);
OObj = sum(OObj_Cost_SYS_ACT)/NT + OObj_Reg;
%
%% --------------------- Duplication UC: Objective --------------------- %%
% UC cost
for s = 1:NT
    DObj_Cost_UC_SU(s, 1) = Gen_Price(:, 5)'*sum(DVar_UC_I_SU{s}, 2);
    DObj_Cost_UC_NL(s, 1) = Gen_Price(:, 2)'*sum(DVar_UC_I{s}, 2);
    DObj_Cost_UC_P(s, 1)  = Gen_Price(:, 3)'*sum(DVar_UC_P{s}, 2);
    DObj_Cost_UC_RH(s, 1) = Gen_Price(:, 7)'*sum(DVar_UC_R_H{s}, 2);
    DObj_Cost_UC_RC(s, 1) = Gen_Price(:, 8)'*sum(DVar_UC_R_C{s}, 2);
end
DObj_Cost_SYS_EXP = DObj_Cost_UC_SU + DObj_Cost_UC_NL...
                  + DObj_Cost_UC_P...
                  + DObj_Cost_UC_RH + DObj_Cost_UC_RC;
%
%% ------------------------ Inner UC: Objective ------------------------ %%
% Enumerated and generated UC objective
for s = 1:NT
    for e = 1:Num_Enu
        IObj_Cost_UC_SU(s, e) = Gen_Price(:, 5)'*sum(IVar_UC_I_SU{s, e}, 2);
        IObj_Cost_UC_NL(s, e) = Gen_Price(:, 2)'*sum(IVar_UC_I{s, e}, 2);
        IObj_Cost_UC_P(s, e)  = Gen_Price(:, 3)'*sum(IVar_UC_P{s, e}, 2);
        IObj_Cost_UC_RH(s, e) = Gen_Price(:, 7)'*sum(IVar_UC_R_H{s, e}, 2);
        IObj_Cost_UC_RC(s, e) = Gen_Price(:, 8)'*sum(IVar_UC_R_C{s, e}, 2);
    end
end
IObj_Cost_SYS_EXP = IObj_Cost_UC_SU + IObj_Cost_UC_NL...
                  + IObj_Cost_UC_P...
                  + IObj_Cost_UC_RH + IObj_Cost_UC_RC;
%
%% ------------------ Outer Training & ED: Constraint ------------------ %%
OCon = [];
% Predictors
OCon = OCon + [               1 <= OVar_Phi_RES <= 1 ]; 
OCon = OCon + [ Quantile_For_RH <= OVar_Phi_R_H      ];
OCon = OCon + [ Quantile_For_RC <= OVar_Phi_R_C      ];
%
% Training: Predictions
for s = 1:NT
    OCon = OCon + [ OVar_Pre_RES_Avai{s} == OVar_Phi_RES.*RES_Farm_Tra_DAF{s} ];
    OCon = OCon + [ OVar_Pre_R_H_Need{s} == OVar_Phi_R_H.*Load_Net_SUM_Tra_DAF(:, s) ];
    OCon = OCon + [ OVar_Pre_R_C_Need{s} == OVar_Phi_R_C.*Load_Net_SUM_Tra_DAF(:, s) ];
end
%
%
% Fixing strategy
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('Solving MP: Get the LB and predictors.');
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');

if NB == 1 
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    disp('Only one block');
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    OCon = OCon + [ OVar_Phi_R_H(1) == OVar_Phi_R_H(2:end) ];
    OCon = OCon + [ OVar_Phi_R_C(1) == OVar_Phi_R_C(2:end) ];
else
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    disp('Two blocks');
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    % Block 1
    OCon = OCon + [ OVar_Phi_R_H(1:3)   == OVar_Phi_R_H(24)  ];
    OCon = OCon + [ OVar_Phi_R_H(20:23) == OVar_Phi_R_H(24)  ];
    OCon = OCon + [ OVar_Phi_R_C(1:3)   == OVar_Phi_R_C(24)  ];
    OCon = OCon + [ OVar_Phi_R_C(20:23) == OVar_Phi_R_C(24)  ];
    % Block 2
    OCon = OCon + [ OVar_Phi_R_H(4) == OVar_Phi_R_H(5:19) ];
    OCon = OCon + [ OVar_Phi_R_C(4) == OVar_Phi_R_C(5:19) ];
end
%
% Training: For reserve
for s = 1:NT
    % For duplicated UC
    OCon = OCon + [ sum(DVar_UC_R_H{s})' <= OVar_Pre_R_H_Need{s} ];
    OCon = OCon + [ sum(DVar_UC_R_C{s})' <= OVar_Pre_R_C_Need{s} ];
    % For inner UC
    OCon = OCon + [ sum(IVar_UC_R_H{s})' <= OVar_Pre_R_H_Need{s} ];
    OCon = OCon + [ sum(IVar_UC_R_C{s})' <= OVar_Pre_R_C_Need{s} ];
end
%
% ED
for s = 1:NT
    % ED: Online or Offline?
    OCon = OCon + [ DVar_UC_I{s} + OVar_ED_I{s} <= 1 ];
    %
    % ED: Logical relationship
    for t = 1:Num_Hour
        if t == 1
            OCon = OCon...
                 + [   OVar_ED_I_SU{s}(:, t) - OVar_ED_I_SD{s}(:, t)...
                    == OVar_ED_I{s}(:, t) ];
        end
        if t >= 2
            OCon = OCon...
                 + [   OVar_ED_I_SU{s}(:, t) - OVar_ED_I_SD{s}(:, t)...
                    == OVar_ED_I{s}(:, t) - OVar_ED_I{s}(:, t-1) ];
        end
    end
    %
    % ED: Segment limit
    for t = 1:Num_Hour
        OCon = OCon...
             + [ 0 <= OVar_ED_P{s}(:, t)...
                   <= Gen_Capacity(:, 3)...
                      .*(DVar_UC_I{s}(:, t) + OVar_ED_I{s}(:, t)) ];
    end
    %
    % ED: Generation limit
    for t = 1:Num_Hour
        OCon = OCon...
             + [   OVar_ED_P{s}(:, t)...
                >= Gen_Capacity(:, 4)...
                   .*(DVar_UC_I{s}(:, t) + OVar_ED_I{s}(:, t)) ];
    end
    % ------------------------ Linearized part 1 ------------------------ %
    % Before
    % for t = 1:Num_Hour
    %     OCon = OCon...
    %          + [   OVar_ED_P{s}(:, t)...
    %             <= Gen_Capacity(:, 3).*DVar_UC_I{s}(:, t)...
    %              + DVar_UC_R_C{s}(:, t).*OVar_ED_I{s}(:, t) ];
    % end
    % After
    for t = 1:Num_Hour
        OCon = OCon...
             + [   OVar_ED_P{s}(:, t)...
                <= Gen_Capacity(:, 3).*DVar_UC_I{s}(:, t)...
                 + OVar_ED_Z1{s}(:, t) ];
    end
    % Linearize
    OCon = OCon + [ OVar_ED_Z1{s} <= OVar_ED_I{s}*M_P ];
    OCon = OCon + [ OVar_ED_Z1{s} >= 0 ];
    OCon = OCon + [ OVar_ED_Z1{s} <= DVar_UC_R_C{s} ];
    OCon = OCon + [ OVar_ED_Z1{s} >= DVar_UC_R_C{s}...
                                   - (1 - OVar_ED_I{s})*M_P ];
    %
    % ------------------------ Linearized part 1 ------------------------ %
    %
    % ------------------------ Linearized part 2 ------------------------ %
    % ED: Adjustment limit based on Hot reserve
    % Before
    %     for t = 1:Num_Hour
%         OCon = OCon...
%              + [   OVar_ED_P{s}(:, t) - DVar_UC_P{s}(:, t)...
%                 <=  DVar_UC_R_H{s}(:, t).*DVar_UC_I{s}(:, t)...
%                  + Gen_Capacity(:, 3).*OVar_ED_I{s}(:, t) ];
%         OCon = OCon...
%              + [   OVar_ED_P{s}(:, t) - DVar_UC_P{s}(:, t)...
%                 >= -DVar_UC_R_H{s}(:, t).*DVar_UC_I{s}(:, t)
%                  - Gen_Capacity(:, 3).*OVar_ED_I{s}(:, t) ];
%     end
    % After
    for t = 1:Num_Hour
        OCon = OCon...
             + [   OVar_ED_P{s}(:, t) - DVar_UC_P{s}(:, t)...
                <=  OVar_ED_Z2{s}(:, t)...
                 + Gen_Capacity(:, 3).*OVar_ED_I{s}(:, t) ];
        OCon = OCon...
             + [   OVar_ED_P{s}(:, t) - DVar_UC_P{s}(:, t)...
                >= -OVar_ED_Z2{s}(:, t)...
                 - Gen_Capacity(:, 3).*OVar_ED_I{s}(:, t) ];
    end
    % Linearize
    OCon = OCon + [ OVar_ED_Z2{s} <= DVar_UC_I{s}*M_P ];
    OCon = OCon + [ OVar_ED_Z2{s} >= 0 ];
    OCon = OCon + [ OVar_ED_Z2{s} <= DVar_UC_R_H{s} ];
    OCon = OCon + [ OVar_ED_Z2{s} >= DVar_UC_R_H{s}...
                                   - (1 - DVar_UC_I{s})*M_P ];
    % ------------------------ Linearized part 2 ------------------------ %
    %
    % ED: Ramping limit
    for t = 2:Num_Hour
        OCon = OCon...
             + [   OVar_ED_P{s}(:, t) - OVar_ED_P{s}(:, t-1)...
                <= Gen_Capacity(:, 7).*     DVar_UC_I{s}(:, t-1)...
                 + Gen_Capacity(:, 9).*(    DVar_UC_I{s}(:, t)...
                                          - DVar_UC_I{s}(:, t-1))...
                 + Gen_Capacity(:, 3).*(1 - DVar_UC_I{s}(:, t)) ];
        OCon = OCon...
             + [   OVar_ED_P{s}(:, t-1) - OVar_ED_P{s}(:, t)...
                <= Gen_Capacity(:, 8).*     DVar_UC_I{s}(:, t)...
                 + Gen_Capacity(:,10).*(    DVar_UC_I{s}(:, t-1)...
                                          - DVar_UC_I{s}(:, t))...
                 + Gen_Capacity(:, 3).*(1 - DVar_UC_I{s}(:, t-1)) ];
    end
    %
    % ED: RES curtailment limit
    OCon = OCon + [ 0 <= OVar_ED_W{s} <= RES_Farm_Tra_ACT{s} ];
    %
    % ED: Power balance
    for t = 1:Num_Hour
        OCon = OCon...
             + [   sum(OVar_ED_P{s}(:, t))...
                 + sum(OVar_ED_W{s}(t, :))...
                 + OVar_ED_S1{s}(t)...
                == sum(Load_City_Tra_ACT{s}(t, :))...
                 + OVar_ED_S2{s}(t) ];
    end
    % ED: Transmission limit
    for t = 1:Num_Hour
        OCon = OCon...
             + [   PTDF_Gen*OVar_ED_P{s}(:, t)...
                 + PTDF_RES*OVar_ED_W{s}(t, :)'...
                 - PTDF_City*Load_City_Tra_ACT{s}(t, :)'...
                 - OVar_ED_S3{s}(t, :)'...
                <= Branch(:, 5) ];
        OCon = OCon...
             + [   PTDF_Gen*OVar_ED_P{s}(:, t)...
                 + PTDF_RES*OVar_ED_W{s}(t, :)'...
                 - PTDF_City*Load_City_Tra_ACT{s}(t, :)'...
                 + OVar_ED_S4{s}(t, :)'...
                >= -Branch(:, 5) ];
    end
    %
    % ED: Non-negative
    OCon = OCon + [ OVar_ED_S1{s} >= 0 ]...
                + [ OVar_ED_S2{s} >= 0 ]...
                + [ OVar_ED_S3{s} >= 0 ]...
                + [ OVar_ED_S4{s} >= 0 ];
end
%
%% -------------------- Duplication UC: Constraints -------------------- %%
DCon = [];
% UC: Per scenario
for s = 1:NT
    % UC: Generation limit
    for t = 1:Num_Hour
        DCon = DCon...
             + [   DVar_UC_P{s}(:, t) - DVar_UC_R_H{s}(:, t)...
                >= Gen_Capacity(:, 4).*DVar_UC_I{s}(:, t) ];
        DCon = DCon...
             + [   DVar_UC_P{s}(:, t) + DVar_UC_R_H{s}(:, t)...
                <= Gen_Capacity(:, 3).*DVar_UC_I{s}(:, t) ];
    end
    %
    % UC: Segment limit
    for t = 1:Num_Hour
        DCon = DCon...
             + [ 0 <= DVar_UC_P{s}(:, t)...
                   <= Gen_Capacity(:, 3).*DVar_UC_I{s}(:, t) ];
    end
    %
    % UC: Hot reserve limit
    for t = 1:Num_Hour
        DCon = DCon...
             + [ 0 <= DVar_UC_R_H{s}(:, t)...
                   <= Gen_Capacity(:, 11).*DVar_UC_I{s}(:, t) ];
    end
    %
    % UC: Cool reserve limit
    for t = 1:Num_Hour
        DCon = DCon...
             + [   DVar_UC_R_C{s}(:, t)...
                >= Gen_Capacity(:, 4).*DVar_UC_I_RC{s}(:, t) ];
        DCon = DCon...
             + [   DVar_UC_R_C{s}(:, t)...
                <= Gen_Capacity(:,12).*DVar_UC_I_RC{s}(:, t) ];
    end
    % UC: Cool reserve flag
    DCon = DCon + [ DVar_UC_I_RC{s} + DVar_UC_I{s} <= 1 ];
    %
    % UC: Logical relationship
    for t = 1:Num_Hour
        if t == 1
            DCon = DCon...
                 + [   DVar_UC_I_SU{s}(:, t) - DVar_UC_I_SD{s}(:, t)...
                    == DVar_UC_I{s}(:, t) ];
        end
        if t >= 2
            DCon = DCon...
                 + [   DVar_UC_I_SU{s}(:, t) - DVar_UC_I_SD{s}(:, t)...
                    == DVar_UC_I{s}(:, t) - DVar_UC_I{s}(:, t-1) ];
        end
    end
    %
    % UC: Min ON/OFF
    for i = 1:Num_Gen
        % Min ON
        for t = Gen_Capacity(i, 5):Num_Hour
            DCon = DCon...
                 + [   sum(DVar_UC_I_SU{s}(i, t-Gen_Capacity(i, 5)+1:t))...
                    <= DVar_UC_I{s}(i, t) ];
        end
        % Min OFF
        for t = Gen_Capacity(i, 6):Num_Hour
            DCon = DCon...
                 + [   sum(DVar_UC_I_SD{s}(i, t-Gen_Capacity(i, 6)+1:t))...
                    <= 1 - DVar_UC_I{s}(i, t) ];
        end
    end
    %
    % UC: Ramping limit
    for t = 2:Num_Hour
        DCon = DCon...
             + [   DVar_UC_P{s}(:, t) - DVar_UC_P{s}(:, t-1)...
                <= Gen_Capacity(:, 7).*     DVar_UC_I{s}(:, t-1)...
                 + Gen_Capacity(:, 9).*(    DVar_UC_I{s}(:, t)...
                                          - DVar_UC_I{s}(:, t-1))...
                 + Gen_Capacity(:, 3).*(1 - DVar_UC_I{s}(:, t)) ];
        DCon = DCon...
             + [   DVar_UC_P{s}(:, t-1) - DVar_UC_P{s}(:, t)...
                <= Gen_Capacity(:, 8).*     DVar_UC_I{s}(:, t)...
                 + Gen_Capacity(:,10).*(    DVar_UC_I{s}(:, t-1)...
                                          - DVar_UC_I{s}(:, t))...
                 + Gen_Capacity(:, 3).*(1 - DVar_UC_I{s}(:, t-1)) ];
    end
    %
    % UC: RES curtailment limit
    DCon = DCon...
         + [ 0 <= DVar_UC_W{s} <= OVar_Pre_RES_Avai{s} ];
    % 
    % UC: Thermal untis
    for i = Unit_Thermal
        DCon = DCon...
             + [ DVar_UC_I_RC{s}(i, :) == 0];
    end
    %
    % UC: Power balance
    for t = 1:Num_Hour
        DCon = DCon...
             + [   sum(DVar_UC_P{s}(:, t))...
                 + sum(DVar_UC_W{s}(t, :))...   
                == sum(Load_City_Tra_DAF{s}(t, :)) ];
    end
    %
    % UC: Transmission limit
    for t = 1:Num_Hour
        DCon = DCon...
             + [ - Branch(:, 5)...
                <= PTDF_Gen*DVar_UC_P{s}(:, t)...
                 + PTDF_RES*DVar_UC_W{s}(t, :)'...
                 - PTDF_City*Load_City_Tra_DAF{s}(t, :)'...
                <= Branch(:, 5) ];
    end
    %
    % UC: Reserve requirement
    DCon = DCon + [   sum(DVar_UC_R_H{s})' >= OVar_Pre_R_H_Need{s} ];
    DCon = DCon + [   sum(DVar_UC_R_H{s})' + sum(DVar_UC_R_C{s})'...
                   >= OVar_Pre_R_H_Need{s} + OVar_Pre_R_C_Need{s} ];   
    %
end
%% --------------- Inner UC: Constraint Generation --------------- %%
% Obj cut
ICon_Cut = [];
for s = 1:NT
    for e = 1:Num_Enu
        ICon_Cut = ICon_Cut...
                 + [ DObj_Cost_SYS_EXP(s) <= IObj_Cost_SYS_EXP(s, e) ];
    end
end
% Inner UC feasibility
for s = 1:NT
    for e = 1:Num_Enu
        ICon_Fea{s, e} = [];
        % UC: Generation limit
        for t = 1:Num_Hour
            ICon_Fea{s, e} = ICon_Fea{s, e}...
                           + [   IVar_UC_P{s, e}(:, t) - IVar_UC_R_H{s, e}(:, t)...
                              >= Gen_Capacity(:, 4).*IVar_UC_I{s, e}(:, t) ];
            ICon_Fea{s, e} = ICon_Fea{s, e}...
                           + [   IVar_UC_P{s, e}(:, t) + IVar_UC_R_H{s, e}(:, t)...
                              <= Gen_Capacity(:, 3).*IVar_UC_I{s, e}(:, t)];
        end
        %
        % UC: Segment limit
        for t = 1:Num_Hour
            ICon_Fea{s, e} = ICon_Fea{s, e}...
                           + [ 0 <= IVar_UC_P{s, e}(:, t)...
                                 <= Gen_Capacity(:, 3).*IVar_UC_I{s, e}(:, t) ];
        end
        %
        % UC: Hot reserve limit
        for t = 1:Num_Hour
            ICon_Fea{s, e} = ICon_Fea{s, e}...
                           + [ 0 <= IVar_UC_R_H{s, e}(:, t)...
                                 <= Gen_Capacity(:, 11).*IVar_UC_I{s, e}(:, t) ];
        end
        %
        % UC: Cool reserve limit
        for t = 1:Num_Hour
            ICon_Fea{s, e} = ICon_Fea{s, e}...
                           + [   IVar_UC_R_C{s, e}(:, t)...
                              >= Gen_Capacity(:, 4).*IVar_UC_I_RC{s, e}(:, t) ];
            ICon_Fea{s, e} = ICon_Fea{s, e}...
                           + [   IVar_UC_R_C{s, e}(:, t)...
                              <= Gen_Capacity(:,12).*IVar_UC_I_RC{s, e}(:, t) ];
        end
        %
        % UC: Ramping limit
        for t = 2:Num_Hour
            ICon_Fea{s, e} = ICon_Fea{s, e}...
                           + [   IVar_UC_P{s, e}(:, t) - IVar_UC_P{s, e}(:, t-1)...
                              <= Gen_Capacity(:, 7).*     IVar_UC_I{s, e}(:, t-1)...
                               + Gen_Capacity(:, 9).*(    IVar_UC_I{s, e}(:, t)...
                                                        - IVar_UC_I{s, e}(:, t-1))...
                               + Gen_Capacity(:, 3).*(1 - IVar_UC_I{s, e}(:, t)) ];
            ICon_Fea{s, e} = ICon_Fea{s, e}...
                           + [   IVar_UC_P{s, e}(:, t-1) - IVar_UC_P{s, e}(:, t)...
                              <= Gen_Capacity(:, 8).*     IVar_UC_I{s, e}(:, t)...
                               + Gen_Capacity(:,10).*(    IVar_UC_I{s, e}(:, t-1)...
                                                        - IVar_UC_I{s, e}(:, t))...
                               + Gen_Capacity(:, 3).*(1 - IVar_UC_I{s, e}(:, t-1))];
        end
        %
        % UC: RES curtailment limit
        ICon_Fea{s, e} = ICon_Fea{s, e}...
                       + [ 0 <= IVar_UC_W{s, e} <= OVar_Pre_RES_Avai{s} ];
        %
        % UC: Power balance
        for t = 1:Num_Hour
            ICon_Fea{s, e} = ICon_Fea{s, e}...
                           + [   sum(IVar_UC_P{s, e}(:, t))...
                               + sum(IVar_UC_W{s, e}(t, :))...
                              == sum(Load_City_Tra_DAF{s}(t, :)) ];
        end
        %
        % UC: Transmission limit
        for t = 1:Num_Hour
            ICon_Fea{s, e} = ICon_Fea{s, e}...
                           + [ - Branch(:, 5)...
                              <= PTDF_Gen*IVar_UC_P{s, e}(:, t)...
                               + PTDF_RES*IVar_UC_W{s, e}(t, :)'...
                               - PTDF_City*Load_City_Tra_DAF{s}(t, :)'...
                              <= Branch(:, 5) ];
        end
        %
        % UC: Reserve requirement
        ICon_Fea{s, e} = ICon_Fea{s, e}...
                       + [ sum(IVar_UC_R_H{s, e})' >= OVar_Pre_R_H_Need{s} ];
        ICon_Fea{s, e} = ICon_Fea{s, e}...
                       + [   sum(IVar_UC_R_H{s, e})' + sum(IVar_UC_R_C{s, e})'...
                          >= OVar_Pre_R_H_Need{s} + OVar_Pre_R_C_Need{s} ];
        %
        %% -------------------------- KKT -------------------------- %%
        [KKT_System{s, e}, KKT_Details{s, e}] =...
        kkt(ICon_Fea{s, e}, IObj_Cost_SYS_EXP(s, e), [ OVar_Phi_RES(:);
                                                       OVar_Phi_R_H;
                                                       OVar_Phi_R_C;
                                                       OVar_Pre_RES_Avai{s}(:);
                                                       OVar_Pre_R_H_Need{s};
                                                       OVar_Pre_R_C_Need{s}]);
        % Stationarity
        KKT_Station{s, e} = KKT_System{s, e}(3);
        % Primal feasibility
        KKT_P_Fea{s, e} = KKT_Details{s, e}.inequalities...
                        + KKT_Details{s, e}.equalities;
        % Dual feasibility
        KKT_D_Fea{s, e} = [ KKT_Details{s, e}.dual >= 0 ];
        % Complementarities
        u{s, e} = binvar(size(KKT_Details{s, e}.A, 1), 1);
        KKT_Comple{s, e} = [  KKT_Details{s, e}.dual <= M_D*u{s, e} ]...
                         + [  KKT_Details{s, e}.A*KKT_Details{s, e}.primal...
                            - KKT_Details{s, e}.b    >= M_P*(u{s, e} - 1) ];
        % SUM
        ICon_KKT{s, e} = KKT_Station{s, e} + KKT_P_Fea{s, e}...
                       + KKT_D_Fea{s, e}   + KKT_Comple{s, e};
    end
end
%
%% ------------------------------ Solve It ----------------------------- %%
Con = OCon + DCon + ICon_Cut;
for s = 1:NT
   for e = 1:Num_Enu
       Con = Con + ICon_KKT{s, e};
   end
end
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('Solving MP: Get the LB and predictors.');
disp(['This is the #', num2str(Iteration), ' iteration for MP...']);
disp(['Current gap: ', num2str(Current_Gap), '%']);
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
ops = sdpsettings('solver', 'gurobi');
ops.gurobi.MIPGap = 0.01;
ops.gurobi.TimeLimit = 60*60;
sol = optimize(Con, OObj, ops);
Training_Time_MP = sol.solvertime;
%
%% ------------------------------ Value It ----------------------------- %%
% Predictor
OVar_Phi_RES = value(OVar_Phi_RES);
OVar_Phi_R_H = value(OVar_Phi_R_H);
OVar_Phi_R_C = value(OVar_Phi_R_C);
for s = 1:NT
    % Prediction
    OVar_Pre_RES_Avai{s} = value(OVar_Pre_RES_Avai{s});
    OVar_Pre_R_H_Need{s} = value(OVar_Pre_R_H_Need{s});
    OVar_Pre_R_C_Need{s} = value(OVar_Pre_R_C_Need{s});
    % ED
    OVar_ED_I{s}    = value(OVar_ED_I{s});
    OVar_ED_I_SU{s} = value(OVar_ED_I_SU{s});
    OVar_ED_I_SD{s} = value(OVar_ED_I_SD{s});
    OVar_ED_P{s}    = value(OVar_ED_P{s});
    OVar_ED_W{s}    = value(OVar_ED_W{s});
    OVar_ED_S1{s}   = value(OVar_ED_S1{s});
    OVar_ED_S2{s}   = value(OVar_ED_S2{s});
    OVar_ED_S3{s}   = value(OVar_ED_S3{s});
    OVar_ED_S4{s}   = value(OVar_ED_S4{s});
    OVar_ED_Z1{s}   = value(OVar_ED_Z1{s});
    OVar_ED_Z2{s}   = value(OVar_ED_Z2{s});
    % Duplicated UC
    DVar_UC_I{s}    = round(value(DVar_UC_I{s}));
    DVar_UC_I_SU{s} = round(value(DVar_UC_I_SU{s}));
    DVar_UC_I_SD{s} = round(value(DVar_UC_I_SD{s}));
    DVar_UC_I_RC{s} = round(value(DVar_UC_I_RC{s}));
    DVar_UC_P{s}    = value(DVar_UC_P{s});
    DVar_UC_W{s}    = value(DVar_UC_W{s});
    DVar_UC_R_H{s}  = value(DVar_UC_R_H{s});
    DVar_UC_R_C{s}  = value(DVar_UC_R_C{s});
    % Inner UC
    for e = 1:Num_Enu
        IVar_UC_P{s, e}   = value(IVar_UC_P{s, e});
        IVar_UC_W{s, e}   = value(IVar_UC_W{s, e});
        IVar_UC_R_H{s, e} = value(IVar_UC_R_H{s, e});
        IVar_UC_R_C{s, e} = value(IVar_UC_R_C{s, e});
    end
    % KKT
    for e = 1:Num_Enu
        KKT_Var_Dual{s, e} = ceil(value(KKT_Details{s, e}.dual));
        KKT_Var_Prim{s, e} = value(KKT_Details{s, e}.primal);
        KKT_Pra_RHS{s, e}  = value(KKT_Details{s, e}.b);
        KKT_Pra_Axb{s, e}  = KKT_Details{s, e}.A*KKT_Var_Prim{s, e}...
                           - KKT_Pra_RHS{s, e};
        u{s, e} = value(u{s, e});
    end
end
%
% Outer cost
OObj_Cost_UC_SU   = value(OObj_Cost_UC_SU);
OObj_Cost_UC_NL   = value(OObj_Cost_UC_NL);
OObj_Cost_UC_RH   = value(OObj_Cost_UC_RH);
OObj_Cost_UC_RC   = value(OObj_Cost_UC_RC);
OObj_Cost_ED_SU   = value(OObj_Cost_ED_SU);
OObj_Cost_ED_NL   = value(OObj_Cost_ED_NL);
OObj_Cost_ED_P    = value(OObj_Cost_ED_P);
OObj_Cost_ED_S1   = value(OObj_Cost_ED_S1);
OObj_Cost_ED_S2   = value(OObj_Cost_ED_S2);
OObj_Cost_ED_S3   = value(OObj_Cost_ED_S3);
OObj_Cost_ED_S4   = value(OObj_Cost_ED_S4);
OObj_Cost_UC_ACT  = value(OObj_Cost_UC_ACT);
OObj_Cost_ED_ACT  = value(OObj_Cost_ED_ACT);
OObj_Cost_SYS_ACT = value(OObj_Cost_SYS_ACT);
OObj_Reg          = value(OObj_Reg);
OObj              = value(OObj);
Bound_Lower       = OObj;
%
% Duplicayed cost
DObj_Cost_UC_SU   = value(DObj_Cost_UC_SU);
DObj_Cost_UC_NL   = value(DObj_Cost_UC_NL);
DObj_Cost_UC_P    = value(DObj_Cost_UC_P);
DObj_Cost_UC_RH   = value(DObj_Cost_UC_RH);
DObj_Cost_UC_RC   = value(DObj_Cost_UC_RC);
DObj_Cost_SYS_EXP = value(DObj_Cost_SYS_EXP);
%
% Inner cost
IObj_Cost_UC_SU   = value(IObj_Cost_UC_SU);
IObj_Cost_UC_NL   = value(IObj_Cost_UC_NL);
IObj_Cost_UC_P    = value(IObj_Cost_UC_P);
IObj_Cost_UC_RH   = value(IObj_Cost_UC_RH);
IObj_Cost_UC_RC   = value(IObj_Cost_UC_RC);
IObj_Cost_SYS_EXP = value(IObj_Cost_SYS_EXP);
%
yalmip('clear');
end
function[Recorder_Updated, Flag_Out_Converge] = NCCG_SP_v10(Season, Recorder_Text, Recorder_Old)
Num_Hour = 24;
Num_RES  = 5;
Iter_Max = 10;
%
for i = 1:Iter_Max
    %% SP
    if i == 1
        [Recorder_Updated, Flag_In_Converge] = NCCG_Sub_SP_v10(Season, Recorder_Text, Recorder_Old);
    else
        [Recorder_Updated, Flag_In_Converge] = NCCG_Sub_SP_v10(Season, Recorder_Text, Recorder_Updated);
    end
    In_Obj_Gap_Latest = Recorder_Updated{29, end}(end);
    % If IN converges or Iteration limits are approched: check OUT convergence and then breck
    if Flag_In_Converge == 1 || i == Iter_Max
        % Update OUT information
        Recorder_Updated{7,  end} = Recorder_Updated{18, end} + max(Recorder_Updated{28, end});
        for it = 1:size(Recorder_Updated, 2)-1
            Out_Obj_UB_Temp(it) = Recorder_Updated{7, it+1};
            Out_Obj_LB_Temp(it) = Recorder_Updated{8, it+1};
        end
        Out_Obj_UB_Best          = min(Out_Obj_UB_Temp);
        Out_Obj_LB_Best          = max(Out_Obj_LB_Temp);
        Out_Obj_Gap_Threshold    = Recorder_Updated{30, end};
        Out_Obj_Gap_Latest       = 100*(Out_Obj_UB_Best - Out_Obj_LB_Best)/Out_Obj_UB_Best;
        Recorder_Updated{9, end} = Out_Obj_Gap_Latest;
        disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        disp(['Outer iteration: #', num2str(size(Recorder_Updated, 2) - 1) ]);
        disp(['Inner Gap: ', num2str(In_Obj_Gap_Latest), '%']);
        disp(['Inner iteration: #', num2str(i)]);
        disp('The inner C&CG is done!');
        disp('Please do Outer MP...');
        disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        % if OUT convergence is done
        if Out_Obj_Gap_Latest <= Out_Obj_Gap_Threshold
            Flag_Out_Converge = 1;
         % if OUT convergence is NOT done
        elseif Out_Obj_Gap_Latest > Out_Obj_Gap_Threshold
            Flag_Out_Converge = 0;
            % New block
            Recorder_New{1, 1}  = Recorder_Updated{1, end}; % Dispatch Date:   Public
            Recorder_New{2, 1}  = Recorder_Updated{2, end}; % Budget       :  Public
            Recorder_New{3, 1}  = Recorder_Updated{19, end}{end}; % Out_W_UB: Scenario from In_MP to Out_MP
            Recorder_New{4, 1}  = Recorder_Updated{20, end}{end}; % Out_W_LB: Scenario from In_MP to Out_MP
            Recorder_New{5, 1}  = Recorder_Updated{21, end}{end}; % Out_L_UB: Scenario from In_MP to Out_MP
            Recorder_New{6, 1}  = Recorder_Updated{22, end}{end}; % Out_L_LB: Scenario from In_MP to Out_MP
            Recorder_New{7, 1}  = []; % Out_Obj_UB:  Given by Out_MP and In_SP
            Recorder_New{8, 1}  = []; % Out_Obj_LB:  Given by Out_MP
            Recorder_New{9, 1}  = []; % Out_Obj_Gap: Given by In_SP and Out_MP
            Recorder_New{10, 1} = []; % Var_UC_I:       From Out_MP to In_SP/In_MP
            Recorder_New{11, 1} = []; % Var_UC_I_SU:    From Out_MP to In_SP/In_MP
            Recorder_New{12, 1} = []; % Var_UC_I_SD:    From Out_MP to In_SP/In_MP
            Recorder_New{13, 1} = []; % Var_UC_I_RC:    From Out_MP to In_SP/In_MP
            Recorder_New{14, 1} = []; % Var_UC_P:       From Out_MP to In_SP/In_MP
            Recorder_New{15, 1} = []; % Var_UC_W:       From Out_MP to In_SP/In_MP
            Recorder_New{16, 1} = []; % Var_UC_R_H:     From Out_MP to In_SP/In_MP
            Recorder_New{17, 1} = []; % Var_UC_R_C:     From Out_MP to In_SP/In_MP
            Recorder_New{18, 1} = []; % Cost_1st_Stage: From Out_MP to In_SP/In_MP
            Recorder_New{19, 1} = {zeros(Num_Hour, Num_RES)}; % In_W_UB_History: Scenarios from In_MP to In_SP
            Recorder_New{20, 1} = {zeros(Num_Hour, Num_RES)}; % In_W_LB_History: Scenarios from In_MP to In_SP
            Recorder_New{21, 1} = {zeros(Num_Hour, 1)};       % In_L_UB_History: Scenarios from In_MP to In_SP
            Recorder_New{22, 1} = {zeros(Num_Hour, 1)};       % In_L_LB_History: Scenarios from In_MP to In_SP
            Recorder_New{23, 1} = {}; % Var_ED_I_History:    Enumerated I from In_SP for In_MP
            Recorder_New{24, 1} = {}; % Var_ED_I_SU_History: Enumerated I from In_SP for In_MP
            Recorder_New{25, 1} = {}; % Var_ED_I_SD_History: Enumerated I from In_SP for In_MP
            Recorder_New{26, 1} = 0;  % In_Num_Enumeration:  Number of binary enumerations in In_MP
            Recorder_New{27, 1} = inf; % In_UB_History  under these Out_MP solutions
            Recorder_New{28, 1} = [];  % In_LB_History  under these Out_MP solutions
            Recorder_New{29, 1} = [];  % In_Gap_History under these Out_MP solutions
            Recorder_New{30, 1} = Recorder_Updated{30, end}; % Out_Obj_Gap_Threshold
            Recorder_New{31, 1} = Recorder_Updated{31, end}; % In_Obj_Gap_Threshold
            % Add new block
            Recorder_Updated    = [Recorder_Updated Recorder_New];
        end
        break
    end
    % If IN is NOT converges and Iteration limits are NOT approched
    if Flag_In_Converge ~= 1 && i ~= Iter_Max        
        disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        disp(['Outer iteration: #', num2str(size(Recorder_Updated, 2) - 1) ]);
        disp(['Inner Gap: ', num2str(In_Obj_Gap_Latest), '%']);
        disp(['Inner iteration: #', num2str(i)]);
        disp('More inner iteration is required.');
        disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    end
    %% MP
    [Recorder_Updated, Flag_In_Converge] = NCCG_Sub_MP_v10(Season, Recorder_Text, Recorder_Updated);
    In_Obj_Gap_Latest = Recorder_Updated{29, end}(end);
    % If IN converges, then check OUT convergence
    if Flag_In_Converge == 1 || i == Iter_Max
        % Update OUT information
        Recorder_Updated{7,  end} = Recorder_Updated{18, end} + max(Recorder_Updated{28, end});
        for it = 1:size(Recorder_Updated, 2)-1
            Out_Obj_UB_Temp(it) = Recorder_Updated{7, it+1};
            Out_Obj_LB_Temp(it) = Recorder_Updated{8, it+1};
        end
        Out_Obj_UB_Best          = min(Out_Obj_UB_Temp);
        Out_Obj_LB_Best          = max(Out_Obj_LB_Temp);
        Out_Obj_Gap_Threshold    = Recorder_Updated{30, end};
        Out_Obj_Gap_Latest       = 100*(Out_Obj_UB_Best - Out_Obj_LB_Best)/Out_Obj_UB_Best;
        Recorder_Updated{9, end} = Out_Obj_Gap_Latest;
        disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        disp(['Outer iteration: #', num2str(size(Recorder_Updated, 2) - 1) ]);
        disp(['Inner Gap: ', num2str(In_Obj_Gap_Latest), '%']);
        disp(['Inner iteration: #', num2str(i)]);
        disp('The inner C&CG is done!');
        disp('Please do Outer MP...');
        disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        if Out_Obj_Gap_Latest <= Out_Obj_Gap_Threshold
            Flag_Out_Converge = 1;
        else
            Flag_Out_Converge = 0;
            % New block
            Recorder_New{1, 1}  = Recorder_Updated{1, end}; % Dispatch Date:   Public
            Recorder_New{2, 1}  = Recorder_Updated{2, end}; % Budget       :  Public
            Recorder_New{3, 1}  = Recorder_Updated{19, end}{end}; % Out_W_UB: Scenario from In_MP to Out_MP
            Recorder_New{4, 1}  = Recorder_Updated{20, end}{end}; % Out_W_LB: Scenario from In_MP to Out_MP
            Recorder_New{5, 1}  = Recorder_Updated{21, end}{end}; % Out_L_UB: Scenario from In_MP to Out_MP
            Recorder_New{6, 1}  = Recorder_Updated{22, end}{end}; % Out_L_LB: Scenario from In_MP to Out_MP
            Recorder_New{7, 1}  = []; % Out_Obj_UB:  Given by Out_MP and In_SP
            Recorder_New{8, 1}  = []; % Out_Obj_LB:  Given by Out_MP
            Recorder_New{9, 1}  = []; % Out_Obj_Gap: Given by In_SP and Out_MP
            Recorder_New{10, 1} = []; % Var_UC_I:       From Out_MP to In_SP/In_MP
            Recorder_New{11, 1} = []; % Var_UC_I_SU:    From Out_MP to In_SP/In_MP
            Recorder_New{12, 1} = []; % Var_UC_I_SD:    From Out_MP to In_SP/In_MP
            Recorder_New{13, 1} = []; % Var_UC_I_RC:    From Out_MP to In_SP/In_MP
            Recorder_New{14, 1} = []; % Var_UC_P:       From Out_MP to In_SP/In_MP
            Recorder_New{15, 1} = []; % Var_UC_W:       From Out_MP to In_SP/In_MP
            Recorder_New{16, 1} = []; % Var_UC_R_H:     From Out_MP to In_SP/In_MP
            Recorder_New{17, 1} = []; % Var_UC_R_C:     From Out_MP to In_SP/In_MP
            Recorder_New{18, 1} = []; % Cost_1st_Stage: From Out_MP to In_SP/In_MP
            Recorder_New{19, 1} = {zeros(Num_Hour, Num_RES)}; % In_W_UB_History: Scenarios from In_MP to In_SP
            Recorder_New{20, 1} = {zeros(Num_Hour, Num_RES)}; % In_W_LB_History: Scenarios from In_MP to In_SP
            Recorder_New{21, 1} = {zeros(Num_Hour, 1)};       % In_L_UB_History: Scenarios from In_MP to In_SP
            Recorder_New{22, 1} = {zeros(Num_Hour, 1)};       % In_L_LB_History: Scenarios from In_MP to In_SP
            Recorder_New{23, 1} = {}; % Var_ED_I_History:    Enumerated I from In_SP for In_MP
            Recorder_New{24, 1} = {}; % Var_ED_I_SU_History: Enumerated I from In_SP for In_MP
            Recorder_New{25, 1} = {}; % Var_ED_I_SD_History: Enumerated I from In_SP for In_MP
            Recorder_New{26, 1} = 0;  % In_Num_Enumeration:  Number of binary enumerations in In_MP
            Recorder_New{27, 1} = inf; % In_UB_History  under these Out_MP solutions
            Recorder_New{28, 1} = [];  % In_LB_History  under these Out_MP solutions
            Recorder_New{29, 1} = [];  % In_Gap_History under these Out_MP solutions
            Recorder_New{30, 1} = Recorder_Updated{30, end}; % Out_Obj_Gap_Threshold
            Recorder_New{31, 1} = Recorder_Updated{31, end}; % In_Obj_Gap_Threshold
            % Add new block
            Recorder_Updated    = [Recorder_Updated Recorder_New];
        end
        break
    else
        disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        disp(['Outer iteration: #', num2str(size(Recorder_Updated, 2) - 1) ]);
        disp(['Inner Gap: ', num2str(In_Obj_Gap_Latest), '%']);
        disp(['Inner iteration: #', num2str(i)]);
        disp('More inner iteration is required.');
        disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    end
end
end
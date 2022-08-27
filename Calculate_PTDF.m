function [PTDF] = Calculate_PTDF(Branch, Ref_Bus)
% Number of transmission lines
Num_Branch = length(Branch(:, 1));
% Number of buses
Num_Bus = max(max(Branch(:, 2:3)));
% Caculate susceptance matrix B
B = zeros(Num_Bus, Num_Bus);
for b = 1:Num_Branch
    F_Bus  = Branch(b, 2);  % Get from-bus       of branch b
    T_Bus  = Branch(b, 3);  % Get to-bus         of branch b
    X_Line = Branch(b, 4);  % Get reactance data of branch b
    % For diagonal elements
    B(F_Bus, F_Bus) = B(F_Bus, F_Bus) + 1/X_Line;
    B(T_Bus, T_Bus) = B(T_Bus, T_Bus) + 1/X_Line;
    % For non-diagonal elements
    B(F_Bus, T_Bus) = B(F_Bus, T_Bus) - 1/X_Line;
    B(T_Bus, F_Bus) = B(T_Bus, F_Bus) - 1/X_Line;
end
% Caculate Delta_Angle matrix
B(Ref_Bus, :) = [];
B(:, Ref_Bus) = [];
Delta_Angle   = inv(B)*eye(Num_Bus - 1);
Delta_Angle   = [Delta_Angle(1:Ref_Bus-1, :);
                 zeros(1, Num_Bus-1);
                 Delta_Angle(Ref_Bus:end, :)]; 
Delta_Angle = [Delta_Angle(:, 1:Ref_Bus-1),...
               zeros(Num_Bus, 1),...
               Delta_Angle(:, Ref_Bus:end)];
% Caculate PTDF matrix  
PTDF = zeros(Num_Branch, Num_Bus);
for n = 1:Num_Bus
    if n == Ref_Bus
        PTDF(:, Ref_Bus) = 0;    
    else
        for b = 1:Num_Branch
            F_Bus  = Branch(b, 2);
            T_Bus  = Branch(b, 3);
            X_Line = Branch(b, 4);
            % PTDF from bus n to branch b
            PTDF(b, n) = (Delta_Angle(n, F_Bus) - Delta_Angle(n, T_Bus))...
                          /X_Line;
        end
    end
end
% Clear the numerical noises
PTDF = round(PTDF, 3);
end


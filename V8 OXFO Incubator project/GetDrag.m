% Inputs "state", "constants", "atmos"; Outputs drag force in Newtons.
% Will at some point account for variations in Cd with Re.
% Uses state values to determine deployment altitudes for chutes.
% Chutes drag development: Arbitrarily chosen to be exponential. ### Research this? ###

function [drag, state] = GetDrag(state,constants,atmos)

% 1.0 ### Calculate Cd ###
%     2.1.1 Get mu - should be received from getAtmos
%     2.1.2 Calculate Re - store in the state/data
%     2.1.3 Calculate Cd - store in the state/data

Cd1 = state.Cd_payload;
Cd2 = state.Cd_drogue;
Cd3 = state.Cd_main;

% 2. Calculate k   ### ASSUMING CONSTANT Cd ###
A1 = state.A_payload;
if state.z <= state.drogueDeploy
    A2 = (state.D_drogue*0.5)^(2)*pi;
    A2 = A2*(1-exp(-(state.drogueDeploy-state.z)/state.tauDrogue));     % Arbitrarily chosen drag development
else
    A2 = 0;
end
if state.z <= state.mainDeploy
    A3 = (state.D_main*0.5)^(2)*pi;
    A3 = A3*(1-exp(-(state.mainDeploy-state.z)/state.tauMain));         % Arbitrarily chosen drag development
else
    A3 = 0;
end

state.k = 0.5*atmos.rho*(A1*Cd1 + A2*Cd2 + A3*Cd3);       % kg/m; Standard formula. Simple sum of the main drag components.

state.test = A3;    % Test

% 3. Calculate drag
drag = state.k*((state.v)^2);       % N; velocity-squared-relation ### TO BE IMPROVED ###

end
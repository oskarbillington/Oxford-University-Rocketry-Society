% Calculate payload velocity based on free fall (with air resistance)
% -start height (0 initial velocity) -deployment height
% Data source (*1): http://www.braeunig.us/space/atmmodel.htm#USSA1976 (18.07.2019)
% Improvements: Calculate Re (inc. mu(h)) -> Cd(h); Better air resistance
% model; Optimise values for design parameters based on boundary values.

% 1 Initialise values
%   1.0 Constants
constants.R_null = 8314.32;           % J/kg-K; Universal gas constant
constants.R_gnd = 287.053;            % J/kg-K, Specific gas constant (0-86 km, above which the air composition changes significantly)
constants.gamma = 1.400;              % Ratio of specific heats
constants.k = 1.380622*10^-23;        % J/K
constants.NA = 6.022169*10^-26;       % kmol-1
constants.g_null = 9.80665;           % m/s^2; Acceleration due to gravity at sea level (geometric altitude), 45 degrees latitude
constants.g_null_dash = 9.80665;      % (m/s)2/m'
constants.r_null = 6356.766;          % km; Radius of the earth, 45 degrees latitude
constants.M_null = 28.9644;           % kg/kmol
constants.P_null = 101325;            % Pa; Air pressure at sea level, 45 degrees latitude
constants.T_null = 288.15;            % K; Temperature at sea level, 45 degrees latitude
constants.T_inf = 1000.0;             % K; Reference temperature

%   1.1 State and master
state.z0 = 100000;              % Initial geometric altitude, m
state.z1 = 0;                   % Final geometric altitude (Parachute deployment), m
state.m = 25;                   % Total mass, kg - Nominal value 25 kg
state.A_payload = 0.03;         % Projected area, m^2
state.D_drogue = 0.610*0.75;         % Drogue diameter, m - 24" Fruity Chute: 0.610 m diameter, 1.5-1.6 Cd.
state.D_main = 4.00;            % Main parachute diameter, m
state.Cd_payload = 0.75;        % Estimated drag coefficient (cubic payload), 10^2<Re<10^5 ###MAY REITERATE IF Re IS PUSHING 10^5(Drag crisis)###
state.Cd_drogue = 1.50;         % Estimated drag coefficient 
state.Cd_main = 1.00;           % Estimated drag coefficient
state.tauDrogue = 100;          % Distance equivalent to time constant for exponential drag development, m
state.tauMain = 200;            % Distance equivalent to time constant for exponential drag development, m
state.drogueDeploy = state.z0;  % Drogue deployment geometric altitude, m
state.mainDeploy = 3000;        % Main deployment geometric altitude, m

master.varToggle = 1;       % Toggle calculating results for a variation of a parameter
master.varRange = 0.50;     % Fractional range +/- to calculate variations within
master.varNum = 2;          % Number of calculations and plots +/- the mean value
% master.varPara = ...      % Select design parameter to variate ### How to make this work? Rather define the entire variation in this paragraph ###

state.v = 0;                % Initial vertical velocity, m/s
state.z = state.z0;         % Initial geometric altitude, m
state.t = 0;                % Initial time, s
state.dt = 0.1;             % Time step size, s
state.high_speed_mode = 0;  % Whether or not |v|>100
state.test = 0;             % Empty. Use to test and plot a specific program parameter. ---Current test: A3 (GetDrag)---

% ###Can we get rid of this paragraph please?###
state.Re = 0;               % Reynold's number (0 for initial velocity = 0) ###Should be calculated in the simulator, requires mu###
state.k = 0;                % Air resistance constant - to be calculated, kg/m ###
state.a = -constants.g_null*(constants.r_null/(constants.r_null + state.z/1000))^2; % Initial vertical acceleration, m/s^2

%   1.2 Vectors to store values
master.n = 10^5;                    % More than large enough
data.a = zeros(1,master.n);         % Projected area, m^2
data.v = zeros(1,master.n);         % Vertical velocity, m/s
data.t = zeros(1,master.n);         % Time, t
data.z = zeros(1,master.n);         % Geometric altitude, m
data.rho = zeros(1,master.n);       % Air density, kg/m^3
data.Re = zeros(1,master.n);        % Reynold's number
data.k = zeros(1,master.n);         % Air resistance constant, kg/m
data.T = zeros(1,master.n);         % Air temperature, K
data.p = zeros(1,master.n);         % Air pressure, Pa
data.C = zeros(1,master.n);         % Speed of sound, m/s
data.test = zeros(1,master.n);      % Test

% 2 Repeat for each time step within altitude range:
data = CalculateData(state,constants,master,data);

% 3 Plot the data
clf
% plot(data.z,data.test)      % Plot test. Use breakpoint.
PlotData(state,data)

% 4 Calculate and plot variations
if master.varToggle == 1
    
    master.varValues = linspace((1-master.varRange)*state.D_drogue,(1+master.varRange)*state.D_drogue,1+2*master.varNum);       % Create variation values and remove the median
    master.varValues = [master.varValues(1:floor(length(master.varValues)/2)), master.varValues(ceil(length(master.varValues)/2)+1:length(master.varValues))];
    master.colourRange = cool(length(master.varValues)+2);
    
    for i = 1:length(master.varValues)
        state.D_drogue = master.varValues(i);            % ### Currently this must be changed manually depending on which parameter is to be varied ###
        data = CalculateData(state,constants,master);
        master.colour = master.colourRange(i+1,:);
        PlotVarData(data,state,master)
    end
    
end

% Input "state" (geometric altitude z (m)) and constants (various); Outputs "atmos" (air density rho (kg/m^3),
% absolute pressure p (Pa), temperature T (K), speed of sound C (m/s)).
% Uses results from source(*1): Piecewise functions
% (*1) http://www.braeunig.us/space/atmmodel.htm#USSA1976 (18.07.2019)
% ### The source describes the reference atmospheres used: 45 degrees
% latitude. May not match our specific conditions, in terms of latitude
% and weather. Speed of sound is inaccurate above 86 km as R changes with
% air composition. ###

function atmos = GetAtmosphere(state,constants)

% 0. Unit conversions
Z = state.z/1000;                                   % z in km
h = constants.r_null*Z / (constants.r_null + Z);    % km, Geopotential altitude

% 1.1 Piecewise functions: Z = 0-86 km
if (0 <= Z) && (Z <= 86)
    
    if (0 <= h) && (h <= 11)            % Troposphere
        T_M = 288.15 - 6.5 * h;                                         % K
        p = 101325.0 * (288.15 / (288.15 - 6.5 * h))^(34.1632 / -6.5);  % Pa
    elseif (11 < h) && (h <= 20)        % Stratosphere
        T_M = 216.65;
        p = 22632.06 * exp(-34.1632*(h - 11) / 216.65);
    elseif (20 < h) && (h <= 32)        % Stratosphere
        T_M = 196.65 + h;
        p = 5474.889 * (216.65 / (216.65 + (h - 20)))^(34.1632);
    elseif (32 < h) && (h <= 47)        % Stratosphere
        T_M = 139.05 + 2.8 * h;
        p = 868.0187 * (228.65 / (228.65 + 2.8 * (h - 32)))^(34.1632 / 2.8);
    elseif (47 < h) && (h <= 51)        % Mesosphere
        T_M = 270.65;
        p = 110.9063 * exp(-34.1632 * (h - 47) / 270.65);
    elseif (51 < h) && (h <= 71)        % Mesosphere
        T_M = 413.45 - 2.8 * h;
        p = 66.93887 * (270.65 / (270.65 - 2.8 * (h - 51)))^(34.1632 / -2.8);
    elseif (71 < h) && (Z <= 86)        % Mesosphere
        T_M = 356.65 - 2.0 * h;
        p = 3.956420 * (214.65 / (214.65 - 2 * (h - 71)))^(34.1632 / -2);
    end
    
    rho = p/(constants.R_gnd*T_M);                      % kg/m^3, Density ?
    C = (constants.gamma*constants.R_gnd*T_M)^(1/2);    % m/s, Speed of sound C
    T = T_M;                                            % K, (Kinetic Temperature = Molecular-Scale Temperature (constant) in this region)
    
end

% 1.2 Piecewise functions: Z = 86-1000 km
if (86 < Z) && (Z <= 1000)      % Thermosphere, Exosphere above Z = 600 km  
    
    % Temperature (K)
    if (86 < Z) && (Z <= 91)
        T = 186.8673;                                                           % Constant
    elseif (91 < Z) && (Z <= 110)
        T = 263.1905 - 76.3232 * ( 1 - ((Z - 91) / (-19.9429))^2 )^(1/2);       % Elliptical
    elseif (110 < Z) && (Z <= 120)
        T = 240.0 + 12.0 * (Z - 110);                                           % Linear
    elseif (120 < Z) && (Z <= 1000)
        T = 1000-(1000-360.0)*exp(-0.01875*(Z-120)*(constants.r_null+120)/(constants.r_null+Z));    % Exponential
    end
    
    % Pressure (Pa), Density (kg/m^3)
    % ### Accurate to 2-3 digits, 86 < Z <= 120 ###
    if (86 < Z) && (Z <= 120)
        p = exp(-0.0000000422012*Z^5 + 0.0000213489*Z^4 - 0.00426388*Z^3 + 0.421404*Z^2 - 20.8270*Z + 416.225 );
        rho = exp( 0.000000075691*Z^5 - 0.0000376113*Z^4 + 0.0074765*Z^3 - 0.743012*Z^2 + 36.7280*Z - 729.346 );
    end
    
    % Pressure/Density: Accuracy upto 4 digits can be achieved by plotting
    % data from the website here.
    if (86 < Z) && (Z <= 91)
    elseif (91 < Z) && (Z <= 100)
    elseif (100 < Z) && (Z <= 110)
    elseif (110 < Z) && (Z <= 120)
    elseif (120 < Z) && (Z <= 150)
    elseif (150 < Z) && (Z <= 200)
    elseif (200 < Z) && (Z <= 300)
    elseif (300 < Z) && (Z <= 500)
    elseif (500 < Z) && (Z <= 750)
    elseif (750 < Z) && (Z <= 1000)
    end
    
    R = constants.R_gnd;                    % ### INACCURATE: No data in the source(*1) for R at these altitudes. Assume similar. ###
    C = (constants.gamma*R*T)^(1/2);        % m/s, Speed of sound C
    
end

% 2. Output
atmos.rho = rho;
atmos.p = p;
atmos.C = C;
atmos.T = T;

end
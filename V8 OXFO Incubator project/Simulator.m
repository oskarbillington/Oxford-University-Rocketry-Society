% Input "state", "constants" and "atmos"; Outputs "state" a time step
% state.dt later.
% Includes calculation of air resistance based on constant Cd and a basic
% square velocity formula.

function state = Simulator(state,constants,atmos)

% 0. Calculate the total mass (kg)
m = state.m;    % ### May increase in complexity later ###

% 1. Calculate the drag due to air resistance (N)
[drag, state] = GetDrag(state,constants,atmos);

% 2. Calculate the gravitational field intensity (m/s^2)
g = constants.g_null*(constants.r_null/(constants.r_null + state.z/1000))^2;

% 3. Calculate the acceleration
state.a = -g + drag/m;      % Newton's second law; positive direction UP

% 4. Use Euler's method to calculate the state after a time step
state.v = state.v + state.a*state.dt;
state.z = state.z + state.v*state.dt;
state.t = state.t + state.dt;

% 5. Get more frequent calculations at high velocities
if ((abs(state.v) > 100) && state.high_speed_mode == 0)
    state.dt = 0.1*state.dt;
    state.high_speed_mode = 1;
elseif ((abs(state.v) <= 100) && state.high_speed_mode == 1)
    state.dt = 10*state.dt;
    state.high_speed_mode = 0;
end

end
% Outputs "data"; Inputs "state", "constants", "master", "data". 
% Main function to calculate all the state data to plot.

function data = CalculateData(state,constants,master,data)

for i = 1:master.n
    if state.z >= state.z1
        
        % 1 Get atmospheric data
        atmos = GetAtmosphere(state,constants);
        
        % 2 Store the data to plot later
        data.a(i) = state.a;
        data.v(i) = state.v;
        data.z(i) = state.z;
        data.t(i) = state.t;
        data.Re(i) = state.Re;
        data.k(i) = state.k;
        data.rho(i) = atmos.rho;
        data.p(i) = atmos.p;
        data.T(i) = atmos.T;
        data.C(i) = atmos.C;
        data.test(i) = state.test;
        
        % 3 Simulate the next time step
        state = Simulator(state,constants,atmos);
        
        % 4 End loop and clear unused points for better plots
    else
        data.a = data.a(1:i-1);
        data.v = data.v(1:i-1);
        data.z = data.z(1:i-1);
        data.t = data.t(1:i-1);
        data.Re = data.Re(1:i-1);
        data.k = data.k(1:i-1);
        data.rho = data.rho(1:i-1);
        data.p = data.p(1:i-1);
        data.T = data.T(1:i-1);
        data.C = data.C(1:i-1);
        data.test = data.test(1:i-1);
        break
    end
end
end
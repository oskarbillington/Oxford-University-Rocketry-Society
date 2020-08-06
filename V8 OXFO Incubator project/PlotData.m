% Plots "data"

function PlotData(state,data)

% 3.1 Plot height against time
subplot(2,3,1)
plot(data.t,data.z,'r')
hold on
xlabel('Time / t')
ylabel('Height / m')
grid on
[diff,I_drogueDeploy] = min(abs(data.z-state.drogueDeploy));            % Mark drogue deployment
plot(data.t(I_drogueDeploy),state.drogueDeploy,'ko','MarkerSize',10)
text(data.t(I_drogueDeploy),state.drogueDeploy-0.1*max(state.z),sprintf('Drogue Deployment after %4.2f s',data.t(I_drogueDeploy)))
[diff,I_mainDeploy] = min(abs(data.z-state.mainDeploy));                % Mark main deployment
plot(data.t(I_mainDeploy),state.mainDeploy,'ko','MarkerSize',10)
text(data.t(I_mainDeploy),state.mainDeploy+0.1*max(state.z),sprintf('Main Deployment after %4.2f s',data.t(I_mainDeploy)))
plot(data.t(end),data.z(end),'ko','MarkerSize',10)
text(data.t(end)*0.85,data.z(1)*0.1,sprintf('Final: %4.2f m %4.2f s',data.z(end),data.t(end)))


% 3.2 Plot velocity against time
subplot(2,3,2)
plot(data.t,data.v,'b')
hold on
xlabel('Time / t')
ylabel('Velocity / m/s')
vFin = data.v(end);             % Plot final velocity
plot(data.t(end),vFin,'ko','MarkerSize',10)
text(0.6*data.t(end),min(data.v)*0.2,sprintf('Final velocity %4.2f m/s',vFin))
[vMin,I_vMin] = min(data.v);    % Plot minimum velocity
plot(data.t(I_vMin),vMin,'ko','MarkerSize',10)
text(data.t(I_vMin),vMin*7/8,sprintf('Minimum velocity %4.2f m/s',vMin))
title('Descent simulation')     % Common title
grid on

% 3.3 Plot acceleration against time
subplot(2,3,3)
plot(data.t,data.a,'g')
hold on
xlabel('Time / t')
ylabel('Acceleration / m/s^2')
[a_max,t_a_max] = max(data.a);                  % Find and plot the maximum acceleration
plot(data.t(t_a_max),a_max,'ko','MarkerSize',10)
text(1.02*data.t(t_a_max),a_max,sprintf('Maximum acceleration %4.2f m/s^2',a_max))
[a_min,I_a_min] = min(data.a);                  % Find and plot the minimum acceleration
plot(data.t(I_a_min),a_min,'ko','MarkerSize',10)
text(1.02*data.t(I_a_min),a_min+0.1*abs(a_min),sprintf('Minimum acceleration %4.2f m/s^2',a_min))
grid on

% 3.4 Plot rho against height
subplot(2,3,4)
semilogy(data.z,data.rho,'k')
hold on
semilogy(data.z,data.p,'b')
xlabel('Height / m')
ylabel('(log)')
legend('Air density / kg/m^3','Air pressure / Pa')

% 3.5 Plot velocity and speed of sound against height
subplot(2,3,5)
plot(data.z,data.v,'k')
hold on
plot(data.z,-1.*data.C,'r')
xlabel('Height / m')
ylabel('m/s')
legend('Velocity','Speed of sound')

% 3.6 Plot acceleration against height
subplot(2,3,6)
plot(data.z,data.a,'k')
hold on
xlabel('Height / m')
ylabel('Acceleration / m/s^2')
[aMax,I_aMax] = max((data.a).*(data.z<=state.mainDeploy));    % Plot maximum acceleration with main deployed
plot(data.z(I_aMax),aMax,'ko')
text(data.z(I_aMax),aMax*7/8,sprintf('%4.2f',aMax))

drawnow

end
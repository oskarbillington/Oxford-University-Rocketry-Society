% Plots variation data on top of PlotData - i.e. subplot positions etc.
% needs to be updated in accordance with the PlotData function

function PlotVarData(data,state,master)

% 3.5 Plot velocity against height
subplot(2,3,5)
hold on
plot(data.z,data.v,'--','Color',master.colour)
legend('Velocity','Speed of sound')
% title('Darker variations indicate higher values')

% 3.6 Plot acceleration against height
subplot(2,3,6)
hold on
plot(data.z,data.a,'--','Color',master.colour)
[aMax,I_aMax] = max((data.a).*(data.z<=state.mainDeploy));      % Plot maximum acceleration with main deployed 
plot(data.z(I_aMax),aMax,'o','Color',master.colour)
text(data.z(I_aMax),aMax*7/8,sprintf('%4.2f',aMax))

drawnow

end
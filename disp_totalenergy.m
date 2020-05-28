function disp_totalenergy(P_Sub, E_Sub, time, T_m, names)
disp('started disp_totalenergy');
set(groot, 'defaultFigurePosition', get(0, 'Screensize'));
set(0,'DefaultFigureWindowStyle','docked')  % 'normal' to un-dock
folder = '/Users/Willemdl/Desktop/TU Delft/BAP/Images';
%% Plot of Total energy, Power and step size vs the time
Time_Max = max(time);

figure('Name','geweldige plotjes','NumberTitle','off');
subplot(3,1,1);
plot(time(:), E_Sub(:,end-1));
title('Total Energy usage');
xlabel('Time');
xlim([0 Time_Max]);
ylabel('E [mJ]');
legend('Energy');


subplot(3,1,2);
plot(time(:), P_Sub(:,end-1));
title('Total Power curve during full simulation');
xlabel('Time []');
xlim([0 Time_Max]);
ylabel('Power [mW]');
legend('Power');

subplot(3,1,3);
%https://nl.mathworks.com/help/physmod/simscape/ug/determine-step-size.html
semilogy(time(1:end-1),diff(time),'-x'); 
title('Step size of totalenergy');
xlabel('Time');
xlim([0 Time_Max]);
ylabel('Step size [s]');
saveas(gcf, 'Images\totalenergy1', 'svg');
%% plot of specific measurement with pattern of stages, power and energy 
%---------- uitzoeken welke combinaties van intervallen mogelijk zijn,
%stel: intervallen 300 400 en 500 dan heb je deze 3 verschillende metingen
%maar ook de combinaties van deze intervallen. als we de tijden kunnen
%bepalen wanneer deze combinaties voor het eerst plaats vinden dan kunnen
%we al deze mogelijkheden bijelkaar/naastelkaar plotten. 
M_Plot = 5;
test = (T_m(M_Plot,2)-T_m(M_Plot,1))/2;

figure();
sgtitle(['Plot of measurement: ', num2str(M_Plot)])
subplot(3,1,1)
plot(time(:), P_Sub(:,end));
xlim([(T_m(M_Plot,1)-test) (T_m(M_Plot,2)+test)]);
title(['Pattern of system Stages during measuremnt:',num2str(M_Plot)]);
xlabel('Time');
ylabel('Stage');
legend('Stages');

subplot(3,1,2)
plot(time(:), P_Sub(:,end-1));
xlim([(T_m(M_Plot,1)-test) (T_m(M_Plot,2)+test)]);
title(['Pattern of Power drawn during measuremnt:', num2str(M_Plot)]);
xlabel('Time');
ylabel('P [mW]');
legend('Power');

subplot(3,1,3)
plot(time(:), E_Sub(:,end-1));
xlim([(T_m(M_Plot,1)-test) (T_m(M_Plot,2)+test)]);
title(['Pattern of Energy usage during measuremnt:', num2str(M_Plot)]);
xlabel('Time');
ylabel('E [mJ]');
legend('Power');
saveas(gcf, 'Images\totalenergy2', 'svg');
%% Extra values that needed to be calculated. 
%linker as energy rechter as % van totaal (volledig of voor 1 meting?)
%Step_Vec = [0 ; diff(time)]; %zero added in orderto align the diff vector
%with power vector
%matrix, iedere colom is een stage iedere rij is k
%waar 1 staat geeft de stage aan voor die k
%geeft vector x,1 van alle unique stages, floor zorgt er voor dat substages naar hoofdstage word omgezet.
Stages = unique(floor(P_Sub(2:end,end))); %gives vector containing the stage numbers, neglecting substages
%K_Stages=logical array; each column is an stage, row is k. if 1 then that 'calculation'(=k) belongs to that specific stage
K_Stages = floor(P_Sub(:,end))==Stages';
Step_Stages = K_Stages.*[0;diff(time)]; %gives stepsize at each moment splitted over the stages. (1,x)=stages (x,1)=k

T_Stages_Tot = (sum(Step_Stages,1)).';%gives total time spend in each stage. 
T_Stages_Perc = (T_Stages_Tot(:) / Time_Max)*100;
T_Sub_Tot = 0;%gives time spend on each "module", kan maar hiervoor moet veel aangepast worden

P_Sub_Max = max(P_Sub(:,1:end-1),[],1);
P_Sub_Max_Perc = zeros(1,size(P_Sub_Max,2));
P_Stages_Tot =K_Stages.*P_Sub(:,end-1); %each column is an stage, row is k
P_Stages_Max = max(P_Stages_Tot,[],1).';
P_Stages_Min = min(P_Stages_Tot,[],1).';


E_per_k = P_Sub(:,1:end-1).*[0 ; diff(time)];%matrix die de energie geeft per k
E_Sub_Tot = E_Sub(end,1:end-1);%vector of total energy per component [%]
E_Sub_Perc = (E_Sub_Tot(:) / E_Sub_Tot(end))*100; %vector of total energy per component [%]
E_Stages_Tot = (sum(K_Stages.*E_per_k(:,end),1)).';%each row is an stage
E_Stages_Perc = (E_Stages_Tot(:) / E_Sub_Tot(end))*100;

NoStages = size(Stages,1);%number of stages
% Stagesnames = strings(1,NoStages);
% for i =1:1:NoStages
%     Stagesnames(1,i) = "Stage "+ num2str(i);
% end

Stagesnames = ["Deep Sleep" "Wake Up" "Measurement" "Processing" "Transmission" ]
%% Bar graph of energy and time in [%] per stage
figure();
y1 = T_Stages_Perc;
y2 = E_Stages_Perc;
x = NoStages;
[AX,H1,H2]=plotyy(1:x,[y1 nan(x,1)],1:x,[nan(x,1) y2],@bar,@bar);
linkaxes(AX,'x');
title('Time and Energy per Stage in percentages');
ylabel(AX(1),'Time [%]');
ylabel(AX(2),'Energy usage [%]');
%https://nl.mathworks.com/help/matlab/ref/matlab.graphics.axis.axes-properties.html
set(AX, 'XTick', 1:1:x,'XTickLabelRotation',45,'xticklabel',cellstr(Stagesnames(1,:))); 
set(AX, 'XGrid', 'on', 'YGrid', 'on');
set(H1,'FaceColor','#0072BD')
set(H2,'FaceColor','#D95319') 
AX(1).YColor = '#0072BD';
AX(2).YColor = '#D95319';
AX(2).XColor = 'k';
xlim([0.5 x+0.5]);
saveas(gcf, 'Images\totalenergy3', 'svg');
%% Bar graph Time and Energy in s and mJ per stage
figure();
y1 = T_Stages_Tot;
y2 = E_Stages_Tot;
x = NoStages;
[AX,H1,H2]=plotyy(1:x,[y1 nan(x,1)],1:x,[nan(x,1) y2],@bar,@bar);
linkaxes(AX,'x');
title('Time and Energy per Stage');
ylabel(AX(1),'Time [s]');
ylabel(AX(2),'Energy usage [mJ]');
%https://nl.mathworks.com/help/matlab/ref/matlab.graphics.axis.axes-properties.html
set(AX, 'XTick', 1:1:x,'XTickLabelRotation',45,'xticklabel',cellstr(Stagesnames(1,:))); 
set(AX, 'XGrid', 'on', 'YGrid', 'on');
set(H1,'FaceColor','#0072BD')
set(H2,'FaceColor','#D95319') 
AX(1).YColor = '#0072BD';
AX(2).YColor = '#D95319';
AX(2).XColor = 'k';
xlim([0.5 x+0.5]);
saveas(gcf, 'Images\totalenergy4', 'svg');
%% Bar graph energy and maximum power per component in mJ and mW
figure();
NoC = size(P_Sub,2)-2; %Number of Components
y1 = E_Sub_Tot.';
y2 = P_Sub_Max.';
x = NoC+1;% extra bar with Total values
[AX,H1,H2]=plotyy(1:x,[y1 nan(x,1)],1:x,[nan(x,1) y2],@bar,@bar);
linkaxes(AX,'x');
title('Energy usage and maximum power per Component');
ylabel(AX(1),'Energy usage [mJ]');
ylabel(AX(2),'maximum power [mW]');
%legend([H1(1) H2(1)],'Deep Sleep','Measuring');
%https://nl.mathworks.com/help/matlab/ref/matlab.graphics.axis.axes-properties.html
set(AX, 'XTick', 1:1:x,'XTickLabelRotation',45,'xticklabel',cellstr(names(1,:))); 
set(AX, 'XGrid', 'on', 'YGrid', 'on');
set(H1,'FaceColor','#0072BD')
set(H2,'FaceColor','#D95319') 
AX(1).YColor = '#0072BD';
AX(2).YColor = '#D95319';
AX(2).XColor = 'k';
xlim([0.5 x+0.5]);
saveas(gcf, 'Images\totalenergy5', 'svg');
%% Bar graph energy and maximum power per component in [%]
figure();
NoC = size(P_Sub,2)-2; %Number of Components
y1 = E_Sub_Perc;
y2 = P_Sub_Max_Perc.';
x = NoC+1;%+1 because of plotting Total values too. 
[AX,H1,H2]=plotyy(1:x,[y1 nan(x,1)],1:x,[nan(x,1) y2],@bar,@bar);
linkaxes(AX,'x');
title('Energy usage and maximum power per Component');
ylabel(AX(1),'Energy usage [mJ]');
ylabel(AX(2),'maximum power [mW]');
%legend([H1(1) H2(1)],'Deep Sleep','Measuring');
%https://nl.mathworks.com/help/matlab/ref/matlab.graphics.axis.axes-properties.html
set(AX, 'XTick', 1:1:x,'XTickLabelRotation',45,'xticklabel',cellstr(names(1,:))); 
set(AX, 'XGrid', 'on', 'YGrid', 'on');
set(H1,'FaceColor','#0072BD')
set(H2,'FaceColor','#D95319') 
AX(1).YColor = '#0072BD';
AX(2).YColor = '#D95319';
AX(2).XColor = 'k';
xlim([0.5 x+0.5]);
saveas(gcf, 'Images\totalenergy6', 'svg');

%% Table of important values EXAMPLE
%https://nl.mathworks.com/help/matlab/ref/uitable.html
%https://nl.mathworks.com/help/matlab/ref/matlab.ui.control.table-properties.html
% figure();
% colums_str = {'final time', 'Energyused'};
% Table_Values = [10000 5000; 10 50];
% uitable('ColumnName', colums_str, 'Data', Table_Values);

%% Table of Energy usage and power per stage 
% figure();
% 
% colums_str = {'Minimum Power', 'Maximum Power', 'Energy used', 'Time in this stage'};
% Table_Values = [P_Stages_Min P_Stages_Max E_Stages_Tot T_Stages_Tot];% need to be columns
% uitable('ColumnName', colums_str, 'Data', Table_Values);


set(groot, 'defaultFigurePosition', 'factory');
disp('finished disp_totalenergy');
end
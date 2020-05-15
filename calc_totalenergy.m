function [ P_Sub, E_Sub, P_Total, E_Total, measurements3, time, tmeasurement, tltest] = calc_totalenergy(S_Sensors, S_MCU, S_Com, I_Array, T_Max, E_Max)
disp('Started calc_totalenergy function');
%input; one array with the sensors that will be used,
%one vector with MCU parameters, one vector with transmission parameters.
%One array with the

%output; 2 vectors/arrays 1 with energy in mili Joule [mJ] and one with the time. seperate time
%vectors will be outputed in order to easily plot and use the energy data.
%energy array; each column is one energy calculation and each row is the
%amount of energy at each time.

%% General information about this function
% The values for power variables are in mW and thus energy is in mJ
% additionally the time is in seconds
% The following assumptions have been made: 1) The time between 2
% intervals is larger than it takes to perform actions required for 1
% interval. 2) The MCU is active while measurements with sensors are
% performed

%% initialisation of function specific variables


[~, NoS] = size(S_Sensors); %NoS = Number of Sensors
P_M_S = zeros(NoS); %P_M_ means power during Measurement _S refers to Sensor
P_DS_S = zeros(1,NoS); %P_S_ means power during Deep Sleep _S refers to Sensor

%dt = .1;%Step size of the time.[s] bare in mind that if dt is too large
%the symulation will not be accurate or fails.
dt_l=0.001;
%dt_l kan ook automatisch gemaakt worden, zoek in alle input parameters
%naar de kleinste tijd(of met meeste decimalen) en baseer daar de stapgrote
%op.
dt=0.1;

dt_h=1;
I_dt_h= I_Array(:,1);
%determine max step size: search for smalles unit in the interval
while (mod(I_dt_h(:,1),10)==0)
    I_dt_h = I_dt_h(:)./10;
    dt_h= dt_h*10;
end

%than calculations wil be wrong.
time = zeros(T_Max/dt,1); %vector with the actual time
tmeasurement = zeros(100,2); %array each row contains in column 1 start time of measurement and 2nd the finished time
k = 1;%this is the index used for vectors and arrays
z=0;%This is used to keep track of how often and when measurement takes place.
% https://matlab.fandom.com/wiki/FAQ#Why_is_0.3_-_0.2_-_0.1_.28or_similar.29_not_equal_to_zero.3F
% https://nl.mathworks.com/matlabcentral/answers/49910-mod-bug-or-something-else

% T_Processing is the total time the MCU spends on processing the measured data.
measurements2 = zeros(100,NoS+2);
P_Sub = zeros(T_Max/dt, NoS+4);%--- uitleggen hoe werkt en noemen dat Ptot pas aan einde word berekend/toegevoegd.
E_Sub = zeros(T_Max/dt, NoS+4);
P_Total = zeros(T_Max/dt,1);
E_Total = zeros(T_Max/dt,1);
tltest = zeros(T_Max/dt,1);

%% The large loop
for i=1:1:NoS
    P_DS_S(1,i) = S_Sensors(2,i)*S_Sensors(6,i);%in mW (2,i)=[V] (6,i)=mA
end
P_DS_MCU = S_MCU(3,1)*S_MCU(7,1);%in mW
P_DS_Com = S_Com(3,1)*S_Com(10,1);%in mW

while time(k) < T_Max  %nu alleen gebaseerd op tijd, 2e while of iets voor berekenen tot wanneer energie op is.
    %----------------- mogelijk maken om te bepalen welk verbruik bij welk
    %deel hoord.
    %------------- "ik doe deze meting en daarvoor had ik x lang in
    %standbay kunnen staan"
    %------------- energie verbruik per stage bepalen (per tijd of als
    %som?)
    %------------- energie verbruik per sensor, mcu, transmissie bepalen
    %(per tijd of als som?)
    %% Energy usage during sleep
    if mod(floor(time(k)),dt_h)==0 %floor rond af naar beneden en zorgt voor integer
        %use biggest stepsize possible
        dt=dt_h;
    elseif dt_h >=100 && mod(floor(time(k)), 10 )==0 %
        dt= 10;
    elseif dt_h >=10 && mod(floor(time(k)), 1)==0
        dt= 1;
    else
        %dt=dt_l;
        dt = 1;
    end
    k = k+1;
    P_DS_tot = sum(P_DS_S(:))+P_DS_MCU +P_DS_Com;
    
    for i=1:1:NoS
        P_Sub(k,i) = P_DS_S(i);
    end
    P_Sub(k,1:NoS) = P_DS_S(:);
    P_Sub(k,NoS+1:NoS+2) = [P_DS_MCU P_DS_Com];
    P_Sub(k,NoS+4) = 1;
    E_Sub(k,1:NoS+2) = E_Sub(k-1,1:NoS+2) + P_Sub(k,1:NoS+2)*dt;
    
    P_Total(k) = P_DS_tot;
    E_Total(k) = E_Total(k-1)+P_DS_tot*dt;
    time(k) = time(k-1) +dt;
    
    %% Energy usage during activities
    %if mod(time(k),1)%this is an easier check than the next if thus should make the matlab script faster
    if any(~mod(floor(time(k)),I_Array(:,1))) %gives true if any interval is true
        z=z+1;
        dt=dt_l;
        measurements = I_Array(find(~mod(floor(time(k)),I_Array(:,1))),2:end);%gives an vector of all
        measurements2(z,:) = sum(measurements,1);
        tmeasurement(z,1) = time(k);%saves the times at which the if statement was true, and thus the measurement started
        %in order to check this easily
        
        %% Energy usage during wake up stage [_WU_]
        % It has been assumed that only the MCU has an wake up stage,
        % the rest remains in Deep Sleep.
        P_WU_MCU = S_MCU(3,1)*S_MCU(4,1)*S_MCU(8,1);
        P_DS_rest = sum(P_DS_S(:)) +P_DS_Com;
        P_WU_tot = P_WU_MCU+ P_DS_rest;
        
        dt_test = strsplit(num2str(S_MCU(6,1)),'.'); %https://nl.mathworks.com/matlabcentral/answers/347325-find-the-precision-of-a-value
        if size(dt_test,2)==1 %https://nl.mathworks.com/matlabcentral/answers/16383-how-do-i-check-for-empty-cells-within-a-list
            dt = 1;
        else
            dt=1*10^(-1*numel(dt_test{2}));
        end
        clear dt_test;
        for tl=0:dt:S_MCU(6,1)
            k = k+1;
            
            P_Sub(k,1:NoS) = P_DS_S(:); %all sensors in DS
            P_Sub(k,NoS+1:NoS+2) = [P_WU_MCU P_DS_Com];
            P_Sub(k,NoS+4) = 2;
            E_Sub(k,1:NoS+2) = E_Sub(k-1,1:NoS+2) + P_Sub(k,1:NoS+2)*dt;
            
            P_Total(k) = P_WU_tot;
            E_Total(k) = E_Total(k-1) +P_WU_tot*dt;
            tltest(k) = tl;
            time(k) = time(k-1) +dt;
        end
        %% Energy usage measurement stage [_M_]
        % S_Sensors(x,1) x=2 -> voltage x=3-> current during measurement
        % x=5-> time for that measurement
        % It has been assumed that only the MCU and sensor which is
        % being measured are active, all other systemparts(other
        % sensors and communication module) are in Deep Sleep
        % Additionally each sensor is after the other activated, thus not 2
        % at the same time.
        T_Processing = 0; % At each new interval the processing time can be different.
        for n=1:1:NoS %for each sensor
            if measurements2(z,n)~=0 %if that sensor needs to be activated
                P_M_MCU = S_MCU(3,1)*S_MCU(4,1)*S_MCU(8,1);
                P_M_Com = P_DS_Com; %communication module is still in DS
                P_M_S(n) = S_Sensors(2,n)*S_Sensors(3,n);
                P_M_rest = sum(P_DS_S(:))-P_DS_S(n)+P_M_Com;
                P_M_tot = P_M_MCU + P_M_S(n)+P_M_rest;
                T_Processing = T_Processing + S_Sensors(5,n);% (5,n) -> time[s] to process 1 measurement based on 32MHz
                
                dt_test = strsplit(num2str(S_Sensors(4,n)),'.'); %https://nl.mathworks.com/matlabcentral/answers/347325-find-the-precision-of-a-value
                if size(dt_test,2)==1 %https://nl.mathworks.com/matlabcentral/answers/16383-how-do-i-check-for-empty-cells-within-a-list
                    dt = 1;
                else
                    dt=1*10^(-1*numel(dt_test{2}));
                end
                clear dt_test;
                for tl=0:dt:S_Sensors(4,n) % (4,n) time measuring[s]
                    k = k+1;
                    
                    P_Sub(k,1:NoS) = P_DS_S(:); %all sensors in DS
                    P_Sub(k,n) = P_M_S(n); %change the one that has been activated
                    P_Sub(k,NoS+1:NoS+2) = [P_M_MCU P_M_Com]; %Communication module is still in DS
                    P_Sub(k,NoS+4) = 3;
                    E_Sub(k,1:NoS+2) = E_Sub(k-1,1:NoS+2) + P_Sub(k,1:NoS+2)*dt;
                    
                    P_Total(k) = P_M_tot;
                    E_Total(k) = E_Total(k-1) + P_M_tot*dt;
                    tltest(k) = tl;
                    time(k) = time(k-1) +dt;
                end
            end
        end
        %% Energy usage during processing stage [_P_]
        P_P_MCU = S_MCU(3,1)*S_MCU(4,1)*S_MCU(8,1);%(3,1)=V (4,1)=mA/MHz (8,1)=MHz
        P_P_Com = S_Com(3,1)*S_Com(8,1); % Communication module is set in active mode.
        P_P_tot = P_P_MCU +P_P_Com +sum(P_DS_S(:));
        T_MCU_tot = (T_Processing/32)*S_MCU(8,1) +S_MCU(5,1); % (5,1) is Extra time in active mode. [s]
        
        dt_test = strsplit(num2str(T_MCU_tot),'.'); %https://nl.mathworks.com/matlabcentral/answers/347325-find-the-precision-of-a-value
        if size(dt_test,2)==1 %https://nl.mathworks.com/matlabcentral/answers/16383-how-do-i-check-for-empty-cells-within-a-list
            dt = 1;
        else 
            dt=1*10^(-1*numel(dt_test{2}));
        end
        clear dt_test;
        for tl=0:dt:T_MCU_tot
            k = k+1;
            
            P_Sub(k,1:NoS) = P_DS_S(:); %all sensors in DS during processing stage.
            P_Sub(k,NoS+1:NoS+2) = [P_P_MCU P_P_Com]; %Communication module is still in DS
            P_Sub(k,NoS+4) = 4;
            E_Sub(k,1:NoS+2) = E_Sub(k-1,1:NoS+2) + P_Sub(k,1:NoS+2)*dt;
            
            P_Total(k) = P_P_tot;
            E_Total(k) = E_Total(k-1) + P_P_tot*dt;
            tltest(k) = tl;
            time(k) = time(k-1) +dt;
        end
        %% Energy usage during transmision stage [_Tr_]
        % is leuk als volgorde en hoeveelheid van Tx en Rx ingegeven
        % kan worden.
        P_Tr_Com = 0;
        P_Tr_MCU = S_MCU(3,1)*S_MCU(4,1)*S_MCU(8,1);
        %idee: vector maken waarin staat 1) de modus; Tx/Rx of standaard 2) de
        %tijd in die modus
        
        %% Energy usage during shutdown stage [_SD_]
        
        tmeasurement(z,2) = time(k);%saves the times at which the measurement is finished, and thus the measurement started
    end
    %end
end
%truncate vectors and matrices
time = [0 ; nonzeros(time(:))];
E_Sub(:,NoS+4) = P_Sub(:,NoS+4); %copy the stage indicator from P_Sub to E_Sub
P_Sub(:,NoS+3) = sum(P_Sub(:,1:NoS+2),2); %sum horizontally
P_Sub = [zeros(1,NoS+4); P_Sub(any(P_Sub,2),:)];

E_Sub(:,NoS+3) = sum(E_Sub(:,1:NoS+2),2); %sum horizontally
E_Sub = [zeros(1,NoS+4); E_Sub(any(E_Sub,2),:)];



measurements3= measurements2( any(measurements2,2), :);%https://nl.mathworks.com/matlabcentral/answers/40018-delete-zeros-rows-and-columns
P_Total = [0 ; P_Total(any(E_Total,2),:)];
E_Total = [0 ; E_Total(any(E_Total,2),:)];
disp('Finished calc_totalenergy function');
end
function [MCU, MCUname] = init_mcu()
%the output of this function should be 1 big matrix, each column is a
%different MCU, each row is a different parameter. The following
%parameters need to be defined:
% 1) The name of the MCU.
% 2) Default measurement rate. [n times per day]
% 3) Voltage at which the microcontroller operates. [V]
% 4) Current drawn when active. [mA/MHz]
% 5) Extra time in active mode. [s]
% 6) Wake up time. [s]
% 7) Current drawn during standby / deepsleep.[mA]
% 8) Base clock frequency. [MHz]

% Eventually the total "active" (non deepsleep) time of the microcontroller
% will be determined by the wake up time, measurement time of sensor(s),
% total transmission time and some "standard time"(time controller needs to
% take in order to keep the system in good conditions).

MCU = zeros(7,7);
MCUname(1,1)= "TESTMCU";
MCU(2,1) = 24; %Default measurement rate. [n times per day]
MCU(3,1) = 3.0; %Voltage at which the microcontroller operates. [V]
MCU(4,1) = 0.1; %Current drawn when active. [mA/MHz]
MCU(5,1) = 2; %Extra time in active mode. [s]
MCU(6,1) = 2; %Wake up time. [s]
MCU(7,1) = 0.010; %Current drawn during standby / deepsleep.
MCU(8,1) = 32; %Base clock frequency. [MHz]






end
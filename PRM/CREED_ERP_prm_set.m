%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                                          %
%                                  CREED ERP Parameter Settings                            % 
%                                                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc;
prm = struct();

%%------------------------------------------------------------------------------------------ 
% Directory Settings & Required Fields 
%------------------------------------------------------------------------------------------- 
if ispc
drvr = input('Indicate working driver for (ex: D:\): ', 's');

prm.matlabdir = [drvr, '\MATLAB\CREED_Analyze\']; % Must contain BDF files for epoching
prm.eeglabdir = [drvr, '\MATLAB\eeglab'];
prm.datadirEEG = [drvr, '\DATA\CREED_ParticipantData\EEG\']; % Must contain CLEAN.set folder sorted by PARTICIPANT

elseif isunix
prm.matlabdir = '/Volumes/HARRISON_TB/MATLAB/CREED_Analyze/';
prm.eeglabdir = '/Volumes/HARRISON_TB/MATLAB/eeglab/';
prm.datadirEEG = '/Volumes/HARRISON_TB/DATA/CREED_ParticipantDATA/EEG/';
end

addpath(genpath(prm.matlabdir));addpath(genpath(prm.datadirEEG));addpath(prm.eeglabdir);
prm.erp_proc = {
                '5.BIN.erp'
%                 '6.AVG.erp'
                   };
prm.fieldhandle = {
                '_bin.mat'
                '_cleanerp.mat'
%                 '_avg.erp'
                   };
%%------------------------------------------------------------------------------------------ 
% ERP Specific Parameters = ADJUST BASED ON ERPs of interest
%%-------------------------------------------------------------------------------------------
prm.ref_select = 3; % Indicate reference scheme [ 1: AVG | 2: Resting AVG | 3: INF | 4: CSD ] 
% If left empty User Identify in CMD Line
prm.erpclass = {'resp-lock' ; 'stim-lock'}; % 'resp-lock OR stim-lock =-> should match Bin def file (.bdf) directories
% prm.erpclass = 'stim-lock'; 
prm.applyld = 1; % apply linear detrend to PRE
prm.addfiltlp = [12.0 ; 30.0]; %12.0; % Additional Lowpass filter (Keep empty if not needed)
prm.epochrange = [-400 1000 ; -100 1000]; % -400 1000 ;
% prm.epochrange = [-100 1000];
prm.baseline = [-400 -200 ; -100 0]; % -400 -200 ;
% prm.baseline = [-100 0];
prm.voltagerange = [-75 75];

open CREED_GenerateERPs.m

run_proc = input('Would you like to run CREED_GenerateERPs? ', 's');
if strcmpi(run_proc, 'Yes') || strcmpi(run_proc, 'Y')
    CREED_GenerateERPs(prm);
end

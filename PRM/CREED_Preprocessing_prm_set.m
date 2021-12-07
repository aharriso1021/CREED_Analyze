%
%                             CREED Preprocessing Parameter Settings                       % 
%                                                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc;
prm = struct();

%%------------------------------------------------------------------------------------------ 
% Directory Settings & Required Fields
%------------------------------------------------------------------------------------------- 
%% PC PCATH
if ispc
    drvr = input('Indicate working driver for (ex: D:\): ', 's');
    prm.drvr = drvr;
    prm.matlabdir = [drvr, '\MATLAB\CREED_Analyze\'];
    prm.eeglabdir = [drvr, '\MATLAB\eeglab'];
        addpath(genpath(prm.matlabdir));addpath(prm.eeglabdir);
    prm.datadirDEX =     [drvr, '\DATA\CREED_ParticipantData\DEX\'];
    prm.datadirGZE = [drvr, '\DATA\CREED_ParticipantData\GAZE\'];
    prm.datadirEEG = [drvr, '\DATA\CREED_ParticipantData\EEG\']; % Must contain RAWDATA.set folder sorted by PARTICIPANT

%% MAC PATH
elseif isunix
    prm.matlabdir = '/Volumes/HARRISON_TB/MATLAB/CREED_Analyze';
    prm.eeglabdir = '/Volumes/HARRISON_TB/MATLAB/eeglab';
        addpath(genpath(prm.matlabdir));addpath(prm.eeglabdir);
    prm.datadirDEX = '/Volumes/HARRISON_TB/DATA/CREED_ParticipantData/DEX/';
    prm.datadirGZE = '/Volumes/HARRISON_TB/DATA/CREED_ParticipantData/GAZE/';
    prm.datadirEEG = '/Volumes/HARRISON_TB/DATA/CREED_ParticipantData/EEG/';
end

prm.proc_steps = {
                '1.RECODE.set'
                '2.PRE_ICA.set' 
                '3.ICA.set'
                '4.CLEAN.set'
                };
    
prm.eegFileType = '*.vhdr'; % specific output file from EEG Recording Software
prm.TaskList = [
%                 "APST"
%                 "PRVT"
%                 "RHRV" 
                "GNGB"
                "NGGB"
                "GNGR"
                "NGGR"
                "GNGC"
                "NGGC"
                    ];
  
%%------------------------------------------------------------------------------------------
% Step 1: BVA + DEX Recode
%-------------------------------------------------------------------------------------------
prm.filehandle{1} = '_recode.set';
prm.resample = 250; % [];  
%%------------------------------------------------------------------------------------------
% Step 2: Pre-ICA Cleaning 
%-------------------------------------------------------------------------------------------
prm.filehandle{2} = '_pICA.set';
prm.datatrim = 1; % Option to cut data before 1st and after last event code
prm.nChan = 64; 
prm.OnlineRef = 'FCz';
prm.KillChanID = {'FT9'  'TP9'...
                  'O1'   'PO7' 'P7' 'TP7' 'T7'  'FT7' 'F7'  'AF7'... 
                  'PO3'  'P1'  'P5' 'P3'  'CP3' 'CP5' 'C3' 'C5' 'Fp1'... % 'C3' 'C5' 'FC5' 'F5'  'C1' 'CP1'
                  'FT10' 'TP10'...
                  'O2'   'PO8' 'P8' 'TP8' 'T8'  'FT8' 'F8'  'AF8'... 
                  'PO4'  'P6'  'P2' 'P4'  'CP4' 'CP6' 'C4' 'C6' 'Fp2'... %'C4' 'C6' 'FC6' 'F6' 'C2' 'CP2'
                  'Oz'   'POz'  ;... % 'CPz' 'Pz'
                  };
prm.FilterDesign = 'BandPass'; 
prm.hp = 1.0; % lower bound of Frequency Band of interest  (HIGHPASS FILTER)
prm.lp = 50.0; % upper bound of Frequency Band of interest (LOWPASS FILTER) 
prm.nt = [];
prm.ASRclean = 1;
%%------------------------------------------------------------------------------------------
% Step 3: Run ICA
%-------------------------------------------------------------------------------------------
prm.filehandle{3} = '_ica.set';
prm.ICAtype = 'INFOMAX'; % Select ICA algorithm (Current: Infomax or Picard)

%%------------------------------------------------------------------------------------------
% Step 4: Blink Art Removal, Cleaning, & Re-Reference
%-------------------------------------------------------------------------------------------
prm.filehandle{4} = '_clean.set';
prm.icthresh = [0.55]; % Threshold for ID IC associated with NEURAL activity
prm.reftyppe = 'AVG'; 
prm.calcCSD = 1; % Binary to calculate CSD [1] = Yes; [0] = No (defaut = 1)
prm.mont_path = []; % Set path to electrode montage .csd file (if empty will search in pipeline)
prm.calcINF = 1;


open CREED_Preprocessing.m

run_proc = input('Would you like to run CREED_Preprocessing? ', 's');
if strcmpi(run_proc, 'Yes') || strcmpi(run_proc, 'Y')
    CREED_Preprocessing(prm);
end
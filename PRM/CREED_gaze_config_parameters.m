
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                CREED Gaze Data Processing Parameters                  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Dirsctory Settings [PC]
if ispc
drive = input('Define working driver (ex D:\): ', 's');
prm.dir_raw_in =  [drive '\DATA\CREED_ParticipantData\DEX\1.DEX.trim']; % Pathway to data Directory - organized by participants
prm.dir_red_out = [drive '\DATA\CREED_ParticipantData\GAZE\1.APST.red']; % Path to where you want the data to go - will spit out 1file/block
prm.dir_prc_out = [drive '\DATA\CREED_ParticipantData\GAZE\2.APST.prc']; % Path to where you want to save processed paramerters - trial-by-trial correction
prm.dir_ppl_out = [drive '\DATA\CREED_ParticipantData\GAZE\3.APST.ppl']; % Path to where you want to save processed pupil data
prm.dir_ecl_out = [drive '\DATA\CREED_ParticipantData\GAZE\4.APST.ecl']; % Path to where you want to save generated eventlist 
prm.dir_mat = [drive '\MATLAB\CREED_Analyze']; % Path to MATLAB scripts
elseif isunix
%% Dirsctory Settings [MAC]
prm.dir_raw_in =  '/Volumes/HARRISON_TB/DATA/CREED_ParticipantData/DEX/1.DEX.trim'; % Pathway to data Directory - organized by participants
prm.dir_red_out = '/Volumes/HARRISON_TB/DATA/CREED_ParticipantData/GAZE/1.APST.red'; % Path to where you want the data to go - will spit out 1file/block
prm.dir_prc_out = '/Volumes/HARRISON_TB/DATA/CREED_ParticipantData/GAZE/2.APST.prc'; % Path to where you want to save processed paramerters - trial-by-trial correction
prm.dir_ppl_out = '/Volumes/HARRISON_TB/DATA/CREED_ParticipantData/GAZE/3.APST.ppl'; % Path to where you want to save processed pupil data
prm.dir_ecl_out = '/Volumes/HARRISON_TB/DATA/CREED_ParticipantData/GAZE/4.APST.ecl'; % Path to where you want to save generated eventlist 
prm.dir_mat =     '/Volumes/HARRISON_TB//MATLAB/CREED_Analyze/'; % Path to MATLAB scripts
end
    addpath(genpath(prm.dir_mat));
%% Task Settings
prm.Task = {'APST01'
%             'GNGB'
%             'GNGR'
            %'GNGC'
%             'NGGB'
%             'NGGR'
            %'NGGC'
            }; % what task you would like to process
prm.Task_var = []; % task variant - recommend keeping blank + define within code

prm.gazeFs = 500; % Sampling Rate of EyeTracking System
prm.roboFs = []; % Sampling Rate of Task - default: EMPTY = defines from data file

prm.WorkSpaceX = [-0.4 0.4]; % MIN:MAX of workspace X-dimension (m)
prm.WorkSpaceY = [-0.1 0.7]; % MIN:MAX of workspace Y-dimension (m)

%% Blink Correction Settings == Additions from TMH to gp with Blink Correction3
prm.pre_blink = 25; % Pad blinks before the blink onset is detected
prm.post_blink = 75; % Pad blinks after the blink end is detected
prm.blink_init = 0; % Initialization of blink is always 0 (ms)
prm.blink_dur = 200; % Maximum duration allocated for blinks
prm.sacc_dur = 50; % Typyical duration of saccades (ms)
prm.fov_rad = 15; % Width of foveal radius beyond which = saccade
prm.sacc_init = 25; % Initialization of saccade after blink (ms)

%% Gaze Filter Settings
prm.SGolayF = 41;
prm.SGolayK = 8;
prm.freq_cutoff_gaze = 15; % Freq cutt off for dblpass filter (Hz)
prm.freq_cutoff_pupil = 10; 

%% Saccade Threshold Criteria
prm.sacc_threshold = [30 6000];
% prm.mle_iterations = 1500; % MAX number of iterations for max likelihood estimate of saccade threshold

%% Pupilometry Processing
prm.miss_data_cut = .4; % MAX % missing data during fixation period  
prm.gaze_move_thresh = 25; % MAX amount of gaze deviation during fixation period

open CREED_gaze_reduction.m

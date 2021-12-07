%% APST Visual Processing                                                %%
% Search within participant file for APST 


function CREED_gaze_reduction(prm)
%%-------------------------------------------------------------------------------------------------------
addpath(genpath(prm.dir_raw_in)); addpath(genpath(prm.dir_red_out)); addpath(genpath(prm.dir_prc_out)); addpath(genpath(prm.dir_ppl_out)); addpath(genpath(prm.dir_ecl_out));
addpath(genpath(prm.dir_mat));
%%-------------------------------------------------------------------------------------------------------
clc;
cd(prm.dir_raw_in)
participant_fldrs = dir('*.dex');
pFldr_names = string({participant_fldrs.name});

%%-------------------------------------------------------------------------------------------------------    
for fldi = 1:length(pFldr_names)
    cd(pFldr_names(fldi))
    taskFi = dir('*.zip');
    taskFi_names = char({taskFi.name});
        avail_tasks = string(taskFi_names(:,11:16));
    if ismember(prm.Task,avail_tasks)
        taskIdx = find(ismember(avail_tasks,prm.Task));
        for ti = 1:length(taskIdx) 
            if ~exist([taskFi_names(ti,1:16) 'red.mat'], 'file')
                rawdata = LOADFILES.zip_load(taskFi_names(taskIdx(ti),:));
                rawdata = c3d_reorder(rawdata);
                if isempty(prm.roboFs)
                    prm.roboFs = rawdata(1).ANALOG.RATE;
                end
                if isempty(prm.Task_var)
                    prm.Task_var = rawdata(1).EXPERIMENT.TASK_PROTOCOL;
                end
                clc;
            fprintf('################################################################################\n\n');
            fprintf('Begin Blink Correction: %s \n\n', taskFi_names(ti, 1:16));
            fprintf('################################################################################\n\n'); 
                try
                    [clean_data, gaze_kinData] = gaze_reduction(taskFi_names(taskIdx(ti),:), rawdata, prm);
                catch
                    keyboard;
                end
                    task_var = prm.Task_var;
                cd(prm.dir_red_out)
                save([taskFi_names(ti,1:16) 'red.mat'], 'rawdata', 'clean_data','gaze_kinData', 'task_var')
            end % END Gaze Reduction
            
            if ~exist([taskFi_names(ti,1:16) 'prc.mat'], 'file')
                if ~exist('gaze_kinData', 'var') % Checks to see if data is loaded
                     cd(prm.dir_red_out)
                     load([taskFi_names(ti,1:16),'red.mat']);
                end
            clc;
            fprintf('################################################################################\n\n');
            fprintf('Computing Task Parameters: %s \n\n', taskFi_names(ti, 1:16));
            fprintf('################################################################################\n\n');
                [APST_trialparameters, APST_trialdynamics] = gaze_parameters(gaze_kinData, clean_data, taskFi_names(ti, 1:16), prm);
                %
                cd(prm.dir_prc_out)
                save([taskFi_names(ti,1:16), 'prc.mat'], 'clean_data', 'gaze_kinData', 'APST_trialparameters', 'APST_trialdynamics');
            end % END Gaze Parameter Processing
            
            if ~exist([taskFi_names(ti,1:16) 'ppl.mat'], 'file')
                if ~exist('APST_trialparameters', 'var') % Checks to see if data is loaded
                     cd(prm.dir_prc_out)
                     load([taskFi_names(ti,1:16),'prc.mat']);
                end
            clc;
            fprintf('################################################################################\n\n');
            fprintf('Computing Pupil Based Parameters: %s \n\n', taskFi_names(ti, 1:16));
            fprintf('################################################################################\n\n');
                    [APST_pupildynamics] = pupil_reduction(gaze_kinData, APST_trialdynamics, APST_trialparameters, prm);
                cd(prm.dir_ppl_out)
                save([taskFi_names(ti,1:16) 'ppl.mat'], 'clean_data', 'gaze_kinData', 'APST_trialparameters', 'APST_trialdynamics', 'APST_pupildynamics')
            end % END Pupil Processing Cleaning
            if ~exist([taskFi_names(ti,1:16) 'ecl.mat'], 'file')
                if ~exist('gaze_kinData', 'var') % Checks to see if data is loaded
                     cd(prm.dir_red_out)
                     load([taskFi_names(ti,1:16),'prc.mat']);
                end
            fprintf('################################################################################\n\n');
            fprintf('Re-calculating Eventlist: %s \n\n', taskFi_names(ti, 1:16));
            fprintf('################################################################################\n\n');    
                APST_event_list = APSTevent_codes_rewrite(APST_trialdynamics, APST_trialparameters, gaze_kinData, clean_data(1).EVENT_DEFINITIONS);
                %
                cd(prm.dir_ecl_out)
                save([taskFi_names(ti,1:16), 'ecl.mat'], 'APST_event_list');
            end % END Eventlist re-calculation
         clearvars APST_event_list APST_trialdynamics APST_trialparameters clean_data gaze_kinData % NEEDS TO REMAIN @ END OF TASK PROCESSING STEPS
        end % END TASK PROCESSING
    else
    end % END Task Check
cd(prm.dir_raw_in)
end % END Participant Loop
end % END Function

%% 
function [data_out, gaze_kinData] = gaze_reduction(file_info, data, prm)
data_out = data;
% blink_prm = prm.blink;
nTrials = length(data);
unfilt_data = data;
gaze_kinData = [];

for trial_i = 1:nTrials
    % Correct for Trial Blinks in 'un-filtered data'
%% Resample IF necessary

if prm.roboFs > prm.gazeFs
    rs_unfilt_data = resample_gaze_data(unfilt_data(trial_i), prm.roboFs);
elseif prm.roboFs < prm.gazeFs
    error('KINARM samplin rate should always be greater of equal to EyeTracking sampling rate. Check parameter (prm) settings');
else
    rs_unfilt_data = unfilt_data;
end
clc;
fprintf('################################################################################\n\n');
fprintf('Processing trial: %s \n\n', string(trial_i));
fprintf('################################################################################\n\n');

%% Check for blinks/loss eye position in the gaze data [stamped w/ -100 = default from DEX]    
if ~isempty(find(rs_unfilt_data.Gaze_X <= -99 | rs_unfilt_data.Gaze_Y <= -99 | rs_unfilt_data.Gaze_PupilArea <= 0))
    try 
        [blink_corrected_data, blink_parameters] = CREED_blink_correction(rs_unfilt_data, file_info(1:9), trial_i, prm);  
    catch
        keyboard;
    end
else
    blink_corrected_data = rs_unfilt_data;
    blink_parameters.nBlinks= 0;
    blink_parameters.blink_logi = logical(zeros([length(blink_corrected_data.Gaze_X) 1]));
    blink_parameters.onsets = NaN;
    blink_parameters.ends   = NaN;
    blink_parameters.durations = 0;
    blink_parameters.total_duration = 0;
    blink_parameters.gaze_out_X = logical(zeros([length(blink_corrected_data.Gaze_X) 1]));
    blink_parameters.gaze_out_Y = logical(zeros([length(blink_corrected_data.Gaze_X) 1]));
end

%% Filter GAZE & PUPIL data 
% Initialize Filter Variables
lpG = prm.freq_cutoff_gaze;
lpP = prm.freq_cutoff_pupil;
Fs  = prm.roboFs;
%
filt_data = FILTER.CREED_c3d_filter_dblpass(blink_corrected_data, 'enhanced', 'fc', lpG);
    % Seperate FILTER for PUPIL - steps copied from above
    [B, A] = FILTER.create_filtercoeff_for_dblpass(lpP, Fs);
    n_refl = round(Fs, lpP);
    % create zbias
    zBias = FILTER.create_zibasis(B, A);
    % filter data
    filt_data.Gaze_PupilArea = FILTER.double_pass_filter_enhanced(filt_data.Gaze_PupilArea, n_refl, B, A, zBias);
filt_data.Gaze_TimeStamp = blink_corrected_data.Gaze_TimeStamp; % safegard in casse Time Stamps were filterd

%% Computing Gaze kinematic variables
gaze_kin_trial = CREED_GazeData(filt_data, blink_parameters, prm);
%     
%     gaze_kin_trial = CREED_check_for_existence_of_blinks(file_info, filt_data, gaze_kin_trial, prm, trial_i);
        %% Gaze ACC re-class + sacc velocity calculations (look through research for other variables)
    
gaze_kinData = [gaze_kinData ; gaze_kin_trial];
data_out(trial_i) = filt_data;
end

end

function [APST_trialperf, APST_trialdynm] = gaze_parameters(gaze_data, trial_data, subj_info, prm)
APST_trialperf = [];
APST_trialdynm = [];
kin_dat = [trial_data];

% if ~isempty(prm.mle_iterations)
%     mle_iter = prm.mle_iterations;
% else
%     mle_iter = 1000;
% end

%%
for itrial = 1:length(gaze_data)
    warning off
    if ~isnan(gaze_data(itrial).Gaze_X)
        minST = [20 6000]; % Hard set gaze thresholds
%     if ~isnan(gaze_data(itrial).Gaze_X)
%             [~, ~, ~, ~, minST(2)] = compute_log_normal_saccade_threshold_apst_acceleration(gaze_data(itrial).Gaze_Ang_Acc, mle_iter); close; 
%             [~, ~, ~, ~, minST(1)] = compute_log_normal_saccade_threshold_apst(gaze_data(itrial).Gaze_Ang_Vel, mle_iter); close; 
    else
        sacc_threshold = NaN;
    end % END isnan check
%% Need to build in a BLINKS DURING EPOCH CHECK %%
[trialperf, trial_dynamics] = calcAPSTPerformance(gaze_data(itrial), kin_dat(itrial), subj_info, minST, itrial, APST_trialperf);

APST_trialperf = [APST_trialperf ; trialperf];
APST_trialdynm = [APST_trialdynm ; trial_dynamics];
end % END Trial Loop
end % END Function

function APST_pupildyn = pupil_reduction(gaze_data, trial_info, trial_dyn, prm)   
    max_missing_data = prm.miss_data_cut;
    gaze_dev_thresh  = prm.gaze_move_thresh;
% Trial x Trial
    [APST_pupildyn] = APSTPupilRed(gaze_data, trial_info, trial_dyn, max_missing_data, gaze_dev_thresh);
    
end % End Pupil Processing
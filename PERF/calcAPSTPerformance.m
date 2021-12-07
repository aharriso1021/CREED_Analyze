%% ------------------------------------------------------------------------------------------------------------------------ %%              
% Calculate Saccade Behavior [APST] - HARRISON 2021                                                                          %
% Detect saccade onset within trial based on established velocity and acceleration thresholds                                %
% Use determined saccade onset to generate trial performance                                                                 %
%                                                                                                                            %
%                           INPUT IS TRIAL DATA RECOMMEND PUTTING FUNCTION WITHIN FOR LOOP                                   %
% -------------------------------------------------------------------------------------------------------------------------- %
% [OUTPUT]                                                                                                                   %
% trial_behavior = data structure containing basic gaze task related parameters                                              %
%   .TrialCondition - Trial type (ANTI v. PRO)                                                                               %
%   .Native_Accuracy - Trial accuracy as determined by KINARM Task                                                           %
%   .Trial_Accuracy - Trial accuracy detemined by code                                                                       %
%   .SRT - Saccade Reaction Time [Target Onset --> Saccade Onset] (ms)                                                       %
% trial_dyn = data structure containing indexing of key task related events                                                  %
%   .fix_targ_idx - col index of FIXATION TARGET APPEARANCE                                                                  %
%   .lat_targ_idx - col index of PERIPHERAL TARGET APPEARANCE                                                                %
%   .sacc_idx - col index of SACCADE ONSET                                                                                   %
% [INPUT]                                                                                                                    %
% gaze_data = corresponding TRIAL gaze_kine_data (cleaned gaze behavior & calculated kinematics)                             %
% trial_data = corresponding TRIAL DEX data (TP & Event information)                                                         %
% subj = SUBJECT INFORMATION (plotting)                                                                                      %
% sacc_threshold = saccade velocity and acceleration thresholds (ex: [20 6000])                                              %
% trial_idx = index of current trial (plotting)                                                                              %
%% ------------------------------------------------------------------------------------------------------------------------ %% 

function [trial_behavior, trial_dyn] = calcAPSTPerformance(gaze_data, trial_data, subj, sacc_threshold, trial_idx, trial_perf)
%% Initialize Variables
trial_dyn.trial_time = gaze_data.TrialTime;
trial_event_labels = deblank(gaze_data.TrialEventsLabels);
trial_event_times = gaze_data.TrialEventsTimes;

gaze_x = gaze_data.Gaze_X;
gaze_y = gaze_data.Gaze_Y;
blinks = gaze_data.blink_parameters.blink_logi;

speed_matrix = [gaze_data.Gaze_Ang_Vel gaze_data.Gaze_Ang_Acc];

% Trial Dynamics Variables
trial_dyn.fix_targ_idx = round(trial_event_times(find(ismember(trial_event_labels, {'Condition (Pro)', 'Condition (Anti)'})))*1000+25); % TIME index of Central Fixation Target ON (ms)
trial_dyn.eye_on_fix_idx = round(trial_event_times(find(ismember(trial_event_labels, {'Gaze on Central Fixation'})))*1000+25);
trial_dyn.lat_targ_idx = round(trial_event_times(find(ismember(trial_event_labels, {'Target On (Pro)', 'Target On (Anti)'})))*1000+25); % TIME index of Lateral Target ON (ms)
trial_window_time = trial_dyn.trial_time(trial_dyn.lat_targ_idx:end);

% Trial Description - define Trial Type (ANTI:PRO) and Target Location (LEFT:RIGHT)
% Will be used to determine TRIAL ACCURACY
trial_Condition = [];
targ_location = [];
    if trial_data.TRIAL.TP == 1
        trial_Condition = 'ANTI';
        targ_location = 'LEFT';
    elseif trial_data.TRIAL.TP == 2
        trial_Condition = 'ANTI';
        targ_location = 'RIGHT';
    elseif trial_data.TRIAL.TP == 3
        trial_Condition = 'PRO';
        targ_location = 'LEFT';
    elseif trial_data.TRIAL.TP == 4
        trial_Condition = 'PRO';
        targ_location = 'RIGHT';
    end

%% TRIAL Behavior
% ID FIRST Saccade over THRESHOLD after LATERAL TARGET PRESENTATION
valid = 0;
if ~isnan(sacc_threshold)
valid = 1;
window_gaze_mat = speed_matrix(trial_dyn.lat_targ_idx:end,:); % TRIM DATA from LAT TARG ON to END of trial 
loc_sacc = 0;

    while loc_sacc == 0 % Sacc onset finder == > Acc Threshold && > Vel threshold for 30ms
    sacc_idx = find(window_gaze_mat(:,2) >= sacc_threshold(2),1,'first'); % Identify FIRST/NEXT occurance of ang_acc > THRESHOLD
        try vel_sacc32 = window_gaze_mat(sacc_idx:sacc_idx+30,1); %
        catch
            vel_sacc32 = window_gaze_mat(sacc_idx:end,1);
        end
        if ~isempty(find(vel_sacc32 < sacc_threshold(1),1)) % tests if current point (acc>thresh) ang_velocity > THRESHOLD for 30ms
            window_gaze_mat(sacc_idx,2) = NaN; % IF NO NaN current point and move to next
        else
            loc_sacc = 1; % IF YES mark point as saccade onset
        end
    end
end
% Unable to ID sacc_idx - manual ID or reject
% Sometimes (based on data quality or erratic eye behavior) above algorithm
% is unabel to detect a saccade

% Plots X data and gives user ability to manually detect saccade
if isempty(sacc_idx)
    plot(gaze_x, 'k-', 'LineWidth', 1.0)
    hold on 
        a = gca;
    try, plot([trial_dyn.lat_targ_idx trial_dyn.lat_targ_idx], [a.YLim], 'r--', 'LineWidth', 0.7);
    catch
        keyboard;
    end
        h1 = title({strcat(subj, ' Trial: ', string(trial_idx)) ; 'Unable to ID Saccade in Data - Manually Select (Y) or Reject (N)'});
        h1.Interpreter = 'none';
        user_id = input('Manual Selection [0 (NO) /1 (YES)]? ');
    if user_id == 1
        [idx,~] = ginput(1);
        sacc_idx = round(idx - trial_dyn.lat_targ_idx);
    else
        valid = 0;
    end
    cla;
end
% Trial too long / unable to accurately capture pupil 
% if length(gaze_x) > 5000
%     valid = 0;
% end

%% Discards trial if too much data is lost during fixation period
% Loss of Data > 25% of Fization Period
if sum(blinks(trial_dyn.fix_targ_idx:trial_dyn.lat_targ_idx)) > (length(gaze_x(trial_dyn.fix_targ_idx:trial_dyn.lat_targ_idx))*.25)
    valid = 0;
end

if valid == 1
trial_dyn.sacc_idx = trial_dyn.lat_targ_idx + sacc_idx;
srt = (trial_window_time(sacc_idx) - trial_window_time(1))*1000;

%% Plot Trial Data to confirm SACCADE ONSET ACCURACY - allows user to verify, manually overrde saccade onset, or delete trial

% ZERO Gaze X & Y Data
relx = gaze_x - gaze_x(1);
rely = gaze_y - gaze_y(1);
    lx = plot(relx, 'k-', 'LineWidth', 1.0);
    hold on
    ly = plot((rely+max(relx)), 'm-', 'LineWidth', 1.0);
%     ly = plot(gaze_y, 'm-', 'LineWidth', 1.0);
        a = gca;
        x = 1:1:length(gaze_x);
        if sum(blinks) > 0
            plot(x(blinks), relx(blinks), 'r.');
            plot(x(blinks), (rely(blinks)++max(relx)), 'g.');
        end
        lf = plot([trial_dyn.fix_targ_idx(end) trial_dyn.fix_targ_idx(end)], [a.YLim(1) a.YLim(2)], '-g', 'LineWidth', 0.7);
        lt = plot([trial_dyn.lat_targ_idx trial_dyn.lat_targ_idx], [a.YLim(1) a.YLim(2)], '-b', 'LineWidth', 0.7);
        ls = plot([trial_dyn.lat_targ_idx trial_dyn.lat_targ_idx] + srt, [a.YLim(1) a.YLim(2)], '--b', 'LineWidth', 0.7); 
        h2 = title(strcat(subj, ' Trial: ', string(trial_idx), ' - Accept Current Saccade onset?'));
            h2.Interpreter = 'none';
%             a.YLim = [-100 200];
    fprintf('Trial RT: %s \n\n', srt);
    acc_togg = input('Accepnt current parameters [1(Y)/2 (N) -or- 0 (NaN)]?: ');
    if acc_togg == 2
        delete(ls);
        fprintf('Select new point');
        [gui_sacc_idx,~] = ginput(1);
        trial_dyn.sacc_idx = round(gui_sacc_idx);
        srt = round(gui_sacc_idx) - trial_dyn.lat_targ_idx;
    elseif acc_togg == 0
        srt = NaN;
    end
    cla; clc;
    
%% Calculate Trial Performance Measures from
if ~isnan(srt)
% Determine direction of saccade (based on sign of Gaze X for 50 samples after PERIPHERAL TARG ONSET
    sacc_X_movement = gaze_x(trial_dyn.sacc_idx:end) - gaze_x(trial_dyn.sacc_idx);
sacc_direction = [];
    try 
        if mean(sacc_X_movement(1:50)) > 0
        sacc_direction = 'RIGHT';
        elseif mean(sacc_X_movement(1:50)) < 0
        sacc_direction = 'LEFT';
        end
    catch
        keyboard;
    end
    
%% Calculate Trial PERFORMANCE VARIABLES
trial_behavior.Trial_Condition = trial_Condition;
trial_behavior.Native_Accuracy = [];
    if ~isempty(find(ismember(trial_event_labels, {'Correct (Pro)', 'Correct (Anti)'})))
        trial_behavior.Native_Accuracy = 1;
    elseif ~isempty(find(ismember(trial_event_labels, {'Time Out Error (Pro)', 'Time Out Error (Anti)'})))
        trial_behavior.Native_Accuracy = -99;
    else
        trial_behavior.Native_Accuracy = -1;
    end
% DOES SACCADE MOVEMENT DIRECTION MATCH EXPECTED
trial_behavior.Trial_Accuracy = [];
    if strcmp(trial_Condition, 'ANTI') && ~strcmp(sacc_direction,targ_location) % TARGET LOCATION ~= SACC DIRECTION
        trial_behavior.Trial_Accuracy = 1;
    elseif strcmp(trial_Condition, 'PRO') && strcmp(sacc_direction,targ_location) % TARGET LOCATION == SACC DIRECTION
        trial_behavior.Trial_Accuracy = 1;
    else
        trial_behavior.Trial_Accuracy = -1;
    end
trial_behavior.SRT = srt;
else
end
else
end

if valid == 0 || isnan(srt)
    trial_behavior.Trial_Condition = trial_Condition;
    trial_behavior.Native_Accuracy = NaN;
    trial_behavior.Trial_Accuracy = NaN;
    trial_behavior.SRT = NaN;
    
%     trial_dyn.trial_time = NaN;
    trial_dyn.fix_targ_idx = NaN;
    trial_dyn.lat_targ_idx = NaN;
    trial_dyn.sacc_idx = NaN;
end
end
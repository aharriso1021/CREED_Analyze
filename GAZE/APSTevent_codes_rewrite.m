function [APST_event_tbl] = APSTevent_codes_rewrite(APST_dyn, APST_prf, APST_gze_data, event_def_list)
APST_event_tbl = table();
end_time = 0;
tnTrials = 0;

event_def_codes  = event_def_list.CODES;
event_def_labels = strtrim(event_def_list.LABELS);


%% Need to build in catch for NaN trials
for iTrial = 1:length(APST_dyn)
% Variable Initialization
trial_dyn = APST_dyn(iTrial);
trial_prf = APST_prf(iTrial);
trial_gze = APST_gze_data(iTrial);
    trial_event_labels = trial_gze.TrialEventsLabels;
    trial_event_times  = int16(trial_gze.TrialEventsTimes*1000);
        trial_event_times = double(trial_event_times);
    % Remove Default Gaze Codes
    xcodes = ismember(trial_event_labels, {'Gaze saccade start' 'Gaze saccade end' 'Gaze fixation start' 'Gaze fixation end'...
        'Gaze blink start' 'Gaze blink end'});
    trial_event_labels(xcodes) = [];
    trial_event_times(xcodes)  = [];

%% Generate Event Codes for Clean Trial
if ~isnan(trial_prf.Trial_Accuracy)
% Re-index Target Presentation 
    trial_event_times(find(ismember(trial_event_labels, {'Condition (Pro)' 'Condition (Anti)'}))) = trial_dyn.fix_targ_idx;
    trial_event_times(find(ismember(trial_event_labels, {'Target On (Pro)' 'Target On (Anti)'}))) = trial_dyn.lat_targ_idx;
% Behavioral Coding 
    % Trial Condition
    if ismember(trial_prf.Trial_Condition, 'PRO')
        cond = '(Pro)';
    else
        cond = '(Anti)';
    end
    % Trial Accuracy
    if trial_prf.Trial_Accuracy == 1
        acc = 'Correct';
    else 
        acc = 'Error';
    end
    perf_code = [acc ' ' cond];
%
nat_beh_idx = find(ismember(trial_event_labels, {'Correct (Anti)' 'Correct (Pro)' 'Error (Anti)' 'Error (Pro)' 'Time Out Error (Anti)' 'Time Out Error (Pro)'}));
    trial_event_labels(nat_beh_idx) = {perf_code};
    trial_event_times(nat_beh_idx)  = trial_dyn.sacc_idx;
%% Generate Numerical Code for Events
trial_event_codes = [];
for iEvent = 1:length(trial_event_labels)
    label_idx = find(ismember(event_def_labels, trial_event_labels(iEvent)));
    trial_event_codes = [trial_event_codes ; event_def_codes(label_idx)];
end % Trial event LOOP
        trial_event_labels(find(ismember(trial_event_labels, {'Condition (Pro)' 'Condition (Anti)'}))) = ...
            strcat(strcat(trial_event_labels(find(ismember(trial_event_labels, {'Condition (Pro)' 'Condition (Anti)'})))), '-CFT On'); % Clarify Event    
%% Generate Trial Table
trial_tbl = table('Size', [length(trial_event_labels) 8], 'VariableType', {'double', 'double', 'double', 'double', 'double', 'string', 'string', 'double'},...
    'VariableNames',{'latency', 'duration', 'channel', 'bvtime', 'bvmknum', 'type','code', 'urevent'});
    trial_tbl.latency  = trial_event_times' + end_time;
        end_time = end_time + length([APST_gze_data(iTrial).TrialTime]);
    trial_tbl.duration = ones([length(trial_event_labels) 1]);
    trial_tbl.channel  = zeros([length(trial_event_labels) 1]);
    trial_tbl.bvtime   = [];
    trial_tbl.bvmknum  = (1:1:length(trial_event_labels))' + tnTrials';
    trial_tbl.type     = trial_event_codes;
    trial_tbl.code     = trial_event_labels';
    trial_tbl.urevent  = (1:1:length(trial_event_labels))' + tnTrials;    
        tnTrials = tnTrials + length(trial_event_labels);    
else % Trial is invalid == no added events - just added time
    end_time = end_time + length([APST_gze_data(iTrial).TrialTime]);
    trial_tbl = [];
end % Trial NaN Check for valid trial
APST_event_tbl = [APST_event_tbl ; trial_tbl];
trial_tbl = [];
end % Task trial LOOP
end % Function End

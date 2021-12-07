function CREED_pupilbehavior(gaze_data_in, task_events)
nTrial = length(gaze_data_in);
Pupil_beh = [];
% Loop thru Trials
for i = 1:nTrial
    trial_data = gaze_data_in(i);
    trial_dynm = task_events(i);
end
end
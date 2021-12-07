function [data_non_filtered_gaze_and_blink_corrected, blink_parameters] = CREED_blink_correction(data_non_filtered, subj_info, trial_i, prm)
%This function takes the un_filtered gaze data as inputs, interpolates the
%data for the sampling rate of the robot and then corrects for blinks. This
%is a preliminary correction. It only accounts for the blinks when the
%eye-tracker lost the pupils.

%% Adapted from Tarkesh's 'Analyze Code'

%% Intialize Parameters gaze_Fs,blink_correct_para, 
robot_Fs = prm.roboFs; 
gaze_Fs  = prm.gazeFs;
work_spaceX = prm.WorkSpaceX;
work_spaceY = prm.WorkSpaceY;
% 
saccade_latency = prm.sacc_init;
foveal_radius_vision = prm.fov_rad;
saccade_durations = prm.sacc_dur;
blink_latency = prm.blink_init;
max_blink_duration = prm.blink_dur;
% pre_blink = prm.pre_blink;
% post_blink = prm.post_blink;
%
data_non_filtered_gaze_and_blink_corrected = data_non_filtered;
%
X = data_non_filtered.Gaze_X;
Y = data_non_filtered.Gaze_Y;
P = data_non_filtered.Gaze_PupilArea;

%% Search for and remove blinks
% Initial search for blinks
blink_p = P < 0;  % Find negative pupil values, which are only found during blinks
blink_x = [abs(diff(X))>(100/robot_Fs); 0]; % Find gaze x segments where vel>100 m/s
blink_y = [abs(diff(Y))>(100/robot_Fs); 0]; % Find gaze y segments where vel>100 m/s
blinks = any([blink_p blink_x blink_y],2); % Collapse across blink indices == compl blink index 

%% Find small nonnan segments between blinks (set to 50 but can be modified based on need)
i_short = find_short_nonnan_segments(blinks,50);
blinks(i_short) = true;

%% Visually Inspect Blinks 
blink_diff = [0 ; diff(blinks)];
i = find(blink_diff == 1); % indeex of all FIRST NaN in Blink (blink init)
o  = (find(blink_diff == -1)-1); % index of all LAST NaN in Blink (blink offset)
    if ~isequal(length(i), length(o)) % catch for blinks in beginning:end of trial
        if isempty(o) 
            o = length(Y);
        elseif isempty(i)
            i = 1;
        elseif i(end) > o(end)
            o = [o ; length(Y)];
        elseif o(1) < i(1)
            i = [1 ; i];
        end
    end
    % Final catch to see for blinks in beginning:end of trial
    if i(end) > o(end)
        o = [o ; length(Y)];
    elseif o(1) < i(1)
        i = [1 ; i];
    end

ttime = 1:length(Y);    
y = Y;
% figure;
for blink_idx = 1:length(i)
y(blinks) = NaN;
if i(blink_idx)-25 <= 0
    blink_seg = 1:(o(blink_idx)+75);
elseif o(blink_idx)+75 > length(Y)
    blink_seg = (i(blink_idx)-25):length(Y);
else
    blink_seg = (i(blink_idx)-25):(o(blink_idx)+75);
end

% Plot Data - ID Exact Blink Onset
    plot(ttime, y, 'k-', 'LineWidth', 1);
    hold on
    plot(ttime(blink_seg), y(blink_seg), 'm-', 'LineWidth', 1);
    title(strcat(subj_info, ': Trial ', string(trial_i)));
        clc;
        fprintf('ID Blink onset:offset')
        [xi, ~] = ginput(2);
        xi = uint16(xi);
        xi = sort(xi); 
            if xi(1) <= 0
                xi(1) = 1;
            end
            if xi(2) > length(X)
                xi(2) = length(X);
            end
blinks(xi(1):xi(2)) = true;
cla;
end
 
% Catch to remove any overlap in onset/offset         
blink_diff = [0 ; diff(blinks)];
blink_init = find(blink_diff == 1);
blink_offs  = find(blink_diff == -1)-1;

% Adjustment for blinks at beginning/end for interpolation
   
blink_at_onset = blinks(1)==true;
if blink_at_onset
  blinks(1) = false;
end

blink_at_end = blinks(end)==true;
if blink_at_end
  blinks(end) = false;
end


%% Add NaNs to Gaze X, Gaze Y and Pupil data
X(blinks) = NaN; % All blink data set to NaN.
Y(blinks) = NaN;
P(blinks) = NaN;

if blink_at_onset
    X(1) = X(blink_offs(1)+1);
    Y(1) = Y(blink_offs(1)+1);
    P(1) = P(blink_offs(1)+1);
        blink_init = [2 ; blink_init];
end

if blink_at_end
    X(end) = X(blink_init(end)-1);
    Y(end) = Y(blink_init(end)-1);
    P(end) = P(blink_init(end)-1);
        blink_offs = [blink_offs ; length(blinks) - 1];
end

%% Add blink parameters (Note that some names are changed from Tarkesh's orignals)
blink_durations = blink_offs - blink_init+1;
n_blinks = length(blink_init);

blink_parameters.nBlinks = n_blinks;
blink_parameters.blink_logi = blinks;
blink_parameters.onsets = blink_init;
blink_parameters.ends   = blink_offs;
blink_parameters.durations = (blink_durations) * (1e3/robot_Fs);
blink_parameters.total_duration = sum(blink_parameters.durations);   
   
%% Fill in missing saccades and pupil changes during blink segments
X = X*1e3; % Temporarily convert from m to mm
Y = Y*1e3;
P = P*1e3;

saccade_onsets = blink_init + saccade_latency;
saccade_ends   = blink_offs   - saccade_latency;
saccade_durations = repmat(saccade_durations,n_blinks,1);
saccade_durations = min([saccade_durations blink_durations-saccade_latency],[],2);

[X] = fill_saccade_fix(X, 'gaze', foveal_radius_vision, blink_init, blink_offs,...
   saccade_onsets, saccade_ends, trial_i); % Fills the gaps due to blinks with a saccade and fixation.

[Y] = fill_saccade_fix(Y, 'gaze', foveal_radius_vision, blink_init, blink_offs,...
   saccade_onsets, saccade_ends, trial_i);

[P] = fill_saccade_fix(P, 'pupil',foveal_radius_vision, blink_init, blink_offs, [], [], trial_i); % See above amd CREED_gaze_config_parameters for max_blink_duration and blink_latency

X = X*1e-3; % Convert from mm back to m
Y = Y*1e-3;
P = P*1e-3;


%% This section removes data in which gaze is outside the workspace - If gaze goes outside workspace, set it to NaN;
blink_parameters.gaze_out_X = X > max(work_spaceX) | X < min(work_spaceX);
blink_parameters.gaze_out_Y = Y > max(work_spaceY) | Y < min(work_spaceY);
    
% P(X > max(work_spaceX)) = NaN;
% P(X < min(work_spaceX)) = NaN;
% P(Y > max(work_spaceY)) = NaN;
% P(Y < min(work_spaceY)) = NaN;
% 
X(X > max(work_spaceX)) = work_spaceX(2);    
X(X < min(work_spaceX)) = work_spaceX(1);
%
Y(Y > max(work_spaceY)) = work_spaceY(2);
Y(Y < min(work_spaceY)) = work_spaceY(1);

Blink_Corrected_Gaze_X = X; %*1e-3
Blink_Corrected_Gaze_Y = Y; %*1e-3
Blink_Corrected_Pupil = P;


%%
data_non_filtered_gaze_and_blink_corrected.Gaze_X = Blink_Corrected_Gaze_X;
data_non_filtered_gaze_and_blink_corrected.Gaze_Y = Blink_Corrected_Gaze_Y;
data_non_filtered_gaze_and_blink_corrected.Gaze_PupilArea = Blink_Corrected_Pupil;

end




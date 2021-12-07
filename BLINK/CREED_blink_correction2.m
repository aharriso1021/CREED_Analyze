function [data_non_filtered_gaze_and_blink_corrected, blink_parameters] = CREED_blink_correction2( data_non_filtered, robot_Fs, gaze_Fs,blink_correct_para, work_spaceX, work_spaceY)
%This function takes the un_filtered gaze data as inputs, interpolates the
%data for the sampling rate of the robot and then corrects for blinks. This
%is a preliminary correction. It only accounts for the blinks when the
%eye-tracker lost the pupils.

%% Adapte from Tarkesh 'Analyze Code'

%% Intialize Parameters
initiate_saccade_time=blink_correct_para.sacc_init;
foveal_radius_vision=blink_correct_para.fov_rad;
saccade_duration=blink_correct_para.sacc_dur;

%% ID Indices of Eye Position off Workspace & Loss of Pupil 
blink = find(data_non_filtered.Gaze_PupilArea <= 0); % Cannont have 0 or NEG Pupil Area 

X = data_non_filtered.Gaze_X;
Y = data_non_filtered.Gaze_Y;
P = data_non_filtered.Gaze_PupilArea;

X(blink) = NaN;    %All blink data set to NaN.
Y(blink) = NaN;
P(blink) = NaN;

%% This section computes the no. of blinks and their duration.
all_nan_elements_in_X = find(isnan(X));
consecutive_all_nan_elements_in_X = diff(all_nan_elements_in_X);
[c,d] = accumconncomps(consecutive_all_nan_elements_in_X);
e = [c d];
final_blink_matrix = e((e(:,1)==1),:);

blink_parameters.numbers = size(final_blink_matrix,1);
blink_parameters.durations = final_blink_matrix(:,2)*(1e3/robot_Fs);

%%
P(find(abs(diff(X))>(100/robot_Fs))) = NaN; %Add more NaNs if vel>100 m/s for Robot_Fs = 200 this correponds to 0.5
X(find(abs(diff(X))>(100/robot_Fs))) = NaN;  
Y(find(abs(diff(X))>(100/robot_Fs))) = NaN;
P(find(abs(diff(Y))>(100/robot_Fs))) = NaN;
X(find(abs(diff(Y))>(100/robot_Fs))) = NaN;
Y(find(abs(diff(Y))>(100/robot_Fs))) = NaN;


X = remove_short_nonnan_segments(X,20);   %Length of the shortest finite data segment is set to 10 but can be modified based on need.
Y = remove_short_nonnan_segments(Y,20);
P = remove_short_nonnan_segments(P,20);

X = X*1e3; %convert to mm temporarily.
Y = Y*1e3;

all_nan_elements_in_X = find(isnan(X));
forLocsbeginNans  = (diff(all_nan_elements_in_X) ~= 1);
beginLocsNans = all_nan_elements_in_X([1;find(forLocsbeginNans)+1]);
blink_parameters.beginLocsNans = beginLocsNans;

[X] = fill_saccade_fix(X,foveal_radius_vision,saccade_duration,initiate_saccade_time,robot_Fs);      %Fills the gaps due to blinks with a saccade and fixation.
[Y] = fill_saccade_fix(Y,foveal_radius_vision,saccade_duration,initiate_saccade_time,robot_Fs);

X = X*1e-3;
Y = Y*1e-3;

%% This section removes data in which gaze is outside the workspace - If gaze goes outside workspace, set it to NaN;
P(X > max(work_spaceX)) = NaN;
P(X < min(work_spaceX)) = NaN;
P(Y > max(work_spaceY)) = NaN;
P(Y < min(work_spaceY)) = NaN;

X(X > max(work_spaceX)) = NaN;    
X(X < min(work_spaceX)) = NaN;

Y(Y > max(work_spaceY)) = NaN;
Y(Y < min(work_spaceY)) = NaN;

Blink_Corrected_Gaze_X = X*1e-3;
Blink_Corrected_Gaze_Y = Y*1e-3;
Blink_Corrected_Pupil = P;


%%
data_non_filtered_gaze_and_blink_corrected = data_non_filtered;
data_non_filtered_gaze_and_blink_corrected.Gaze_X = Blink_Corrected_Gaze_X;
data_non_filtered_gaze_and_blink_corrected.Gaze_Y = Blink_Corrected_Gaze_Y;
data_non_filtered_gaze_and_blink_corrected.Gaze_PupilArea = Blink_Corrected_Pupil;
     
end




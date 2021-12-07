function data_out = resample_gaze_data(data_in, RobotFs)
%% Run code to resample Gaze data to Kinematic data 

% Initialize Variables
ts = data_in.Gaze_TimeStamp;
x  = data_in.Gaze_X;
y  = data_in.Gaze_Y;
p  = data_in.Gaze_PupilArea;

gaze_data = [ts x y p];
gaze_data_unique = unique(gaze_data,'rows');
length_gaze_data = length(gaze_data);

gaze_data_timestamps_new = (gaze_data_unique(1,1):(1/RobotFs):gaze_data_unique(1,1)+((1/RobotFs)*(length_gaze_data-1)))';

%There are a few assumptions involved here. Primarily, we assume that the
%first gaze data point and KINARM robot data point coincide. That will
%usually not be the case. They might be off by 0-4 ms for ROB and TMT
%tasks.

%Resample to sampling rate of robot data
gaze_data_x_new = interp1(gaze_data_unique(:,1),gaze_data_unique(:,2),gaze_data_timestamps_new,'linear','extrap');
gaze_data_y_new = interp1(gaze_data_unique(:,1),gaze_data_unique(:,3),gaze_data_timestamps_new,'linear','extrap');
gaze_data_p_new = interp1(gaze_data_unique(:,1),gaze_data_unique(:,4),gaze_data_timestamps_new,'linear','extrap');

data_out = data_in;
data_out.Gaze_TimeStamp = gaze_data_timestamps_new;
data_out.Gaze_X = gaze_data_x_new;
data_out.Gaze_Y = gaze_data_y_new;
data_out.Gaze_PupilArea  = gaze_data_p_new;
end
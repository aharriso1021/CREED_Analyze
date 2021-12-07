function this_gaze_data = CREED_GazeData(data, prm)
this_gaze_data.TrialTime = [1:1:length(data.Gaze_X)]/1000;
this_gaze_data.TrialEventsLabels = data.EVENTS.LABELS;
this_gaze_data.TrialEventsTimes = data.EVENTS.TIMES;
this_gaze_data.Gaze_X=data.Gaze_X*1e3;
this_gaze_data.Gaze_Y=data.Gaze_Y*1e3;
this_gaze_data.Gaze_XY = [data.Gaze_X data.Gaze_Y] * 1e3;
this_gaze_data.Gaze_TimeStamp=data.Gaze_TimeStamp;    %PLEASE DON'T MODIFY THE TIMESTAMPS.           

SGf = prm.SGolayF;
SGk = prm.SGolayK;
Robot_Fs = prm.roboFs;


Gaze_X_Velocity=derivative(this_gaze_data.Gaze_X)./derivative(this_gaze_data.Gaze_TimeStamp);
Gaze_Y_Velocity=derivative(this_gaze_data.Gaze_Y)./derivative(this_gaze_data.Gaze_TimeStamp);
this_gaze_data.Gaze_X_Vel = sgolayfilt(Gaze_X_Velocity,SGk,SGf); 
this_gaze_data.Gaze_Y_Vel = sgolayfilt(Gaze_Y_Velocity,SGk,SGf); 

this_gaze_data.Gaze_TimeStamp_Vel=derivative(this_gaze_data.Gaze_TimeStamp);

[Gaze_Ang_Vel_No_Filt, this_gaze_data.Gaze_Rad_Vel, this_gaze_data.Gaze_R] = carttospherical_velocity(this_gaze_data.Gaze_X,this_gaze_data.Gaze_Y,...
this_gaze_data.Gaze_X_Vel,this_gaze_data.Gaze_Y_Vel);
this_gaze_data.Gaze_Ang_Vel = sgolayfilt(Gaze_Ang_Vel_No_Filt,SGk,SGf);   %Applies a Savitzky-Golay Filter filter

this_gaze_data.Peak_Gaze_X_Vel=max(this_gaze_data.Gaze_X_Vel);
this_gaze_data.Peak_Gaze_Y_Vel=max(this_gaze_data.Gaze_Y_Vel);
this_gaze_data.Peak_Gaze_Ang_Vel=max(this_gaze_data.Gaze_Ang_Vel);

Gaze_Ang_Acc_No_Filt=derivative(this_gaze_data.Gaze_Ang_Vel)*Robot_Fs;
this_gaze_data.Gaze_Ang_Acc=sgolayfilt(Gaze_Ang_Acc_No_Filt,SGk,SGf);

%% Apply Pupil Filter
this_gaze_data.PupilSize = data.Gaze_PupilArea;
this_gaze_data.Blink = [];
this_gaze_data.Blink_Time = [];
end
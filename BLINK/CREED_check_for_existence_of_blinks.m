function gaze_kin=CREED_check_for_existence_of_blinks(file_info, data, gaze_kinematics, prm, i)
blink_parameters = prm.blink;

blink.x = find(gaze_kinematics.Gaze_X <= -99999);  %-99999 is chosen because eye tracking sets position data of blinks to -100 m (99999=100*1000-1 mm). 
blink.y = find(gaze_kinematics.Gaze_Y <= -99999);
    
if any(isnan(gaze_kinematics.Gaze_X)) || any(isnan(gaze_kinematics.Gaze_Y)) || max(gaze_kinematics.Gaze_Ang_Vel)>1.5e3    %The blinks are checked for peak velocity or leftover Nans from the autocorrections.  
        disp([file_info, ' Trial: ', num2str(i)]);
        ps_1 = gaze_kinematics.PupilSize;
        gX_old = gaze_kinematics.Gaze_X;
        gY_old = gaze_kinematics.Gaze_Y;
    try [gaze_kinematics.Gaze_X, gaze_kinematics.Gaze_Y, gaze_kinematics.blink]=CREED_blink_gui(gaze_kinematics.Gaze_X,gaze_kinematics.Gaze_Y, i,...
     prm.roboFs, blink_parameters); %% Has to be away to extract XCoord pairs from all corrextions
        accept = input('Accept gaze correction (0 = NO ; 1 = YES) ');
    catch
        accept = input('Accept gaze correction (0 = NO ; 1 = YES) '); 
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% Figure out how to remove points in the Pupil Size varianle that correspond to blinks      
    if accept == 1 & ~isnan(gaze_kinematics.blink) %This if statement will be executed if the blink correction is accepted. 
        gaze_diff = gaze_kinematics.Gaze_Y - gY_old;
        blink_idx = find(abs(gaze_diff) > 5);
        gaze_kinematics.blink_time=...
        (gaze_kinematics.Gaze_TimeStamp(gaze_kinematics.blink(2))-gaze_kinematics.Gaze_TimeStamp(gaze_kinematics.blink(1)))*1e3;  %Gives time in ms for the blink
  
        blink.temp=gaze_kinematics.blink;
        blink.time_temp=gaze_kinematics.blink_time;
  
        %Recompute the gaze velocity if there were blinks.
        data.Gaze_X=gaze_kinematics.Gaze_X*1e-3;  %Reassigns corrected gaze position data to data so it could be passed to the class gaze_data.
        data.Gaze_Y=gaze_kinematics.Gaze_Y*1e-3;
        gaze_kinematics=CREED_GazeData(data, prm);
            gaze_kinematics.Blink=blink.temp;
            gaze_kinematics.Blink_Time= blink.time_temp;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    
    else   %This elseif is executed if the blink correction is not executed. 
        gaze_kinematics.TrialTime = NaN;
        gaze_kinematics.TrialEventsLabels = NaN;
        gaze_kinematics.TrialEventsTimes = NaN;
        gaze_kinematics.Gaze_XY = NaN;
        gaze_kinematics.Gaze_TimeStamp=NaN;
        gaze_kinematics.Gaze_X_Vel=NaN;
        gaze_kinematics.Gaze_Y_Vel=NaN;
        gaze_kinematics.Gaze_TimeStamp_Vel=NaN;
        gaze_kinematics.Gaze_Rad_Vel = NaN;
        gaze_kinematics.Gaze_R = NaN;
        gaze_kinematics.Gaze_Ang_Vel=NaN;
        gaze_kinematics.Peak_Gaze_X_Vel = NaN;
        gaze_kinematics.Peak_Gaze_Y_Vel = NaN;
        gaze_kinematics.Peak_Gaze_Ang_Vel = NaN;
        gaze_kinematics.Gaze_Ang_Acc = NaN;
        gaze_kinematics.PupilSize = NaN;
        gaze_kinematics.Blink = NaN;
        gaze_kinematics.Blink_Time = NaN;
            gaze_kinematics = rmfield(gaze_kinematics, 'blink'); 
    end
   
end
 
gaze_kin=gaze_kinematics;
 
end
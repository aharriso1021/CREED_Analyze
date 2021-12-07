function [pupil_dyn] = calcAPSTPupil(gaze_data, trial_info, trial_dyn, miss_thr, dev_thr)
pupil_dyn = struct('TrialCondition', {}, 'TrialAcc', [], 'ZPupilData', [], 'LatTargIdx', [], 'MaxConsIdx', [],...
    'MaxConst', [], 'ConstRate', [], 'TEPD', [], 'DilRate', []);
pupil_dyn = repmat(pupil_dyn, [length(gaze_data) 1]);
%%
close all;
set(0,'DefaultFigureWindowStyle', 'docked');
for ti = 1:length(trial_info)
pupil_dyn(ti).TrialCondition = trial_dyn(ti).Trial_Condition;
pupil_dyn(ti).TrialAcc = trial_dyn(ti).Trial_Accuracy;
%
if isnan(trial_dyn(ti).Trial_Accuracy) || trial_dyn(ti).SRT <=100
    trial_valid = 0;
else
    trial_valid = 1;
end
if trial_valid == 1
%%
fix_idx    = trial_info(ti).eye_on_fix_idx(end);
sacc_idx   = trial_info(ti).sacc_idx;
latt_idx   = trial_info(ti).lat_targ_idx;
%
pupil_dat  = gaze_data(ti).Gaze_PupilArea;
gazex_dat  = gaze_data(ti).Gaze_X;
blink_inf  = gaze_data(ti).blink_parameters;
%% Multiple Loss/Lock on CFT
if length(fix_idx) > 1 
    figure;
    subplot 211
    plot(pupil_dat,'k-'); a = gca;
    title('Accept Trial? [Y(1) / N(0)]');
    hold on
        for k = 1:length(fix_idx)
            plot([fix_idx(k) fix_idx(k)], [a.YLim(1) a.YLim(2)], 'r--');
        end
    subplot 212
    plot(pupil_dat(fix_idx(end):latt_idx+90),'k-');
    hold on
        periT = latt_idx - fix_idx(end); a = gca;
        plot([periT periT], [a.YLim(1) a.YLim(2)], 'r--');
    trial_valid = input('Accept Trial? [Y(1) / N(0)] ');
    close;
end
 
if trial_valid == 1
    fix_period = fix_idx(end):1:latt_idx+90; 
        fix_pupil = pupil_dat(fix_period);
            pupilZ = fix_pupil - mean(fix_pupil(1:100));
        fix_gazex = gazex_dat(fix_period);
            gazexZ = fix_gazex - mean(fix_gazex(1:10));
        fix_blink = blink_inf.blink_logi(fix_period);
            pti = latt_idx - fix_idx(end);
            sci = sacc_idx - fix_idx(end);
            [~,mci] = min(pupilZ(200:pti));
                mci = mci + 200;
%% Blink & Gaze Deviation Check
    if ~isempty(find(abs(gazexZ(1:pti)) > dev_thr)) ||  sum(fix_blink)/length(fix_period) >= miss_thr
        trial_valid = 0;
    end
%% 
    if pupilZ(mci) >= pupilZ(200)
        trial_valid = 0;
    elseif mci - 150 <= 250
        trial_valid = 0;
    elseif pti - mci < 10
        trial_valid = 0;
    end
    
if trial_valid == 1
    
%% Final Visual Inspection    
if ismember(trial_dyn(ti).Trial_Condition, 'PRO')
    ln = 'b-';
else
    ln = 'r-';
end
plot(pupilZ, ln, 'LineWidth', 1.5); a = gca;
hold on
plot([pti pti], [a.YLim(1) a.YLim(2)], 'k--');
plot(200, pupilZ(200), 'go', 'MarkerFaceColor', 'g');
plot(mci, pupilZ(mci), 'mo', 'MarkerFaceColor', 'm');
    title(['Not Auto Reject - Accept Trial ' num2str(ti)]);
trial_valid = input('1 = Yes / 0 = No ');
close;
end

end
    
if trial_valid == 1
    pupil_dyn(ti).ZPupilData = pupilZ;
    pupil_dyn(ti).LatTargIdx = pti;
    pupil_dyn(ti).MaxConsIdx = mci;
    pupil_dyn(ti).MaxConst = pupilZ(mci);
    pupil_dyn(ti).ConstRate = (pupilZ(mci) - pupilZ(150)) / (mci - 150);
    pupil_dyn(ti).TEPD = pupilZ(pti) - pupilZ(mci);
    pupil_dyn(ti).DilRate = pupil_dyn(ti).TEPD / (pti - mci);
else

    if ~exist('pupilZ', 'var')
        fix_period = fix_idx(end):1:latt_idx+90; 
            fix_pupil = pupil_dat(fix_period);
            pupilZ = fix_pupil - mean(fix_pupil(1:100));
    end
    pupil_dyn(ti).ZPupilData = pupilZ;
    pupil_dyn(ti).LatTargIdx = NaN;
    pupil_dyn(ti).MaxConsIdx = NaN;
    pupil_dyn(ti).MaxConst = NaN;
    pupil_dyn(ti).ConstRate = NaN;
    pupil_dyn(ti).TEPD = NaN;
    pupil_dyn(ti).DilRate = NaN;
end

else
    pupil_dyn(ti).ZPupilData = NaN;
    pupil_dyn(ti).LatTargIdx = NaN;
    pupil_dyn(ti).MaxConsIdx = NaN;
    pupil_dyn(ti).MaxConst = NaN;
    pupil_dyn(ti).ConstRate = NaN;
    pupil_dyn(ti).TEPD = NaN;
    pupil_dyn(ti).DilRate = NaN;
    
end % END Valid Trial Proc
end % END Trial LOOP 

% for xi = 1:length(pupil_dyn)
% if ~isempty(pupil_dyn(xi).PupilRespZ)
%     pdat = pupil_dyn(xi).PupilRespZ;
%     plot(pdat,'k-');
%     keyboard;
%     cla
% end

end
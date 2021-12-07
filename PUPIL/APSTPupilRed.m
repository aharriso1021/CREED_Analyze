function [pupil_dyn] = APSTPupilRed(gaze_data, trial_info, trial_dyn, miss_thr, dev_thr)
pupil_dyn = struct('TrialN', [], 'TrialCondition', {}, 'TrialValid', [], 'TrialAcc', [], 'ZPupilData', [], 'LatTargIdx', [], 'MaxConsIdx', [],...
    'MaxConstAmp', [], 'TEPD', []);
%% Trim Data 2 Fixation Period
trial_pupil = struct('TrialN', [], 'Condition', {}, 'ACC', [], 'ValidTrial', [], 'pDat_fpz', [], 'ltI', [], 'maxCI', []);
trial_pupil = repmat(trial_pupil, [length(gaze_data) 1]);
for trialI = 1:length(gaze_data)
    trial_pupil(trialI).TrialN = trialI;
    trial_pupil(trialI).Condition = trial_dyn(trialI).Trial_Condition;
if ~isnan(trial_dyn(trialI).Trial_Accuracy)
    trial_pupil(trialI).ACC = trial_dyn(trialI).Trial_Accuracy;
    %
    pDat   = gaze_data(trialI).Gaze_PupilArea * 1e5;
    xDat   = gaze_data(trialI).Gaze_X;
    blinks = gaze_data(trialI).blink_parameters.blink_logi;
        fix_init = trial_info(trialI).eye_on_fix_idx(end);
        fix_end  = trial_info(trialI).lat_targ_idx;
        % 
        pDat_fp = pDat(fix_init:fix_end+100);
            pDat_fpz = pDat_fp - mean(pDat_fp(1:100));
        xDat_fp = xDat(fix_init:fix_end);
            xDat_fpz = xDat_fp - mean(xDat_fp(1:100));
        blinks_fp = blinks(fix_init:fix_end+100);
    if sum(blinks_fp) / length(blinks_fp) >= miss_thr % Too much missing data during fix period
        trial_pupil(trialI).ACC = NaN;
        trial_pupil(trialI).pDat_fp = nan([length(pDat_fp), 1]);
        trial_pupil(trialI).ValidTrial = NaN;
    elseif ~isempty(find(abs(xDat_fpz) >= dev_thr,1))    % Eye movement during fix period
        trial_pupil(trialI).ACC = NaN;
        trial_pupil(trialI).pDat_fpz = nan([length(pDat_fp), 1]);
        trial_pupil(trialI).ValidTrial = NaN;
    else
        trial_pupil(trialI).pDat_fpz = pDat_fpz;
        trial_pupil(trialI).ltI = fix_end;
            [~, maxCI] = min(pDat_fpz(400:end-100));
        trial_pupil(trialI).maxCI = maxCI+400;
        trial_pupil(trialI).ValidTrial = 1;
    end
    
else % NEED TO NAN pDat_FP & ACC
    trial_pupil(trialI).ACC = NaN;
    trial_pupil(trialI).pDat_fpz = nan([1111, 1]);
    trial_pupil(trialI).ValidTrial = NaN;
end % END Behavior NaN Chack
    
    
    
end % END Pupil Data Trim
%% Remove INVALID BEHAVIORAL TRIALS
trial_pupil = trial_pupil(~isnan([trial_pupil.ACC]));
pupil_dyn = repmat(pupil_dyn, [length(trial_pupil) 1]);

%% Trial Visualization
figure;
%
proIdx = ismember({trial_pupil.Condition}, {'PRO'});
antIdx = ~proIdx;
accIdx = [trial_pupil.ACC] == 1;
%
for tpI = 1:length(trial_pupil)
    acc = trial_pupil(tpI).ACC;
    cnd = {trial_pupil(tpI).Condition};
    
subplot 141
cla;
plot([trial_pupil(proIdx & accIdx).pDat_fpz], 'b--');
hold on
plot(nanmean([trial_pupil(proIdx & accIdx).pDat_fpz],2),'b-', 'LineWidth', 4);
title(['PCor nTrials: ' num2str(sum(~isnan([trial_pupil(proIdx & accIdx).ValidTrial])))])

subplot 142
cla;
plot([trial_pupil(antIdx & accIdx).pDat_fpz], 'r--');
hold on
plot(nanmean([trial_pupil(antIdx & accIdx).pDat_fpz],2),'r-', 'LineWidth', 4);
title(['ACor nTrials: ' num2str(sum(~isnan([trial_pupil(antIdx & accIdx).ValidTrial])))])

subplot 143
cla
plot([trial_pupil(proIdx & ~accIdx).pDat_fpz], 'k--');
hold on
plot(nanmean([trial_pupil(proIdx & ~accIdx).pDat_fpz],2),'b-', 'LineWidth', 4);
title(['PErr nTrials: ' num2str(sum(~isnan([trial_pupil(proIdx & ~accIdx).ValidTrial])))])

subplot 144
cla;
plot([trial_pupil(antIdx & ~accIdx).pDat_fpz], 'm--');
hold on
plot(nanmean([trial_pupil(antIdx & ~accIdx).pDat_fpz],2),'m-', 'LineWidth', 4);
title(['AErr nTrials: ' num2str(sum(~isnan([trial_pupil(antIdx & ~accIdx).ValidTrial])))])
%%

if ismember(cnd, 'PRO') && acc == 1
    subplot 141
    plot(trial_pupil(tpI).pDat_fpz, 'g-', 'LineWidth', 2)
    clc;
    disp(['Trial: ' num2str(tpI) '/' num2str(length(trial_pupil))]);
    trial_fate = input('Keep trial in set? [No (0) / Yes (1)] ');
elseif ismember(cnd, 'ANTI') && acc == 1
    subplot 142
    plot(trial_pupil(tpI).pDat_fpz, 'g-', 'LineWidth', 2)
    clc;
    disp(['Trial: ' num2str(tpI) '/' num2str(length(trial_pupil))]);
    trial_fate = input('Keep trial in set? [No (0) / Yes (1)] ');
elseif ismember(cnd, 'PRO') && acc == -1
    subplot 143
    plot(trial_pupil(tpI).pDat_fpz, 'g-', 'LineWidth', 2)
    clc;
    disp(['Trial: ' num2str(tpI) '/' num2str(length(trial_pupil))]);
    trial_fate = input('Keep trial in set? [No (0) / Yes (1)] ');
elseif ismember(cnd, 'ANTI') && acc == -1
    subplot 144
    plot(trial_pupil(tpI).pDat_fpz, 'g-', 'LineWidth', 2)
    clc;
    disp(['Trial: ' num2str(tpI) '/' num2str(length(trial_pupil))]);
    trial_fate = input('Keep trial in set? [No (0) / Yes (1)] ');

end

if trial_fate == 0
trial_pupil(tpI).pDat_fpz = nan([length(trial_pupil(tpI).pDat_fpz), 1]);
trial_pupil(tpI).ValidTrial = NaN;
    pupil_dyn(tpI).TrialN = trial_pupil(tpI).TrialN;
    pupil_dyn(tpI).TrialCondition = trial_pupil(tpI).Condition;
    pupil_dyn(tpI).ValidTrial = NaN;
    pupil_dyn(tpI).TrialAcc = trial_pupil(tpI).ACC;
    pupil_dyn(tpI).ZPupilData = trial_pupil(tpI).pDat_fpz;
    pupil_dyn(tpI).LatTargIdx = NaN;
    pupil_dyn(tpI).MaxConsIdx = NaN;
    pupil_dyn(tpI).MaxConstAmp = NaN;
    pupil_dyn(tpI).TEPD = NaN;

else
    pupil_dyn(tpI).ZPupilData = trial_pupil(tpI).pDat_fpz;
    pupil_dyn(tpI).TrialN = trial_pupil(tpI).TrialN;
    pupil_dyn(tpI).TrialCondition = trial_pupil(tpI).Condition;
    pupil_dyn(tpI).ValidTrial = 1;
    pupil_dyn(tpI).TrialAcc = trial_pupil(tpI).ACC;    
        lat_targI = length(trial_pupil(tpI).pDat_fpz)-100;
    pupil_dyn(tpI).LatTargIdx = lat_targI;
    pupil_dyn(tpI).MaxConsIdx = trial_pupil(tpI).maxCI;
        MaxConstAmp = trial_pupil(tpI).pDat_fpz(trial_pupil(tpI).maxCI);
    pupil_dyn(tpI).MaxConstAmp = MaxConstAmp;
        tepd = trial_pupil(tpI).pDat_fpz(lat_targI) - MaxConstAmp;
    pupil_dyn(tpI).TEPD = tepd;
end    


end % END Visualization

end % END Function
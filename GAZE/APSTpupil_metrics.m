function APSTpupil_metrics
clc; clear;
%%
gze_prc_dir = 'D:\PROJECTS\CREED\DATA\CREED_ParticipantData\GAZE\2.APST.prc\';
cd(gze_prc_dir);
%%
files = dir('*.mat');
subj_files = {files.name};
    APST_trialparameters(1).blink_parameters = [];
    APST_trialparameters(1).PupilArea = [];
    APST_trialparameters(1).PupilArea_2xbc = [];
    APST_trialparameters(1).TargOn_idx = [];
    APST_trialparameters(1).GapOn_idx = [];
    APST_trialparameters(1).Sacc_idx = [];

for i = 1:length(subj_files)
    subj = subj_files{i};
    load(subj);
    subj_pupil_data = struct();
     
    for j = 1:length(APST_trialparameters)
        if ~isnan(APST_trialparameters(j).Trial_Accuracy)
            pupil = gaze_kinData(j).Gaze_PupilArea;
            %
            blink_info = gaze_kinData(j).blink_parameters;
            trial_idx = APST_trialdynamics(j);
                ct = trial_idx.fix_targ_idx(1);
                pt = trial_idx.lat_targ_idx;
                sx = trial_idx.sacc_idx;
            pupil_trim = pupil(ct:end);
            pupil_area = mean(pupil_trim(100:300)) - pupil_trim;
            pupil_area2 = mean(pupil_area(800:850)) - pupil_area;
            %%
            if blink_info.nBlinks < 1 || ~any(blink_info.blink_logi(ct:pt))
                    APST_trialparameters(j).PupilArea = pupil_area;
                    APST_trialparameters(j).PupilArea_2xbc = pupil_area2;
                    APST_trialparameters(j).TargOn_idx = pt - ct;
                    APST_trialparameters(j).GapOn_idx = APST_trialparameters(j).TargOn_idx - 200;
                    APST_trialparameters(j).Sacc_idx = sx - ct;
            else
                    APST_trialparameters(j).blink_parameters = blink_info;
                    APST_trialparameters(j).PupilArea = pupil_area;
                    APST_trialparameters(j).PupilArea_2xbc = pupil_area2;
                    APST_trialparameters(j).TargOn_idx = pt - ct;
                    APST_trialparameters(j).GapOn_idx = APST_trialparameters(j).TargOn_idx - 200;
                    APST_trialparameters(j).Sacc_idx = sx - ct;
               
            end
        else
            APST_trialparameters(j).PupilArea = NaN;
                    APST_trialparameters(j).PupilArea_2xbc = NaN;
                    APST_trialparameters(j).TargOn_idx = NaN;
                    APST_trialparameters(j).GapOn_idx = NaN;
                    APST_trialparameters(j).Sacc_idx = NaN;
        end
           
    end % trial loop
end % subj loop
    save(subj, 'APST_trialdynamics', 'APST_trialparameters', 'gaze_kinData')
end % func end

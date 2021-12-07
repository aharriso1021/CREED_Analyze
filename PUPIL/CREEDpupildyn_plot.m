parent_dir =  '/Volumes/HARRISONext/DATA/CREED_ParticipantData/GAZE/3.APST.ppl';
proc_out_dir = '/Volumes/HARRISONext/DATA/CREED_ParticipantData/GAZE/4.APST.ppt';
    addpath(genpath(parent_dir)); addpath(genpath(proc_out_dir));
cd(parent_dir)
files = dir('*.mat');
dat_check = zeros(length(files),1);
for i = 1:length(files)
cd(parent_dir)
subj_id = files(i).name(1:9);
if ~exist([subj_id '_APSTppt.mat'],'file')
    load(files(i).name);
    if ~isfield(APST_pupildynamics, 'TrialN')
        count = 0;
        for j = 1:length(APST_pupildynamics)
            APST_pupildynamics(j).TrialN = j;
        end
    end
        aIdx = isnan([APST_pupildynamics.TrialAcc]); % NaN Trials from Behavioral Processing 
        pIdx = isnan([APST_pupildynamics.LatTargIdx]); % NaN Trials from Pupil Processing
        try
            trials = any([aIdx' pIdx'],2);
        catch
            keyboard;
        end
    pupil_dat = APST_pupildynamics(~trials);
    %% 
        pIdx = ismember({pupil_dat.TrialCondition}, 'PRO'); % REF = PRO TRIALS
        acIdx = [pupil_dat.TrialAcc] == 1;
proC_dat = pupil_dat(pIdx & acIdx);
antC_dat = pupil_dat(~pIdx & acIdx);
antE_dat = pupil_dat(~pIdx & ~acIdx);

figure;
%% PLOTS 
% Correct PRO Trials
accept_plot = 0;
dat0 = proC_dat;
while accept_plot == 0
hT = plot([proC_dat.ZPupilData], 'b--');
hold on
hM = plot(nanmean([proC_dat.ZPupilData],2), 'b-', 'LineWidth', 4);
%
rm_line = input('Would you like to remove outlier? [0 / 1] ');
rmlines = [];    
    if rm_line == 1
        set(hT, 'ButtonDownFcn', {@bClick, hT}, 'UserData', []);
        keyboard;
            yD = zeros([length(hT) 1]);
            for k = 1:length(hT)
                yD(k) = ~isempty(hT(k).UserData);
            end
            xI = logical(yD);
                datlen = length(proC_dat(xI).ZPupilData);
                proC_dat(xI).ZPupilData = nan([datlen 1]);
            rmlines = [rmlines ; find(xI)];
    else
        accept_plot = 1;
    end
cla;
end


% Correct ANTI Trials
accept_plot = 0;
dat0 = antC_dat;
while accept_plot == 0
hT = plot([antC_dat.ZPupilData], 'r--');
hold on
hM = plot(nanmean([antC_dat.ZPupilData],2), 'r-', 'LineWidth', 4);
% title([subj_id ' PC Trials: ' num2str(size([~isnan(proC_dat.LatTargIdx)],2))]);
rm_line = input('Would you like to remove outlier? [0 / 1] ');
    if rm_line == 1
    rmlines = []; 
        set(hT, 'ButtonDownFcn', {@bClick, hT}, 'UserData', []);
        keyboard;
            yD = zeros([length(hT) 1]);
            for k = 1:length(hT)
                yD(k) = ~isempty(hT(k).UserData);
            end
            xI = logical(yD);
                datlen = length(antC_dat(xI).ZPupilData);
                antC_dat(xI).ZPupilData = nan([datlen 1]);
            rmlines = [rmlines ; find(xI)];
    else
        accept_plot = 1;
    end
cla;
end

% Error Anti Trials
accept_plot = 0;
dat0 = antE_dat;
while accept_plot == 0
hT = plot([antE_dat.ZPupilData], 'g--');
hold on
hM = plot(nanmean([antE_dat.ZPupilData],2), 'g-', 'LineWidth', 4);
% title([subj_id ' PC Trials: ' num2str(size([~isnan(proC_dat.LatTargIdx)],2))]);
rm_line = input('Would you like to remove outlier? [0 / 1] ');
    if rm_line == 1
    rmlines = []; 
        set(hT, 'ButtonDownFcn', {@bClick, hT}, 'UserData', []);
        keyboard;
            yD = zeros([length(hT) 1]);
            for k = 1:length(hT)
                yD(k) = ~isempty(hT(k).UserData);
            end
            xI = logical(yD);
                datlen = length(antE_dat(xI).ZPupilData);
                antE_dat(xI).ZPupilData = nan([datlen 1]);
            rmlines = [rmlines ; find(xI)];
    else
        accept_plot = 1;
    end
cla;
end
APST_pupildyn_trim = [proC_dat, antC_dat, antE_dat];
[~, sortI] = sort([APST_pupildyn_trim.TrialN]);
APST_pupildyn_trim = APST_pupildyn_trim(sortI);
%%
cd(proc_out_dir)
save([subj_id '_APSTppt.mat'], 'clean_data', 'gaze_kinData', 'APST_trialparameters', 'APST_trialdynamics', 'APST_pupildynamics', 'APST_pupildyn_trim')    
close;
end
end

function bClick(hline, ~, h)
disp(find(h == hline));
yd = get(hline, 'Ydata');
set(hline, 'UserData', yd);
end
function CREED_TrialXTrial_inspect
clear; clc; close all;
if ispc
    drvr = input('PC Driver: [Ex D:] ', 's'); clc;
    eeg_dir = [drvr '\DATA\CREED_ParticipantData\EEG\'];
    eeglab_dir = [drvr '\MATLAB\eeglab'];
elseif isunix
    eeg_dir =  '/Volumes/HARRISON_TB/DATA/CREED_ParticipantData/EEG/';
    eeglab_dir = '/Volumes/HARRISON_TB/MATLAB/eeglab/';
end
    addpath(genpath(eeg_dir)); addpath(eeglab_dir);
    eeglab; clc;
cd(eeg_dir)
    if ~exist('6.TXTclean.erp', 'dir')
        mkdir '6.TXTclean.erp';
    end  
    variant = input('Indicate variant to process: [Button | Reach | Cont] ', 's');
        variant_fldr = [upper(variant) '_bin.mat']; clc;
    plot_mode = input('Choose Plot Mode - WHOLEHEAD or HOTSPOT: ', 's');
        clc;
%% 
plot_chans = {
            'blank' 'blank' 'F5' 'FC5' 'C5' 'CP5' 'blank';...
            'blank' 'AF3'   'F3' 'FC3' 'C3' 'CP3' 'blank';...
            'Fp1'   'blank' 'F1' 'FC1' 'C1' 'CP1' 'P2';... 
            'blank' 'AFz'   'Fz' 'FCz' 'Cz' 'CPz' 'Pz';...        
            'Fp2'   'blank' 'F2' 'FC2' 'C2' 'CP2' 'P2';... 
            'blank' 'AF4'   'F4' 'FC4' 'C4' 'CP4' 'blank';...
            'blank' 'blank' 'F6' 'FC6' 'C6' 'CP6' 'blank';...
              };

erp_set = input('Choose ERP [resp-lock -or- stim-lock]: ', 's'); % 'stim-lock';
    erp_set = lower(erp_set); clc;
% set(0, 'DefaultFigureWindowStyle', 'docked');
figure;

cd([eeg_dir '5.BIN.erp' filesep variant_fldr])
fldr = dir('*bin.mat');
subj_files = char({fldr.name});

count = 0;

for subji = 1:size(subj_files,1)
if ~exist([subj_files(subji,1:14) '_txtc.set'], 'file')
cd([eeg_dir '5.BIN.erp' filesep variant_fldr])
    load(subj_files(subji,:));
    EEG = ALLEEG(ismember({ALLEEG.session}, erp_set));
        xi = ~ismember(plot_chans, {EEG.chanlocs.labels});
        plot_chans(xi) = {'blank'};
        chans_list = reshape(plot_chans, [],1);
    % EEG = pop_eegfiltnew(EEG, 'hicutoff',11);
    
%% MANUAL TRIAL INSPECTION
compl = 0; % Initialize visualizaiton complete index (0 = no & repeat)
while compl == 0
    if strcmpi(plot_mode, 'WHOLEHEAD')
        [EEG] = vis_inspection_wh(EEG, subj_files, subji, erp_set, plot_chans, chans_list, count); 
    elseif strcmpi(plot_mode, 'HOTSPOT')
        plot_grps = {'FRONTAL' 'FRONTO-CENTRAL' 'CENTRAL' 'CENTRO-PARIETAL'};
        grp_list{1} = {'F1' 'Fz' 'F2' }; % 'FC1' 'FCz' 'FC2'
        grp_list{2} = {'FC1' 'FCz' 'FC2' }; % 'C1' 'Cz' 'C2'
        grp_list{3} = {'C1' 'Cz' 'C2' }; % 'CP1' 'CPz' 'CP2'
        grp_list{4} = {'CP1' 'CPz' 'CP2' 'Pz'};
        [EEG] = vis_inspection_hs(EEG, subj_files, subji, erp_set, plot_grps, grp_list, count);
    else
        error('Unknown Plot Mode');
    end
    compl = input('End of Manual Trial Visualization - save and continue? [NO (0) / YES (1)]');
clf; clc;
end
    
%% Remove REJECTED CHANNELS
EEG = simplesyncartifacts(EEG, 'Direction', 'bidirectional');
EEG = pop_rejepoch(EEG, EEG.reject.rejmanual, 0);
clc;
cd([eeg_dir '6.TXTclean.erp'])
if ~exist([upper(variant) '-' erp_set '_txtc.set'], 'dir')
    mkdir([upper(variant) '-' erp_set '_txtc.set']);
end

cd([upper(variant) '-' erp_set '_txtc.set'])
pop_saveset(EEG, [subj_files(subji,1:14) '_txtc.set']);

end % END CHECK EXIST
end % END SUBJ LOOP

    
end % END FUNC

function [EEG] = vis_inspection_wh(EEG, subj_files, subji, erp_set, plot_chans, chans_list, count)
Fs = 1/EEG.srate;
% chanIdx = find(ismember({EEG.chanlocs.labels}, plot_chans));
    eeg_data = EEG.data;
    eeg_data_hold = EEG.data; 
    lat = [EEG.xmin:Fs:EEG.xmax]*1000;
    EEG.TXTrejTrial = [];
triali = 1;
while triali <= EEG.trials
%         plot_dim = (100*()) + (10*(size(plot_chans,2)));
        %%
    for chani = 1:length(chans_list)
    if ~ismember(chans_list(chani), 'blank')
    subplot(size(plot_chans,2), size(plot_chans,1), chani)
    hold on
        chan_data = squeeze(eeg_data(ismember({EEG.chanlocs.labels}, plot_chans(chani)),:,:));

    yyaxis left;
    h{1} = plot(lat, chan_data(:,triali), 'b-', 'LineWidth', 0.5);
        a = gca;
        a.YDir = 'reverse';
    yyaxis right
    h{2} = plot(lat, nanmean([chan_data],2), 'r-', 'LineWidth', 1.5);
        title(plot_chans(chani))
        a = gca;
        a.YLim = [-8 8];
        a.YDir = 'reverse';
        a.XLim = [-200 1000];
        a.XTick = -200:200:1000;
    h{3} = plot([a.XLim(1) a.XLim(2)], [0 0], 'k-');
    h{4} = plot([0 0], [a.YLim(1) a.YLim(2)], 'k-');
    else
    end % END CHAN LABEL CHECK
    end % END CHANNEL PLOT LOOP
    %%
    sgtitle([EEG.condition '-' erp_set]);
    fprintf('%s\nTrial: %s\nGood Trials: %s\n',...
        subj_files(subji,1:14),...
        strcat(string(triali), '/', string(EEG.trials)),...
        string(sum(~isnan(squeeze(eeg_data(1,1,:))))));
    user_input = input('[A] = Previous Trial \n[D] = Advance Trial \n[S] = Remove Trial \n[W] = Start Over \nSelect an Action: ', 's');
    clc;
    if strcmpi(user_input, 'S')
    count = count + 1;
    %% REMOVE TRIAL == REPLACE WITH NANS %% 
        [ch,lt,~]=size(eeg_data);
        trialX = nan([ch lt]);
        EEG.TXTrejTrial.rejData{count} = squeeze(eeg_data(:,:,triali));
        EEG.TXTrejTrial.rejTrialIdx(count) = triali; 
        eeg_data(:,:,triali) = trialX;
        EEG.reject.rejmanual(triali) = 1;
    triali = triali + 1; % proceed to next trial
    elseif strcmpi(user_input, 'D')
    %% Keep Trial and move on to the next
    triali = triali + 1;
    elseif strcmpi(user_input, 'A')
    %% GO BACK - restore previous data 
    if triali > 1
    eeg_data(:,:,triali-1) = eeg_data_hold(:,:,triali-1);    
    triali = triali - 1; % reset trial counter
    if ~isempty(EEG.TXTrejTrial) && triali == EEG.TXTrejTrial.rejTrialIdx(count) % Reset counter & REJ info if needed 
        EEG.TXTrejTrial.rejData{1} = [];
        EEG.TXTrejTrial.rejTrialIdx(1) = [];
        EEG.reject.rejmanual(triali) = 0;
        count = count - 1;
    end
    else
    end
    elseif strcmpi(user_input, 'W')
    %% Reset and start over at Trial 1
    eeg_data = EEG.data;
    triali = 1;
    % Reset Rejection Parameters
    EEG.TXTrejTrial = [];
    EEG.reject.rejmanual(:) = 0;
    end
clf;
end % END TRIAL LOOP
    
end % END txt FUNC

function [EEG] = vis_inspection_hs(EEG, subj_files, subji, erp_set, plot_grps, grp_list, count)
Fs = 1/EEG.srate;
% chanIdx = find(ismember({EEG.chanlocs.labels}, plot_chans));
    eeg_data = EEG.data;
    eeg_data_hold = EEG.data; 
    lat = [EEG.xmin:Fs:EEG.xmax]*1000;
    EEG.TXTrejTrial = [];
triali = 1;

while triali <= EEG.trials
for grpi = 1:length(plot_grps)
    subplot(length(plot_grps), 1, grpi)
    hold on
        grp_data = squeeze(mean(eeg_data(ismember({EEG.chanlocs.labels}, grp_list{grpi}),:,:),1));
    %
    yyaxis left;
    h{1} = plot(lat, grp_data(:,triali), 'b-', 'LineWidth', 0.5);
        a = gca;
        a.YDir = 'reverse';
    yyaxis right
    h{2} = plot(lat, nanmean([grp_data],2), 'r-', 'LineWidth', 1.5);
        title(plot_grps(grpi))
        a = gca;
        a.YLim = [-8 8];
        a.YDir = 'reverse';
        a.XLim = [-200 1000];
        a.XTick = -200:200:1000;
    h{3} = plot([a.XLim(1) a.XLim(2)], [0 0], 'k-');
    h{4} = plot([0 0], [a.YLim(1) a.YLim(2)], 'k-');
    if ismember(string(erp_set), 'resp-lock')
        if ismember(plot_grps(grpi), {'FRONTAL' 'FRONTO-CENTRAL' 'CENTRAL'})
            h{5} = patch([0 180 180 0], [-8 -8 8 8], 'k');
        end
            h{5}.FaceAlpha = 0.20;
        if ismember(plot_grps(grpi), {'CENTRAL' 'CENTRO-PARIETAL'})
            h{5} = patch([300 600 600 300], [-8 -8 8 8], 'k');
        end
            h{5}.FaceAlpha = 0.20;
    elseif ismember(string(erp_set), 'stim_lock')
        %% NEED TO PATCH STIMULUS LOCKED ERP components %% 
    end
end % END CHANNEL PLOT LOOP

    %%
    sgtitle([EEG.condition '-' erp_set]);
    fprintf('%s\nTrial: %s\nGood Trials: %s\n',...
        subj_files(subji,1:14),...
        strcat(string(triali), '/', string(EEG.trials)),...
        string(sum(~isnan(squeeze(eeg_data(1,1,:))))));
    user_input = input('[A] = Previous Trial \n[D] = Advance Trial \n[S] = Remove Trial \n[W] = Start Over \nSelect an Action: ', 's');
    clc;
    %
    if strcmpi(user_input, 'S')
    count = count + 1;
    %% REMOVE TRIAL == REPLACE WITH NANS %% 
        [ch,lt,~]=size(eeg_data);
        trialX = nan([ch lt]);
        EEG.TXTrejTrial.rejData{count} = squeeze(eeg_data(:,:,triali));
        EEG.TXTrejTrial.rejTrialIdx(count) = triali; 
        eeg_data(:,:,triali) = trialX;
        EEG.reject.rejmanual(triali) = 1;
    triali = triali + 1; % proceed to next trial
    elseif strcmpi(user_input, 'D')
    %% Keep Trial and move on to the next
    triali = triali + 1;
    elseif strcmpi(user_input, 'A')
    %% GO BACK - restore previous data 
    if triali > 1
    eeg_data(:,:,triali-1) = eeg_data_hold(:,:,triali-1);    
    triali = triali - 1; % reset trial counter
    if ~isempty(EEG.TXTrejTrial) && triali == EEG.TXTrejTrial.rejTrialIdx(count) % Reset counter & REJ info if needed 
        EEG.TXTrejTrial.rejData{1} = [];
        EEG.TXTrejTrial.rejTrialIdx(1) = [];
        EEG.reject.rejmanual(triali) = 0;
        count = count - 1;
    end
    else
    end
    elseif strcmpi(user_input, 'W')
    %% Reset and start over at Trial 1
    eeg_data = EEG.data;
    triali = 1;
    % Reset Rejection Parameters
    EEG.TXTrejTrial = [];
    EEG.reject.rejmanual(:) = 0;
    end
if triali <= EEG.trials    
clf;
end
end% TRIAL LOOP
end
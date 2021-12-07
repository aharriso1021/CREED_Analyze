function CREED_GenerateERPs(prm)
clc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Not Quite Ready for CR Task or APST = NEED to bypass merging sets                      %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath(genpath(prm.matlabdir));addpath(genpath(prm.datadirEEG));addpath(prm.eeglabdir);

%%------------------------------------------------------------------------------------------ 
% Initialize eeglab
try
[ALLEEG, EEG, CURRENTSET, ALLCOM] =  eeglab;
catch 
eeglabdir = fileparts(which('eeglab.m'));
addpath(eeglabdir);
[ALLEEG, EEG, CURRENTSET, ALLCOM] =  eeglab;
end
close; 
%%------------------------------------------------------------------------------------------ 
clc;
task_var = input('Which task would you like to process? [BUTTON, REACH, CR, APST]: ', 's');
if strcmpi(task_var, 'BUTTON')
    file_names = {'BUTTON_clean.set'};
    tasks = {'GNGB' 'NGGB'};
    task_var = 'BUTTON';
elseif strcmpi(task_var, 'REACH')
    file_names = {'REACH_clean.set'};
    tasks = {'GNGR' 'NGGR'};
    task_var = 'REACH';
elseif strcmpi(task_var, 'CR')
    file_names = {'CONTR_clean.set'};
    tasks = {'GNGC01' 'NGGC01'};
    task_var = 'CONTR';
elseif strcmpi(task_var, 'APST')
    file_names = 'APST_clean.set';
    tasks = {'APST01'};
    task_var = 'APST';
else
    error('Unsupported task variant');
end % End 

%------------------------------------------------------------------------------------------ 
% Select REF SCHEME 
clc; 
if isempty(prm.ref_select)
    rSelect = input('Select Reference scheme to process: \n 1: Task AVG \n 2: Resting AVG \n 3: INF \n 4: CSD \n'); 
else
    rSelect = prm.ref_select; 
end
 
%% Directory Check                          
directory_check(prm);

%% 
cd(string(fullfile(prm.datadirEEG, '4.CLEAN.set',file_names)))
subjfiles = dir('*.set');
subjfile_names = char({subjfiles.name});
    participant_ids = str2num(subjfile_names(:,6:9)); % Full list of participant IDs in directory
    unique_ids = unique(participant_ids); % Subset of ONLY unique IDs 
for partI = 1:length(unique_ids)
curr_participant = unique_ids(partI);
part_files_idxs = find(participant_ids == unique_ids(partI));
ALLERP = [];
%%------------------------------------------------------------------------------------------ 
for vari = 1:length(tasks)
if ~exist([subjfile_names(part_files_idxs(1),1:10) tasks{vari} prm.fieldhandle{1}],'file')

% MERGE CLEANSETS == ONLY for REACH & BUTTON
cd(string(fullfile(prm.datadirEEG, '4.CLEAN.set',file_names)))
    ALLEEG = []; % Sanity check 
    ALLPRF = [];
    if ~ismember({task_var}, {'CONTR','APST'})
        variant_idx = find(ismember(subjfile_names(part_files_idxs,11:14),tasks(vari)));
        for k = 1:length(variant_idx)
            EEG = pop_loadset(subjfile_names(part_files_idxs(variant_idx(k)),:));
            
                if rSelect == 1 % TASK AVG
                    EEG = EEG;
                    
                elseif rSelect == 2 % RESTING 1 AVG
                    rf_idx = find(ismember({EEG.chanlocs.labels}, 'xRRef1'));
                    chX_idx = find(ismember({EEG.chanlocs.labels}, {'xRRef2', 'xRRef3'}));
                    EEG = pop_reref(EEG, rf_idx, 'exclude', [chX_idx]);
                        EEG.ref = 'RESTING';
                    
                elseif rSelect == 3 % INF (REST) Ref
                    chX_idx = ismember({EEG.chanlocs.labels}, {'xRRef1', 'xRRef2', 'xRRef3'});
                    EEG.chanlocs(chX_idx) = [];
                    EEG.nbchan = EEG.nbchan - sum(chX_idx);
                    %
                    EEG.data = EEG.infref;
                        [EEG.chanlocs.ref] = deal("INF");
                        EEG.ref = "INF";
                        
                elseif rSelect == 4 % CSD
                    chX_idx = ismember({EEG.chanlocs.labels}, {'xRRef1', 'xRRef2', 'xRRef3'});
                    EEG.chanlocs(chX_idx) = [];
                    EEG.nbchan = EEG.nbchan - sum(chX_idx);
                    %
                    EEG.data = EEG.csd;
                        EEG.ref = 'CSD';
                end
            
            ALLEEG = eeg_store(ALLEEG, EEG);
            if isstruct(EEG.task_perf)
                EEG.task_perf = struct2table(EEG.task_perf);
            end
            if ~isempty(ALLPRF) && any(ismember(EEG.task_perf.Properties.VariableNames, 'TrialNumber'))
               EEG.task_perf.TrialNumber = EEG.task_perf.TrialNumber + ALLPRF.TrialNumber(end); 
            end
            ALLPRF = [ALLPRF ; EEG.task_perf];
            EEG = []; % clear EEG for next iteration
        end % Merge Task Blocks
            ALLPRFt = ALLPRF;
%             ALLPRFt.TrialNumber = [1:height(ALLPRFt)]';
    clc;
        fprintf('################################################################################\n\n');
        fprintf('MERGING DATASETS: %s \n\n', subjfile_names(part_files_idxs(k),1:14));
        fprintf('################################################################################\n\n');
        EEG = xmerge(ALLEEG);
        EEG = eeg_checkset(EEG);
        EEG = pullchannellocations(EEG);
        
    else % NO merging for CR & APST
    variant_idx = find(ismember(subjfile_names(part_files_idxs,11:16),tasks(vari)));
    EEG = pop_loadset(subjfile_names(part_files_idxs(variant_idx),:));
        if rSelect == 1 % TASK AVG
            EEG = EEG;
            
        elseif rSelect == 2 % RESTING 1 AVG
            rf_idx = find(ismember({EEG.chanlocs.labels}, 'xRRef1'));
            chX_idx = find(ismember({EEG.chanlocs.labels}, {'xRRef2', 'xRRef3'}));
            EEG = pop_reref(EEG, rf_idx, 'exclude', [chX_idx]);
                EEG.ref = 'RESTING';

        elseif rSelect == 3 % INF (REST) Ref
            chX_idx = ismember({EEG.chanlocs.labels}, {'xRRef1', 'xRRef2', 'xRRef3'});
            EEG.chanlocs(chX_idx) = [];
            EEG.nbchan = EEG.nbchan - sum(chX_idx);
            %
            EEG.data = EEG.infref;
                [EEG.chanlocs.ref] = deal("INF");
                EEG.ref = "INF";

        elseif rSelect == 4 % CSD
            chX_idx = ismember({EEG.chanlocs.labels}, {'xRRef1', 'xRRef2', 'xRRef3'});
            EEG.chanlocs(chX_idx) = [];
            EEG.nbchan = EEG.nbchan - sum(chX_idx);
            %
            EEG.data = EEG.csd;
                EEG.ref = 'CSD';
        end
    ALLPRFt = EEG.task_perf;
    end
        EEG.ALLPRF = ALLPRFt;
        EEG.task_perf = [];
    clc;
    
    fprintf('################################################################################\n\n');
    fprintf('Computing ERP file: %s \n\n', [subjfile_names(part_files_idxs(1),1:9) '-' tasks{vari}]);
    fprintf('################################################################################\n\n');
%%----------------------------------------------------------------------------------------- 
EEGSTORE = [];
EEG0 = EEG;
    if ismember(task_var, {'CONTR'}) && length(prm.erpclass) > 1 % HAVENT FIGRUED OUT STIM-LOCK CONTR yet
        prm.erpclass = {'resp-lock'};
    end
        
for erpi = 1:length(prm.erpclass)
    EEG = EEG0; % Re-assign original data (no longer continuous after 1st LOOP)

    %% GENERATE EVENTLIST
    EEG  = pop_creabasiceventlist(EEG, 'AlphanumericCleaning', 'on', 'BoundaryNumeric', {-99}, 'BoundaryString', {'boundary'});
    %% BIN Data & Epoch 
        bdf_path = which(['CREED_' prm.erpclass{erpi} '-' tasks{vari} '.txt']);
    % Define Bins 
    EEG = pop_binlister(EEG, 'BDF', bdf_path, 'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput', 'EEG');
    % Epoch Bins
    EEG = pop_epochbin(EEG, prm.epochrange(erpi,:), prm.baseline(erpi,:));
        EEG.condition = [tasks{vari}];
        EEG.session = [prm.erpclass{erpi}];
    % FILTER IF NEEDED
    if prm.addfiltlp(erpi) > 0
        EEG = simpleEEGfilter(EEG, 'Filter', 'Lowpass', 'Design', 'Windowed Symmetric FIR', 'Cutoff', prm.addfiltlp(erpi), 'Order', (3*fix(EEG.srate/0.5)));
    end    
    % APPLY LINEAR DETREND TO CONTINUOUS DATA
    if prm.applyld == 1
        EEG = lindetrend(EEG, 'all');
    end

    % Removeal of Voltage Artifacts
    EEG = pop_artextval(EEG, 'Channel', 1:EEG.nbchan, 'Flag', 1, 'Threshold', prm.voltagerange, 'Twindow', [(EEG.xmin*1000) (EEG.xmax*1000)]);
    % Store ERP
    EEGSTORE = [EEGSTORE ; EEG];
end % ERP CLASS LOOP

%% Save BIN/EPOCH Data
cd([prm.datadirEEG, prm.erp_proc{1}])
    if ~exist([task_var prm.fieldhandle{1}], 'dir')
        mkdir([task_var prm.fieldhandle{1}])
           cd([task_var prm.fieldhandle{1}])
    else
           cd([task_var prm.fieldhandle{1}])
    end    
    ALLEEG = EEGSTORE;
    save([subjfile_names(part_files_idxs(1),1:10) tasks{vari} prm.fieldhandle{1}], 'ALLEEG')
%% CLEANING - Voltage Threshold, Removal of bad channels & TrialxTrial Visual Inspection
else
end % exist check statement
end % vari LOOP
%%


%     %% Removeal of Voltage Artifacts
%     EEG = pop_artextval(EEG, 'Channel', 1:EEG.nbchan, 'Flag', 1, 'Threshold', prm.voltagerange, 'Twindow', [(EEG.xmin*1000) (EEG.xmax*1000)]);
% 
%     
%     %% Calculate Averaged Epochs
% %     ERP = pop_averager(EEG , 'Criterion', 'good', 'DQ_flag', 1, 'ExcludeBoundary', 'on', 'SEM', 'on' );
% %% Store ERPSET
% ALLERP = [ALLERP ; ERP];
% ERP = [];
% 
% % eeg_hold = eeg_store(eeg_hold, EEG);
% end % vari LOOP 
%     ERP = pop_appenderp(ALLERP, 'Erpsets', [1 2]);
%         ERP.erpname = [subjfile_names(part_files_idxs(1),1:10) task_var];
%         ERP.subject = curr_participant;
% 
% %% SAVE ERPset
% cd([prm.datadirEEG, prm.erp_proc{1}])
%     if ~exist([task_var, prm.erpclass prm.fieldhandle{1}], 'dir')
%         mkdir([task_var, prm.erpclass prm.fieldhandle{1}])
%         cd([task_var, prm.erpclass prm.fieldhandle{1}])
%     else
%         cd([task_var, prm.erpclass prm.fieldhandle{1}])
%     end
% pop_savemyerp(ERP, 'filename', [subjfile_names(part_files_idxs(1),1:10) task_var prm.fieldhandle{1}])

end % partI Loop
%% Look into ADDING MERGING, RT MATCHING, & AVERAGING
% eeg_hold == ALLEEG 2 merge


%     %% Save .erp File in VARIANT DIRECTORY
%     cd(output_dir)
%     if ~exist(strcat(task_var, ".erp"), 'file')
%         mkdir(strcat(task_var, ".erp"));
%         addpath(strcat(task_var, ".erp"))
%     end
%     cd(string(fullfile(output_dir, strcat(task_var,'.erp'))))
%         pop_savemyerp(ERP, 'erpname', char(strcat('CREED', num2str(curr_participant),'_', tasks(varI),'_', prm.erpclass)),...
%             'filename', char(strcat('CREED', num2str(curr_participant),'_', tasks(varI),'_', prm.erpclass)));

end % Function End

%% Check for existence of OUTPUT directory in Path
function directory_check(prm)
cd(prm.datadirEEG)
for fldi = 1:length(prm.erp_proc)
if ~exist(prm.erp_proc{fldi}, 'dir')
    mkdir(prm.erp_proc{fldi});
end
end
end


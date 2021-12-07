%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                         CREED_analyzecode2.0                                                 %
%                                                         --   07/08/2020   --                                                 %
%                        Below is Reduction Code necessary to clean and generate ERPs for Go/No-Go Variants                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                                              

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                          Establishing Paths                                                  %
clc; clear; close all;
init_path = input('Input Path to Data: ', 's');
    if isempty(init_path)
        use_gui = input('Would you prefer to use the GUI (Y/N)? ', 's');
        if strcmpi(use_gui, 'Y')
            init_path = uigetdir;
        else
            init_path = 'F:\DATA\CREED_ParticipantData\'; % Adam's default Pathway
        end
    end
mat_path = input('Input Path to MATLAB CREED Processing functions: ', 's');
    if isempty(mat_path)
        use_gui = input('Would you prefer to use the GUI (Y/N)? ', 's');
        if strcmpi(use_gui, 'Y')
            addpath(genpath(uigetdir));
        else 
            mat_path = 'F:\MATLAB\CREED_Analyze\'; % Adam's Default Pathway
        end
    end
addpath(genpath(mat_path));
eeg_dir = fullfile(init_path, 'EEG');
dex_dir = fullfile(init_path, 'DEX');

clearvars use_gui mat_path

%                                                           ** Do NOT Alter **                                                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                                                                             %                  
proc_tasks = [
              "GNGB"
              "NGGB"
              "PRVT"
              "GNGR"
              "NGGR"
              "GNGC"
              "NGGC"           
              ];
proc_steps = ["0.EEGrawfiles.set" % <-- RAW EEG Folder Name 
              "1.EEGrecode.set"  
%               "2.EEGreduct.set"
%               "3.EEGica.set"
%               "4.EEGclean.set"
%               "5.ERPavg.set"
%               "6.ERPmerge.set"
              ];
% Setup Folders for Sorting of Saved EEG.set files 
cd(eeg_dir)
    fold_in = dir('*.set');
    fold_names = {fold_in.name}';
    if  isempty(find(ismember(fold_names, proc_steps(1))))
        error('Cannot find RAW EEG data directory, be sure it is in path and properly named');
    end
    % Compare Folders in path to proc_steps
    needed_folders = find(~ismember(proc_steps, fold_names));
    if ~isempty(needed_folders)
        for fold_i = 1:length(needed_folders) 
            if ~isempty(find(strcmp(proc_steps(needed_folders(fold_i)), proc_steps(2))))
                mkdir(proc_steps(needed_folders(fold_i)));
                
            elseif ~isempty(find(ismember(proc_steps(needed_folders(fold_i)), [proc_steps(6), proc_steps(7)])))
                mkdir(proc_steps(needed_folders(fold_i)), 'BTN.erp');
                mkdir(proc_steps(needed_folders(fold_i)), 'RCH.erp');
                mkdir(proc_steps(needed_folders(fold_i)), 'CNT.erp');
            else
                 mkdir(proc_steps(needed_folders(fold_i)), 'GNGB.set'); mkdir(proc_steps(needed_folders(fold_i)), 'GNGC.set'); 
                mkdir(proc_steps(needed_folders(fold_i)), 'GNGR.set'); mkdir(proc_steps(needed_folders(fold_i)), 'NGGB.set'); 
                mkdir(proc_steps(needed_folders(fold_i)), 'NGGC.set'); mkdir(proc_steps(needed_folders(fold_i)), 'NGGR.set');
            end
        end
    end
    addpath(genpath(eeg_dir))
    addpath(genpath(dex_dir))
    clearvars fold_in fold_names needed_folders fold_i
    
%                                                                                                                             % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                          Begin Processing Steps                                                             %
% This code is designed to run through each participant's data fodler & Load GNG/NGG Task Variant                             %
%                After file is loaded it runs through the COMPLETE processing steps                                           %  

cd(fullfile(eeg_dir,proc_steps(1)))
part_dirs = dir('CREED*');
part_names = char({part_dirs.name});
% Begin Running through Participant Folders and loading task files
for part_i = 1:size(part_names,1)
    cd(fullfile(eeg_dir, proc_steps(1), part_names(part_i,:)))
    task_files = dir('*.vhdr');
    file_names = char({task_files.name});
    pol_inv = [];
    for task_i = 1:size(file_names,1)
        task = file_names(task_i, 1:16);
        task_type = file_names(task_i, 11:14);
        % Checks if TASK is in PROC_TASKS list
        task_check = find(ismember(proc_tasks, task_type));
        if task_check >= 1
            % Checks for existence of RECODE file 
            if ~exist(strcat(task, '_mrk2.set'), 'file')
%%%%%%                                        Processing Step #1: Recode EEG File                                       %%%%%%                          
                msgbox({task ; proc_steps(2)}, 'modal') 
                % Load BrainVision Recorder File
                try
                EEG = pop_loadbv(fullfile(eeg_dir, proc_steps(1), part_names(part_i,:)), file_names(task_i,:), [], [1:65]);
                catch
                    keyboard;
                end
                % Recode EEG file to merge DEX event codes
                EEG = CREED_BVArecode(EEG, dex_dir, part_names(part_i, 1:12), file_names(task_i, 1:16)); 
                    cd(fullfile(eeg_dir, proc_steps(2)))
                    if ~exist(strcat(part_names(part_i,1:9), '_mrk2.set'), 'dir')
                        mkdir(strcat(part_names(part_i,1:9), '_mrk2.set'))
                    end
                    cd(strcat(part_names(part_i,1:9), '_mrk2.set'))
                    pop_saveset(EEG, strcat(task, '_mrk2'));
            end
            % Checks for existence of REDUCT file
            if ~exist(strcat(task, '_reduct.set'), 'file')
                
%%%%%                                      Processing Step #2: EEG Pre-Processing                                     %%%%%%    

                msgbox({task ; proc_steps(3)}, 'modal')
                if ~exist('EEG', 'var')
                    EEG = pop_loadset(strcat(task,'_mrk2.set'));
                end
                % Prepare EEG File for ICA 
                chan_locfile = which('standard-10-5-cap385.elp');
                try
                    [EEG, pol_inv] = CREED_PreProcessing(EEG, chan_locfile, pol_inv); % Using code default settings
                catch
                    keyboard
                end
                    cd(fullfile(eeg_dir, proc_steps(3), strcat(task_type, '.set')))
                    pop_saveset(EEG, strcat(task, '_reduct'),'savemode', 'onefile');
                clearvars chan_locfile 
            end
            % Checks for existence of ICA file
%             if ~exist(strcat(task, '_ica.set'), 'file')
%                 
% %%%%%%                                 Processing Step #3: Generate ICs for blink analysis                            %%%%%%
%                 
%                 msgbox({task ; proc_steps(4)}, 'modal')
%                 if ~exist('EEG', 'var')
%                     EEG = pop_loadset(strcat(task,'_reduct.set'));
%                 end
%                 % Look for Studywise RNG to set rand function seed 
%                 if ~exist('StudyRNG.mat', 'file')
%                     studyRNG = rng; save('StudyRNG.mat', 'studyRNG');
%                 else 
%                     studyRNG = load('StudyRNG.mat');
%                 end
%                 % Run InfoMax ICA (options based on Pontifex et al Psychophys 2017)
%                 EEG = pop_runica(EEG, 'icatype', 'runica', 'options', {'extended', 1, 'block', floor(sqrt(EEG.pnts/3)),...
%                     'anneal', 0.98, 'reset_randomseed', 'no'});
%                 cd(fullfile(eeg_dir, proc_steps(4), strcat(task_type, '.set')))
%                     pop_saveset(EEG, strcat(task, '_ica'),'savemode', 'onefile');
%             end
% %             Check for existence of CLEAN file
%             if ~exist(strcat(task, '_clean.set'), 'file')
%                 
% %%%%%%                    Processing Step #4: Artifact Removal, Channel Interpol, & Re-reference                      %%%%%%
%                 
%                 msgbox({task ; proc_steps(5)}, 'modal')
%                 if ~exist('EEG', 'var')
%                     EEG = pop_loadset(strcat(task,'_ica.set'));
%                 end
%                 % Infomax ICA (options based on Pontifex et al Psychophys 2017)
%                 EEG =EEG.CREED_Reduction(EEG, 'ArtifactChannels', {'VEOG', 'HEOG'});
%                 cd(fullfile(eeg_dir, proc_steps(5), strcat(task_type, '.set')))
%                     pop_saveset(EEG, strcat(task, '_clean'),'savemode', 'onefile');
%              end
        clearvars EEG %% IF SEGMENTING PROCESSING DO NOT COMMENT THIS LINE OUT!!! 
        end
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                     Calculate ERPs from Completed Participant Files                                        %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% variant = {'BTN', 'RCH', 'CNT'};
    
% Merge similar TASK BLOCKS 
% for merge_i = 1:length(proc_tasks)
%     if ~exist(strcat(task(1:9), proc_tasks(merge_i), '_resplock.erp'), 'file')
%     msgbox({strcat(task(1:9), '_', proc_tasks(merge_i)) ; proc_steps(6)}, 'modal')
%         cd(fullfile(eeg_dir, proc_steps(5), strcat(proc_tasks(merge_i), '.set'))) 
%         clean_files = dir('*.set');
%         clean_names = char({clean_files.name});
%         % Find ALL participant files to gen ALLEEG for merging & EPOCHING
%         EEG = EEG.CREEDmerge_cleansets(clean_names, task(1:9), proc_tasks(merge_i));        
%         % Generating BINS & Average ERPSETS
%             if find(strcmp(proc_tasks(merge_i), ["GNGB", "GNGR", "GNGC"]))
%                 if strcmp(variant(round(merge_i/2)), 'BTN')
%                     rl_bdf = which('CREED_RL.btn_GO-GO.bdf');
%                     sl_bdf = which('CREED_SL.btn_GO-GO.bdf');
%                 elseif strcmp(variant(round(merge_i/2)), 'RCH')
%                     rl_bdf = which('CREED_RL.rch_GO-GO.bdf');
%                     sl_bdf = which('CREED_SL.rch_GO-GO.bdf');
%                 elseif strcmp(variant(round(merge_i/2)), 'CNT')
% %                     sl_bdf = which('CREED_SL.cnt_GO-GO.bdf'); == STILL NEED TO CREATE
%                 else
%                 end          
%             elseif find(strcmp(proc_tasks(merge_i), ["NGGB", "NGGR", "NGGC"]))
%                 
%                 if strcmp(variant(round(merge_i/2)), 'BTN')
%                     rl_bdf = which('CREED_RL.btn_NOGO-GO.bdf');
%                     sl_bdf = which('CREED_SL.btn_NOGO-NOGO.bdf');
%                 elseif strcmp(variant(round(merge_i/2)), 'RCH')
%                     rl_bdf = which('CREED_RL.rch_NOGO-GO.bdf');
%                     sl_bdf = which('CREED_SL.rch_NOGO-NOGO.bdf');
%                 elseif strcmp(variant(round(merge_i/2)), 'CNT')
% %                     sl_bdf = which('CREED_SL.cnt_NOGO-NOGO.bdf'); == STILL NEED TO CREATE
%                 else
%                 end 
%             else
%                 error('Variant NOT YET supported for ERP reduction - check back again later');
%             end
%                 EEG = EEG.CREEDadj_eventmarkers(EEG, 0, proc_tasks(merge_i)); %% Uses NEW ERROR Threshold to modidfy COMMISSION ERROR Event Codes %% 
%                 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                   *** Current Editing Point ***                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 
%                 rlERP = EEG.CREED_genERP(EEG, rl_bdf, 'LockTypye', 'Response', 'EpRange', [-400 600],  'Baseline', [-400 -200], 'Volt', [-100 100]);
%                 slERP = EEG.CREED_genERP(EEG, sl_bdf, 'LockTypye', 'Stimulus', 'EpRange', [-100 1000], 'Baseline', [-100 0],    'Volt', [-100 100]);
%         %% SAVE files according to the TASK TYPE %% 
%         cd(fullfile(eeg_dir, proc_steps(6), strcat(variant(round(merge_i/2)), '.erp')))
%            pop_savemyerp(rlERP, 'erpname', char(strcat(task(1:9),proc_tasks(merge_i), '_resplock')), 'filename',...
%                char(strcat(task(1:9), proc_tasks(merge_i), '_resplock.erp')));
%            pop_savemyerp(slERP, 'erpname', char(strcat(task(1:9),proc_tasks(merge_i), '_stimlock')), 'filename',...
%                char(strcat(task(1:9), proc_tasks(merge_i), '_stimlock.erp')));
%         clearvars rlERP slERP EEG
%     end
% end
%    % Combine ERPs files == TASK TYPE (i.e. GNGB + NGGB = BUTTONresplock.erp) 
% for merge_i = 1:length(proc_tasks)
%     if ~exist(string(strcat(task(1:9), variant(round(merge_i/2)), '_resplock.erp')), 'file')
%         cd(fullfile(eeg_dir, proc_steps(6), strcat(variant(round(merge_i/2)), '.erp')))
%         part_erpfiles = dir('*.erp');
%         erp_names = char({part_erpfiles.name});
%         lock_variant = {'resplock.erp' , 'stimlock.erp'};
%         curr_participant = find(ismember(string(erp_names(:,1:9)), task(1:9)));
%         for lock_i = 1:length(lock_variant)
%         erps2merge = find(endsWith(string(erp_names(curr_participant,:)), lock_variant(lock_i)));
%         % Setup ALLERP to merge
%         ALLERP = [];
%             for j = 1:length(erp_names(erps2merge)) 
%                 ERP = pop_loaderp('filename', erp_names(erps2merge(j),:));
%                 ALLERP = [ALLERP ; ERP];
%                 ERP = [];
%             end
% %         % Check ERP size compatibility & edit if necessary
% %         [ALLERP, del_chans] = checkERPsize(ALLERP);
%         % Merge ERPsets
%         ERP = pop_appenderp(ALLERP, 'Erpsets', [1:length(erps2merge)]);
% %         % Create CRN-ERN difference wave
%             if strcmp(lock_variant(lock_i), 'resplock.erp')
%                 ERP = pop_binoperator(ERP, {'b3 = b1 - b2 label DIFF'});
%             else
%             end
% %         ERP.del_chans = del_chans;
% %         % Save merged ERP file
%         cd(fullfile(eeg_dir, proc_steps(7), strcat(variant(round(merge_i/2)), '.erp'))) 
             pop_savemyerp(ERP, 'erpname', char(strcat(task(1:9),variant(round(merge_i/2)), lock_variant(lock_i))),...
                 'filename', char(strcat(task(1:9), variant(round(merge_i/2)), '_', lock_variant(lock_i))))    
%         end
%     end
% end
end



    
    

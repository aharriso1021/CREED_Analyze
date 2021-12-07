%%-----------------------------------------------------------------------------------------------------------%%
%                                            CREED EEG Pre-Processing                                         %
%                                           [ATH] 11/02/2020 - Updated                                        %
%%-----------------------------------------------------------------------------------------------------------%%

%%-----------------------------------------------------------------------------------------------------------%%
%
% ** Code is meant to run as is for EEG collected using BVA + KINARM setup
% ** Relies on configuration of parameters defined in CREED_Preprocessing_prm_set.mat
%
%%-----------------------------------------------------------------------------------------------------------%%

function CREED_Preprocessing(prm)
% Setting PATH

addpath(genpath(prm.datadirDEX)); addpath(genpath(prm.datadirEEG)); addpath(genpath(prm.matlabdir));addpath(genpath(prm.datadirGZE));
try 
    [ALLEEG, EEG, CURRENTSET, ALLCOM] =  eeglab;
catch 
    dir_input = input('Unable to locate EEGLAB please input proper path: ', 's');
    addpath(dir_input);
    [ALLEEG, EEG, CURRENTSET, ALLCOM] =  eeglab;
end

% Check Folders in DATA DIRECTORY
fNames = check_outputdirectories(prm);

%%-----------------------------------------------------------------------------------------------------------%%
% Begin Pre-Processing Data                                                                                   %
%%-----------------------------------------------------------------------------------------------------------%%

% Begin at RAW DATA FILES
cd(string(fNames(1)))
fFiles = dir('*.eeg');
pNames = {fFiles.name};
    % MAC transfer twist
    xi  = find(contains(pNames, '._'));
    pNames(xi) = [];
    pNames = char(pNames);
TaskList = prm.TaskList;

% Loop through Participant RAW FILES
for iPart = 1:size(pNames,1)
cd(pNames(iPart,:))
curr_part = pNames(iPart,1:12);
pFiles = dir(prm.eegFileType);
    % MAC SAVING TWEAK
    if ~isempty(find(contains({pFiles.name}, '._')))
        delete(pFiles(contains({pFiles.name}, '._')).name);
    end
taskFiles = char({pFiles.name});
pol_inv = []; % Tweak for polarity check on EOG electrodes & resets with every new participant loop 

% Loop through Task List Files
for iTL = 1:length(TaskList)
    task_Idx = find(ismember([taskFiles(:,11:14)], TaskList(iTL)));
% Loop through Participant Task Files
for iTask = 1:size(task_Idx,1)
EEG = []; % Ensures EEG is clear    
    curr_task = taskFiles(task_Idx(iTask),11:14);
    curr_taskrun = taskFiles(task_Idx(iTask),15:16);
    if ismember(curr_task, 'APST')
       if ~exist([taskFiles(task_Idx(iTask),1:16) 'ecl.mat'])
           break
       end
    end
if ismember(curr_task, prm.TaskList)
if ~exist([taskFiles(task_Idx(iTask),1:16) prm.filehandle{1}], 'file') && ~strcmp([curr_task,curr_taskrun], 'APST02') % DONT WANT TO PROC APST02 YET
%%-----------------------------------------------------------------------------------------------------------%%
% Step 1: BVA + DEX Recode
        clc;
    fprintf('################################################################################\n\n');
    fprintf('LOADING DATA: %s \n\n', [curr_part ' ' curr_task curr_taskrun]);
    fprintf('################################################################################\n\n');
    if strcmp(prm.eegFileType, '*.vhdr') % LOAD BV Recorder File
        EEG = pop_loadbv(char(fullfile(prm.datadirEEG, fNames(1), pNames(iPart,:))),taskFiles(task_Idx(iTask),:), [], [1:65]);
        rec_info = readtable(taskFiles(task_Idx(iTask),:), 'FileType', 'text', 'VariableNamingRule', 'preserve');
            rec_info = string(rec_info{82:145,1});
            rec_info2 = [];
            for rci = 1:length(rec_info)
                splt = strtrim(strsplit(rec_info(rci,':')));
                    if strcmp(splt(1), 'Gnd') && strcmp(splt(2), 'not connected')
                        error(['GND IMP Error: ' taskFiles(task_Idx(iTask),:)]);
                    end
                rec_info2{rci,1} = splt(1);
                rec_info2{rci,2} = str2double(splt(2));
                    if isnan(rec_info2{rci,2})
                        rec_info2{rci,2} = 1000;
                    end
            end
        EEG.rec_info = rec_info2;
    else
    end

        clc;
    fprintf('################################################################################\n\n');
    fprintf('MERGING EVENT CODES: %s \n\n', [taskFiles(task_Idx(iTask),1:16)]);
    fprintf('################################################################################\n\n');
%
    if strcmp(curr_task,'APST')
        EEG = CREED_APST_add_events(EEG, prm.datadirGZE, taskFiles(task_Idx(iTask),1:16)); 
    else
        EEG = CREED_BVArecode(EEG, prm.datadirDEX, prm.datadirGZE, curr_part, taskFiles(task_Idx(iTask),1:16));
    end
    
        % Downsample if necessary 
        if ~isempty(prm.resample)
            EEG = pop_resample(EEG, prm.resample);   
        end
        % Check to ensure data = double precision        
        if ~isdoublep(EEG.data)
            temp = double(EEG.data);
            EEG.data = temp;
        end
        
    EEG.subject = taskFiles(task_Idx(iTask), 1:9);
    EEG.condition = curr_task;
    EEG.session = str2double(curr_taskrun);

% SAVE RECODE set
    cd(fullfile(prm.datadirEEG,fNames{2}))
    if ~exist([curr_task prm.filehandle{1}],'dir')
        new_dir = [curr_task prm.filehandle{1}];
        mkdir(new_dir);
        cd(new_dir)
    else
        cd([curr_task prm.filehandle{1}])
    end
        clc;
    fprintf('################################################################################\n\n');
    fprintf('SAVING DATA FILE: %s \n\n', [taskFiles(task_Idx(iTask),1:16) prm.filehandle{1}]);
    fprintf('################################################################################\n\n');
        pop_saveset(EEG, [taskFiles(task_Idx(iTask),1:16) prm.filehandle{1}]);
%%-----------------------------------------------------------------------------------------------------------%%
end % RECODE Complete Check

if ~exist([taskFiles(task_Idx(iTask),1:16) prm.filehandle{2}]) && ~strcmp([curr_task,curr_taskrun], 'APST02') % DONT WANT TO PROC APST02 YET
%%-----------------------------------------------------------------------------------------------------------%%
% Step 2: Pre-ICA Cleaning 
    if isempty(EEG)
        EEG = pop_loadset([taskFiles(task_Idx(iTask),1:16) prm.filehandle{1}]);
    end
    
        clc;
    fprintf('################################################################################\n\n');
    fprintf('PRE-PROCESSING FILE: %s \n\n', [taskFiles(task_Idx(iTask),1:16)]);
    fprintf('################################################################################\n\n');   
    %
    [EEG, pol_inv] = CREED_PreICAcleaning(EEG, pol_inv, prm);

% SAVE PRE-ICA set
    cd(fullfile(prm.datadirEEG,fNames{3}))
    if ~exist([curr_task prm.filehandle{2}], 'dir')
        new_dir = [curr_task prm.filehandle{2}];
        mkdir(new_dir);
        cd(new_dir)
    else
        cd([curr_task prm.filehandle{2}])
    end
        clc;
    fprintf('################################################################################\n\n');
    fprintf('SAVING DATA FILE: %s \n\n', [taskFiles(task_Idx(iTask),1:16) prm.filehandle{2}]);
    fprintf('################################################################################\n\n');
        pop_saveset(EEG, [taskFiles(task_Idx(iTask),1:16) prm.filehandle{2}]);
%%-----------------------------------------------------------------------------------------------------------%%
end % PRE-ICA Complete Check
% 
%%-----------------------------------------------------------------------------------------------------------%%
% Step 3: Compute ICA 
if ~exist([taskFiles(task_Idx(iTask),1:16) prm.filehandle{3}]) && ~strcmp([curr_task,curr_taskrun], 'APST02') % DONT WANT TO PROC APST02 YET
    if isempty(EEG)
        EEG = pop_loadset([taskFiles(task_Idx(iTask),1:16) prm.filehandle{2}]);
    end
icatype = prm.ICAtype;
switch icatype
    case 'INFOMAX'
        EEG = pop_runica(EEG,'icatype','runica','options',{'extended',1,'block',floor(sqrt(EEG.pnts/3)),'anneal',0.98,'rndreset','no'});
    case 'PICARD'
        EEG = pop_runica(EEG, 'icatype', 'picard', 'mode', 'ortho', 'maxiter', 200, 'tol', 1e-10, 'verbose', 1);
    otherwise
end
        clc;
    fprintf('################################################################################\n\n');
    fprintf('FINISHED COMPUTING ICA: %s \n\n', [taskFiles(task_Idx(iTask),1:16) prm.filehandle{2}]);
    fprintf('################################################################################\n\n');

% SAVE ICA set
    cd(fullfile(prm.datadirEEG,fNames{4}))
    if ~exist([curr_task prm.filehandle{3}], 'dir')
        new_dir = [curr_task prm.filehandle{3}];
        mkdir(new_dir);
        cd(new_dir)
    else
        cd([curr_task prm.filehandle{3}])
    end
        clc;
    fprintf('################################################################################\n\n');
    fprintf('SAVING DATA FILE: %s \n\n', [taskFiles(task_Idx(iTask),1:16) prm.filehandle{3}]);
    fprintf('################################################################################\n\n');
        pop_saveset(EEG, [taskFiles(task_Idx(iTask),1:16) prm.filehandle{3}]);
end % ICA Complete Check
%-----------------------------------------------------------------------------------------------------------%%
        % ADD RHRV AVG to EEG Struct % 
%-----------------------------------------------------------------------------------------------------------%%
% Step 4: Remove ICs, Interpolate, Re-reference, & Complete Reduction

if ~exist([taskFiles(task_Idx(iTask),1:16) prm.filehandle{4}]) && ~strcmp([curr_task,curr_taskrun], 'APST02') % DONT WANT TO PROC APST02 YET
    if isempty(EEG)
        EEG = pop_loadset([taskFiles(task_Idx(iTask),1:16) prm.filehandle{3}]);
    end
        clc;
    fprintf('################################################################################\n\n');
    fprintf('GENERATING CLEAN SET FILE: %s \n\n', [taskFiles(task_Idx(iTask),1:16)]);
    fprintf('################################################################################\n\n');   
    %
    if ismember(curr_task, {'GNGB' 'NGGB'})
        variant = 'BUTTON';
    elseif ismember(curr_task, {'GNGR' 'NGGR'})
        variant = 'REACH';
    elseif ismember(curr_task, {'GNGC' 'NGGC'})
        variant = 'CONTR';
    else
        variant = curr_task;
    end
    
    if ~exist('xRest', "var") 
    xRest = [];
    end
    
    % SNAG RESTING DATA 
    [EEG, xRest] = CREED_CleanSet(EEG, prm, xRest);
    
%     if ~ismember(variant, 'RHRV')
%         % LOAD xRest Data if not in Workspace Already
%         if isempty(xRest)
%             cd([prm.datadirEEG prm.proc_steps{4} '/RHRV_clean.set'])
%             pRHRV_files = dir('*.set');
%             pRHRV_fNames = {pRHRV_files.name};
%             curr_pRHRV = find(contains(pRHRV_fNames, EEG.subject));
%             xRest = [];
%             for rI = 1:length(curr_pRHRV)
%                 rxEEG = pop_loadset(pRHRV_fNames(curr_pRHRV(rI)));
%                 xRest{rI} = rxEEG.xRest;
%             end
%         end
%         % ADD xRRef Channel DATA
%         pts = EEG.pnts;
%         for rr = 1:length(xRest)
%             xRdat = xRest{rr};
%             seg_diff = uint32((length(xRdat)-pts)/2);
%         % 
%         nCh = EEG.nbchan;
%         EEG.nbchan = nCh + 1;
%         EEG.chanlocs(nCh+1).labels = ['xRRef' num2str(rr)];
%         EEG.data(nCh + 1,:) = zeros(1,EEG.pnts);
%             try
%                 EEG.data(nCh + 1,:) = [xRdat(seg_diff:end-seg_diff)];
%             catch
%                 EEG.data(nCh + 1,:) = [xRdat(seg_diff:end-seg_diff-1)]; % Some reason size of trim = +1 
%             end        
%         end
%      end
    
% SAVE CLEAN set
    cd(fullfile(prm.datadirEEG,fNames{5}))
    if ~exist([variant prm.filehandle{4}], 'dir')
        new_dir = [variant prm.filehandle{4}];
        mkdir(new_dir);
        cd(new_dir)
    else
        cd([variant prm.filehandle{4}])
    end
        clc;
    fprintf('################################################################################\n\n');
    fprintf('SAVING DATA FILE: %s \n\n', [taskFiles(task_Idx(iTask),1:16) prm.filehandle{4}]);
    fprintf('################################################################################\n\n');
        pop_saveset(EEG, [taskFiles(task_Idx(iTask),1:16) prm.filehandle{4}]);  

end % Clean Set check
end % TASK CHECK 
end % end I_TASK loop
end % TASK LIST Loop

EEG = []; %% clears EEG sanity check == restarting processing for new participant
xRest = []; % Clear for next participant

cd(fullfile(prm.datadirEEG, fNames{1})) % RETURN TO PARENT EEG DIRECTORY

end % end I_PART LOOP



end % end CREED_Preprocessing

function fNames = check_outputdirectories(prm)
cd(prm.datadirEEG) 
proc_steps = {'1.RECODE.set', '2.PRE_ICA.set', '3.ICA.set', '4.CLEAN.set'};
fldrs = dir('*.set');
fNames = {fldrs.name};
    % MAC transfer twist
    xi  = find(contains(fNames, '._'));
    fNames(xi) = [];
needed_dirs = find(~ismember(proc_steps, fNames));
if ~isempty(needed_dirs)
    for i = 1:length(needed_dirs)
        mkdir(string(proc_steps(needed_dirs(i))));
    end
    addpath(genpath(prm.datadirEEG));
else
        fNames = fNames;
end
end
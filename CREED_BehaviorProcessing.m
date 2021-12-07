 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                      CREED Behavioral Processing                           %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear all; close all; clc;

% display('Designate path to KINARM data directory');
% knDirect = uigetdir;
%     knDirect = '/Volumes/HARRISONext/DATA/CREED_ParticipantData/DEX/'; %% ADAM'S DEFAULT PATHWAY
drvr = input('Indicate working driver for (ex: D:\): ', 's');
    knDirect = [drvr '\DATA/CREED_ParticipantData/DEX/'];
addpath(genpath(knDirect));

taskList = {
    'GNGB'
    'GNGR'
    'GNGC'
    'NGGB'
    'NGGR'
    'NGGC'
%     'APST'
    };

if exist('2.DEX.proc','dir') == 0
    cd(knDirect)
    mkdir(knDirect, '2.DEX.proc');
    addpath(genpath(knDirect));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
cd(fullfile(knDirect,'1.DEX.trim'))
catch
    errordlg('1.DEX.trim directory not found! Be sure pathway is correct.', 'Directory Error');
end
participants = dir('*.dex');
participantNames = char({participants.name}'); % List of Participant files
%% Loop through each participant file NOT already completed %%
for part_idx = 1:size(participantNames,1)
    partID = participantNames(part_idx,1:9);
    if ~exist(strcat(partID,'_dexproc.mat'), 'file')
    cd(fullfile(knDirect, '1.DEX.trim', participantNames(part_idx,:)))
% Step 1: BVA + DEX Recode
        clc;
    fprintf('################################################################################\n\n');
    fprintf('LOADING PARTICIPANT: %s \n\n', participantNames(part_idx,:));
    fprintf('################################################################################\n\n');
        files = dir('*.zip');
        fileNames = char({files.name}');
        taskfile_idx = find(ismember(fileNames(:,11:14),taskList));
            CREED_knDat = struct('Task',{},'Run', [],'TrialData',[]);
            CREED_knDat = repmat(CREED_knDat, [length(taskfile_idx) 1]);
        for task_idx = 1:length(taskfile_idx) %% Process participant files of interest (in taskList) & store in participant struct >> 2.Dex.proc
            CREED_knDat(task_idx).Task = string(fileNames(taskfile_idx(task_idx),11:14));
            CREED_knDat(task_idx).Run  = string(fileNames(taskfile_idx(task_idx),15:16));
                data = LOADFILES.zip_load(fileNames(taskfile_idx(task_idx),:));
        clc;
    fprintf('################################################################################\n\n');
    fprintf('PROCESSING TASK: %s \n\n', fileNames(taskfile_idx(task_idx),1:16));
    fprintf('################################################################################\n\n');
                    data = c3d_reorder(data); % reorder .c3d files within DEX data file to correspond to TRIAL NUMBER
                    [data, ~] = remove_gazecodes(data); % remove any gaze codes added by the EyeLink
                    %% [May need to rethink for APST] %%
                    CREED_knDat(task_idx).TrialData = behaviorProc(data, fileNames(taskfile_idx(task_idx),11:14));
        end
        cd(fullfile(knDirect, '2.DEX.proc'))
        save(strcat(partID, '_dexproc.mat'), 'CREED_knDat');
    end
end

function perfMatrix = behaviorProc(datain, task)
knc3d = datain.c3d;

if strcmp(task, 'GNGB') || strcmp(task,'NGGB')
        disp('Button Task Variant');
        perfMatrix = calcButtonPerformance(knc3d, task);
        perfMatrix = struct2table(perfMatrix);
elseif strcmp(task,'GNGR') || strcmp(task,'NGGR')
        disp('Reach Task Variant');
        perfMatrix = calcReachPerformance(knc3d);
        perfMatrix = struct2table(perfMatrix);
elseif strcmp(task,'GNGC') || strcmp(task,'NGGC')
        disp('Continuous Task Variant');
        [~, perfMatrix, ~] = gen_continuous_data(knc3d);
elseif strcmp(task,'APST')
        disp('Anti-Pro Saccade Task');
        
else
        errordlg('Unknown task type');
end      
end





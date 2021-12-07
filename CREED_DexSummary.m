function CREED_GNGperf = CREED_DexSummary
%% Initialize Directory & Table 
if ispc
drvr = input('Indicate working driver for (ex: D:\): ', 's'); 
    dex_dir = [drvr '\DATA\CREED_ParticipantData\DEX\'];
elseif isunix
    dex_dir = '/Volumes/HARRISON_TB/DATA/CREED_ParticipantData/DEX/2.DEX.proc/';
end
if exist('CREED_GNGperf.mat', 'file') == 2
    load CREED_GNGperf.mat
else
    CREED_GNGperf = table();
end
%%
cd([dex_dir '2.DEX.proc\'])
dir_files = dir('*.mat');
participant_files = char(dir_files.name);

%%
for i_part = 1:length(participant_files)
%%%%%%% PARTICIPANT IN TABLE %%%%%%%%%%%%
if isempty(CREED_GNGperf) || ~ismember(str2double(participant_files(i_part,6:9)), CREED_GNGperf.ID)
    disp(participant_files(i_part,1:9));
    load(participant_files(i_part,:), 'CREED_knDat');
    unique_tasks = unique([CREED_knDat.Task]);
    curr_ID = str2double(participant_files(i_part,6:9));
    part_tbl = table();
    %% Generate participant table 
    for i_task = 1:length(unique_tasks)
        curr_task = find(strcmp([CREED_knDat.Task],unique_tasks(i_task)));
        task_data = [];
        task_tbl  = table();
        if ismember(unique_tasks(i_task), {'GNGC' 'NGGC'})
            for i_run = 1:length(curr_task)
                task = strcat(CREED_knDat(curr_task(i_run)).Task, CREED_knDat(curr_task(i_run)).Run);
                task_data = CREED_knDat(curr_task(i_run)).TrialData;
                task_tbl = fill_table(task_data, task_tbl, curr_ID, task);
                part_tbl = [part_tbl ; task_tbl];
            end
        else
            for i_run = 1:length(curr_task)
                task_data = [task_data ; CREED_knDat(curr_task(i_run)).TrialData(:,2:end)];
            end
            task = strcat(CREED_knDat(curr_task(i_run)).Task,'00');
            task_tbl = fill_table(task_data, task_tbl, curr_ID, task);
            part_tbl = [part_tbl ; task_tbl];
        end    
    
    end  
CREED_GNGperf = [CREED_GNGperf ; part_tbl];

end % EXIST CHECK
end % END Participant LOOP 
cd(dex_dir)
CREED_GNGperf = sortrows(CREED_GNGperf, 'ID', 'ascend');
save('CREED_GNGperf.mat', 'CREED_GNGperf');
% add sort
end % FUNCTION END

function tbl_out = fill_table(data_in, tbl_in, curr_id, task)
tbl_out = tbl_in;

tbl_out.ID    = curr_id; 
tbl_out.Task  = categorical(task);

%% Initializing Object & Accuracy LOGICALS
if ismember(task, {'GNGB00' 'NGGB00'})
    obj_logi = strcmp(data_in.StimulusType, 'Target'); % LOGICAL idx of Targets (1) and Distractors (0)    
    acc_logi = data_in.TrialAccuracy == 1; % LOGICAL idx of trial Correct (1) and Incorrect (0)
    TrialRT = data_in.TrialRT;
elseif ismember(task, {'GNGR00' 'NGGR00'})
    obj_logi = strcmp(data_in.StimulusType, 'Target');         % LOGICAL idx of Targets (1) and Distractors (0)
    data_in.prctReach(isnan(data_in.prctReach)) = -99;         % Temporarily set NaN reach --> -99.0   
    data_in.TrialReachDist(isnan(data_in.TrialReachDist)) = 0; % Temporarily set NaN reach dist --> 0
    acc_logi = zeros(height(data_in),1);
    % Building ACC LOGICAL IDX - Correct (1) and Incorrect (0)
        acc_logi(obj_logi & data_in.prctReach  >= 80) = 1; 
        % acc_logi(obj_logi & data_in.prctReach  <  80) = false; % Override if participant did NOT fully reach out to TARGET
        acc_logi(~obj_logi & data_in.TrialReachDist <  2.0) = 1; 
        % acc_logi(~obj_logi & data_in.prctReach >= 10) = false; % Override: participant must reach > threshold for error
    acc_logi = logical(acc_logi);
    TrialRT = data_in.TrialRT;
elseif ismember(task, {'GNGC01' 'NGGC01' 'GNGC02' 'NGGC02'})
    obj_logi = data_in(:,2) == 1;
    acc_logi = zeros(size(data_in,1),1);
        acc_logi(obj_logi & data_in(:,6) == 1)  = 1; % isTarg + Hit
        acc_logi(~obj_logi & data_in(:,6) == 0) = 1; % ~isTarg + ~Hit
    TrialRT = double((data_in(:,4) - data_in(:,1))*5); %adj for 200Hz Fs * 5ms
end
% Performance
tbl_out.ACC   = (sum(acc_logi)/length(acc_logi))*100;
tbl_out.THits = sum(obj_logi & acc_logi);
tbl_out.TMiss = sum(obj_logi & ~acc_logi);
tbl_out.DHits = sum(~obj_logi & ~acc_logi);
% Behavior
tbl_out.RTtarg   = mean(TrialRT(obj_logi & acc_logi));
tbl_out.RTSDtarg = std(TrialRT(obj_logi & acc_logi));
tbl_out.CVRTtarg = std(TrialRT(obj_logi & acc_logi)) ./ mean(TrialRT(obj_logi & acc_logi));
tbl_out.RTdist   = mean(TrialRT(~obj_logi & ~acc_logi));
tbl_out.RTSDdist = std(TrialRT(~obj_logi & ~acc_logi));
tbl_out.CVRTdist = std(TrialRT(~obj_logi & ~acc_logi)) ./ mean(TrialRT(~obj_logi & ~acc_logi));
%% Initialize Signal Detection Parameters
h = sum(obj_logi & acc_logi) / sum(obj_logi);
f = sum(~obj_logi & ~acc_logi) / sum(~obj_logi);
LLh = (sum(obj_logi & acc_logi) + 0.5) / (sum(obj_logi) + 1);
LLf = (sum(~obj_logi & ~acc_logi) + 0.5) / (sum(~obj_logi) + 1);
% Signal Detection Theory
tbl_out = calc_sdt(tbl_out, h, f, LLh, LLf);
end
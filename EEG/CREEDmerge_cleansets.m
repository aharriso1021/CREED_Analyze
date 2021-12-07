function [EEG] = CREEDmerge_cleansets(dir_list, part_ID, curr_task)
% Find ALL participant files to gen ALLEEG for merging & EPOCHING
part_files2merge = find(ismember(string(dir_list(:,1:9)), part_ID));
    if ismember(curr_task, ["GNGC", "NGGC"]) %% Do not merge CONTINUOUS task
    % LOAD LOOP SINGLE FILE AND PROC
    elseif ismember(curr_task, ["GNGB", "NGGB", "GNGR", "NGGR"])
        ALLEEG = [];
        for k = 1:length(part_files2merge)
            EEG = pop_loadset(dir_list(part_files2merge(k), :));
            ALLEEG = eeg_store(ALLEEG, EEG); EEG = [];
        end
    else
        error('Task Type Not Supported');
    end 
% Merge like data sets into one
EEG = xmerge(ALLEEG);
EEG = eeg_checkset(EEG);
EEG = pullchannellocations(EEG);
total_perf = [];
    for j = 1:length(part_files2merge)
        if j == 1
            total_perf = [total_perf ; table2struct(ALLEEG(j).task_perf)];
        else
            block_perf = table2struct(ALLEEG(j).task_perf);
            for i = 1:length(block_perf)
                block_perf(i).TrialNum = block_perf(i).TrialNum + total_perf(end).TrialNum;
            end
            total_perf = [total_perf ; block_perf];
        end    
    end
EEG.task_perf = total_perf;
end
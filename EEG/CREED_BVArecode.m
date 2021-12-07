function EEG = CREED_BVArecode(EEG, dex_dir, gze_dir, participant_name, task_name)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This Code is designed to recode BVA-DEX data
% 1. Finds & Loads matching KINARM task 
% 2. Pulls Events from the KINARM c3d files (Codes & Labels)
% 3. Compares number of events recorded in BVA : DEX and creates new EEG.events & EEG.urevents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
if strcmp(task_name(11:14), 'APST')
cd(fullfile(gze_dir,'\2.APST.prc'))
else
cd(fullfile(dex_dir, '1.DEX.trim', [participant_name '.dex']))
%%
eegEvents = EEG.event;
kn_dat = LOADFILES.zip_load(strcat(task_name,'.zip'));

kn_dat = remove_gazecodes(kn_dat);
kn_dat = c3d_reorder(kn_dat);

TaskEvents  = [];
TaskLatency = [];
TaskNCodes  = [];
%%
if ismember(task_name(11:14), {'GNGB' 'NGGB' 'GNGR' 'NGGR'})
    time_adj = eegEvents(3).latency;
    for triali = 1:length(kn_dat)
        TrialEvents = deblank(kn_dat(triali).EVENTS.LABELS);
        TrialLatency = (1000*kn_dat(triali).EVENTS.TIMES) + time_adj;
        TrialCodes = [];
            for eventi = 1:length(TrialEvents)
                TrialCodes(eventi) = kn_dat(1).EVENT_DEFINITIONS.CODES(ismember(kn_dat(1).EVENT_DEFINITIONS.LABELS,TrialEvents(eventi)));
            end
        TaskEvents  = [TaskEvents ; TrialEvents'];
        TaskLatency = [TaskLatency ; TrialLatency'];
        TaskNCodes  = [TaskNCodes ; TrialCodes'];

        time_adj = time_adj + length(kn_dat(triali).Gaze_X);
    end

        if ismember(task_name(11:14), {'GNGB' 'NGGB'})
            EEG.task_perf = calcButtonPerformance(kn_dat, task_name(11:14));
        %
        elseif ismember(task_name(11:14), {'GNGR' 'NGGR'})
            perf = calcReachPerformance(kn_dat);
            % OVERWRITING DEFAULT PERFORMANCE CODES
            perf = struct2table(perf);
                perf.TrialReachDist(isnan([perf.TrialReachDist])) = 0;
                perf.prctReach(isnan([perf.prctReach])) = -99;
            obj_logi = ismember([perf.StimulusType], 'Target'); % 1 = TARGET
            acc_logi = zeros([height(perf) 1]);
                
                acc_logi(obj_logi & [perf.prctReach] > 80) = 1;
                
                acc_logi(~obj_logi & [perf.TrialReachDist] < 2.0) = 1;
            perf_codes = nan([height(perf) 1]);
                perf_codes(obj_logi & acc_logi)    = 24; % Correct GO TRIAL 
                perf_codes(~obj_logi & acc_logi)   = 34; % Correct NOGO TRIAL
                perf_codes(obj_logi & ~acc_logi)   = 25; % Error GO TRIAL
                perf_codes(~obj_logi & ~acc_logi)  = 35; % Error NOGO TRIAL
            perf_code_idx = find(ismember(TaskNCodes, [24 34 25 35]));
            for ci = 1:length(perf_code_idx)
                TaskNCodes(perf_code_idx(ci)) = perf_codes(ci);
                    if perf_codes(ci) == 24
                        TaskEvents{perf_code_idx(ci)} = 'Correct (GO)';
                    elseif perf_codes(ci) == 25
                        TaskEvents{perf_code_idx(ci)} = 'Error (GO)';
                    elseif perf_codes(ci) == 34
                        TaskEvents{perf_code_idx(ci)} = 'Correct (NO)';
                    elseif perf_codes(ci) == 35
                        TaskEvents{perf_code_idx(ci)} = 'Error (NO)';
                    end
            end
            EEG.task_perf = perf;
        end
    
%%   
elseif ismember(task_name(11:14), {'GNGC' 'NGGC'})
    [~, hit_matrix, task_length] = gen_continuous_data (kn_dat);
    [gngc_eventcodes] = gen_gngc_events(hit_matrix, task_length);
    TrialEvents  = deblank(kn_dat.EVENTS.LABELS);
    TrialLatency = kn_dat.EVENTS.TIMES*1000;
        if strcmp(TrialEvents(1), 'TASK_BUTTON_10_CLICKED') && length(unique([eegEvents.latency]) == 3)
            TaskEvents = [TrialEvents(2); gngc_eventcodes.Label; TrialEvents(end)];
            TaskNCodes = [235; gngc_eventcodes.Code; 135];
            if length(unique([eegEvents.latency])) < 3
                disp(unique([eegEvents.latency]));
%                 keyboard;
%                     clc;
                TaskLatency= [TrialLatency(2); gngc_eventcodes.Time; TrialLatency(end)] + (eegEvents(3).latency - (task_length*5));
            else
                TaskLatency = [TrialLatency(2); gngc_eventcodes.Time; TrialLatency(end)] + (eegEvents(3).latency);
            end
        else
            keyboard;
        end
    EEG.task_perf = hit_matrix;
%% LEGACY %%
% elseif strcmp(task_name(11:14), 'APST')
%     t2t_offset = '250';
%     KN_TaskEventTimes(1) = eegEvents(3).latency;
%     KN_TaskEventCode(1) = event_defs.CODES(find(strcmp(KN_trialeventLabels(1),event_defs.LABELS)));
%         for event_i = 2:length(KN_trialeventLabels)
%             if strcmp(KN_trialeventLabels(event_i), 'Hand Still') && strcmp(KN_trialeventLabels(event_i-1), 'End_Trial')
%                 KN_TaskEventTimes(event_i) = KN_TaskEventTimes(event_i - 1) + eval(t2t_offset);
%             else
%                 KN_TaskEventTimes(event_i) = KN_TaskEventTimes(event_i - 1) + KN_TimeDiff(event_i);
%             end
%         try
%             KN_TaskEventCode(event_i) = event_defs.CODES(find(strcmp(KN_trialeventLabels(event_i),event_defs.LABELS)));
%         catch
%             KN_TaskEventCode(event_i) = event_defs.CODES(find(strcmp(' Target On (Pro)',event_defs.LABELS))); % Weird space in event code is throwing off strcmp
%         end
%         end
%%            
elseif strcmp(task_name(11:14), 'PRVT')
    TaskEvents = deblank(kn_dat.EVENTS.LABELS);
    for event_i = 1:length(TaskEvents)
        TaskNCodes(event_i) = kn_dat.EVENT_DEFINITIONS.CODES(find(ismember(kn_dat.EVENT_DEFINITIONS.LABELS, TaskEvents(event_i))));
    end
    TaskLatency = KN_trialeventTimes + eegEvents(3).latency;
    
elseif strcmp(task_name(11:14), 'RHRV')
        TaskEvents = deblank(kn_dat.EVENTS.LABELS)';
        TaskNCodes = [199 ; 99]; % Task Start : Task End
        unLat = unique([eegEvents.latency]);
        if length(unLat) > 3 || unLat(1) ~= 1
            fprintf('Event Code Issues \n');
            keyboard;
        else
            TaskLatency = unLat(2:3)';
        end        
end    
                                                %       KINARM      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                       Continue to Build NEW EEG Events Table                                             % 
%                                                                                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                %    Build Table    %

knEvent_tbl1 = table('Size', [length(TaskNCodes) 8], 'VariableType', {'double', 'double', 'double', 'double', 'double', 'string', 'string', 'double'},...
    'VariableNames',{'latency', 'duration', 'channel', 'bvtime', 'bvmknum', 'type','code', 'urevent'});
    task_length = length(TaskNCodes);
knEvent_tbl1.latency = [TaskLatency];
knEvent_tbl1.duration = ones(task_length,1);
knEvent_tbl1.channel = zeros(task_length,1);
% knEvent_tbl1.bvtime = [];
knEvent_tbl1.bvmknum = [1:task_length]';
knEvent_tbl1.type = [TaskNCodes];
knEvent_tbl1.code = string(TaskEvents);
knEvent_tbl1.urevent = [1:task_length]';

knEvent_tbl2 = knEvent_tbl1(:,1:6);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EEG.event = table2struct(knEvent_tbl1)';
EEG.urevent = table2struct(knEvent_tbl2)';
               
if ~isequal(size(EEG.event,2), size(EEG.urevent,2))
    keyboard
end
end


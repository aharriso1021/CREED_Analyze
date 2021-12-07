function ReachTrialPerf = calcReachPerformance(data_in)
%% Pre-processing of ARM MOVEMENT data 
try
    data_in = data_in.c3d;
catch 
    data_in = data_in;
end

try
    data = KINARM.KINARM_add_hand_kinematics(data_in); % adds hand acceleration & velocity data to structure
catch
    error('Unable to locate KINARM directory to add hand kinematics, be sure it is in path')
end
try 
    data_filt = FILTER.filter_double_pass(data, 'enhanced', 'fc', 20); % applies filter to kinematic data
    clearvars data data_in
catch 
    error('Unable to locate FILTER directory, be sure it is in the path')
end
%% 

%% 
ReachTrialPerf =  genVariableStruct(data_filt);
end

% Create Supplemental Structure for the REACH variant that can be used later for 2ndary variable calculations
function VariableStruct = genVariableStruct(data)

VariableStruct = struct('TrialNumber', [], 'StimulusType', {}, 'ObjectCoordinates', [],'TrialAccuracy', [], 'TrialRT', [], 'TrialReachDist', [], 'prctReach', [],...
    'TrialTimeStamps', [], 'TrialEvents', {}, 'TrialHandPosXY', [], 'TrialHandVelXY', [], 'TrialHandAccXY', []);
VariableStruct = repmat(VariableStruct, [length(data), 1]);

% FOR LOOP to extract variables 
for trial_idx = 1:length(data)
VariableStruct(trial_idx).TrialNumber = data(trial_idx).TRIAL.TRIAL_NUM;
if data(trial_idx).TP_TABLE.Trial_Type(data(trial_idx).TRIAL.TP_ROW)== 1 % Trial Type: 1 (TARGET) 2 (DISTRACTOR)
    VariableStruct(trial_idx).StimulusType = 'Target';
elseif data(trial_idx).TP_TABLE.Trial_Type(data(trial_idx).TRIAL.TP_ROW)== 2
    VariableStruct(trial_idx).StimulusType = 'Distractor';
end
if ~isempty(find(ismember(deblank(data(trial_idx).EVENTS.LABELS), {'Correct (GO)' 'Correct (NO)'}))) % Accuracy (as calculated by task) can overwrite later
    VariableStruct(trial_idx).TrialAccuracy = 1;
elseif ~isempty(find(ismember(deblank(data(trial_idx).EVENTS.LABELS), {'Error (GO)' 'Error (NO)'})))
    VariableStruct(trial_idx).TrialAccuracy = -1;
else
    VariableStruct(trial_idx).TrialAccuracy = 0;
end
    ObjLocList = [data(trial_idx).TARGET_TABLE.X data(trial_idx).TARGET_TABLE.Y]; %Object Location XY Coordinates from TargetTable
VariableStruct(trial_idx).ObjectCoordinates = ObjLocList(data(trial_idx).TP_TABLE.Target_Row(data(trial_idx).TRIAL.TP_ROW),:); %Pulling XY of Trial OBJECT
    TrialTimes = 1:1:length(data(trial_idx).Gaze_TimeStamp);
VariableStruct(trial_idx).TrialTimeStamps = TrialTimes';
    ECodes = deblank(data(trial_idx).EVENTS.LABELS);
    ETimes = data(trial_idx).EVENTS.TIMES*1000; %converting Event Time Stamps into ms
    TrialECStamps = repmat("empty", [length(TrialTimes) 1]);
    TrialECStamps(TrialTimes(int32(ETimes))) = ECodes;
VariableStruct(trial_idx).TrialEvents = TrialECStamps;
    if strcmp(data(1).EXPERIMENT.ACTIVE_ARM, 'RIGHT')
        active_arm = 'Right';
    elseif strcmp(data(1).EXPERIMENT.ACTIVE_ARM, 'LEFT')
        active_arm = 'Left';
    end
%% Trial Kinematic Information - save in file for later use %% 
VariableStruct(trial_idx).TrialHandPosXY = ([data(trial_idx).(strcat(active_arm, '_HandX')) data(trial_idx).(strcat(active_arm, '_HandY'))]) * 100; %% cm 
VariableStruct(trial_idx).TrialHandVelXY = (hypot(data(trial_idx).(strcat(active_arm, '_HandXVel')),data(trial_idx).(strcat(active_arm, '_HandYVel')))) * 100; %% cm/s
VariableStruct(trial_idx).TrialHandAccXY = (hypot(data(trial_idx).(strcat(active_arm, '_HandXAcc')),data(trial_idx).(strcat(active_arm, '_HandYAcc')))) * 100; %% cm/s^2       
%%

%% Computing RT/Reach Distance/Error Magnitude %% 
if ~isempty(find(ismember(deblank(data(trial_idx).EVENTS.LABELS), {'Correct (GO)' 'Error (NO)'}))) % Calculating RT for CORRECT responses and COMISSION errors
    objON_idx = find(ismember(VariableStruct(trial_idx).TrialEvents, {'Target_ON (GO)' 'Target_ON (NO)'}));
    reachON_idx = find(ismember(VariableStruct(trial_idx).TrialEvents, {'Correct (GO)' 'Error (NO)'}));
VariableStruct(trial_idx).TrialRT = VariableStruct(trial_idx).TrialTimeStamps(reachON_idx) - VariableStruct(trial_idx).TrialTimeStamps(objON_idx);
%% Calculating REACH DISTANCE & PCT MAX variables %%%%%% 
%  Includes Y-coordinate offset == global coordinate system of handpos
    TargLoc = [VariableStruct(trial_idx).ObjectCoordinates] + [0 10]; % Y-offset
    [~,MaxReach_idx] = max(VariableStruct(trial_idx).TrialHandPosXY(:,2)); % index of max hand path dist (y-coord)
    maxDist = hypot(TargLoc(1) + -(VariableStruct(trial_idx).TrialHandPosXY(objON_idx,1)),...
        TargLoc(2) - VariableStruct(trial_idx).TrialHandPosXY(objON_idx,2)); % Calc Hand - Target dist (@ TargOn)
    reachDist = hypot(VariableStruct(trial_idx).TrialHandPosXY(MaxReach_idx,1) + -(VariableStruct(trial_idx).TrialHandPosXY(objON_idx,1)),...
        VariableStruct(trial_idx).TrialHandPosXY(MaxReach_idx,2) - VariableStruct(trial_idx).TrialHandPosXY(objON_idx,2));% Max distance to Target reached
VariableStruct(trial_idx).TrialReachDist = reachDist; % Total distance from start reached (cm)
VariableStruct(trial_idx).prctReach = (reachDist/maxDist)*100; % Proportion of distance to target reached (%)
else
    VariableStruct(trial_idx).TrialRT = NaN;
    VariableStruct(trial_idx).TrialReachDist = NaN; 
    VariableStruct(trial_idx).prctReach = NaN;
end

end
end
function CREEDhrvRed = CREED_hrvReduct(task)
%%
addpath(genpath('F:\DATA\CREED_ParticipantData\')); 

%DEXdir_dataIN= uigetdir;
%DEXdir_dataOUT= uigetdir;

DEXdir_dataIN = 'F:\DATA\CREED_ParticipantData\DEX\1.DEX.trim';
HRVdir_dataOUT = 'F:\DATA\CREED_ParticipantData\HRV';
    cd(HRVdir_dataOUT)
    if ~exist(task, 'dir')
        mkdir(task); addpath(task);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd(DEXdir_dataIN)
dexFiles = dir('*.dex');
partFiles = char({dexFiles.name});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for partIDX = 1:length(partFiles)
    if ~exist(strcat(partFiles(partIDX,1:9), '_', task, '.mat'),'file')
        cd(partFiles(partIDX,:))
            subjFiles = dir('*.zip');
            taskFiles = char({subjFiles.name});
       HRVstruct = [];
            fileIDX = find(ismember(string(taskFiles(:,11:14)), task));
            for procIDX = 1:length(fileIDX)
                hrv_struct = struct('Trial', [], 'EKG_dat', [], 'TrialClock', [], 'RRidx', [], 'RRamp', [], 'RRlat', []);
                hrv_struct.Trial = str2num(taskFiles(fileIDX(procIDX),16));
                knDat = LOADFILES.zip_load(taskFiles(fileIDX(procIDX),:));
                    knDat = c3d_reorder(knDat);
                    [knDat, ~] = remove_gazecodes(knDat);
                    ecg_dat = knDat.c3d.EKG;
                    sRate = knDat.c3d.ANALOG.RATE;
                [filtDat, trialClk, peak_idx, peakAmp, peakLat, Rpeaks, Rlocs] = find_Rpeaks(ecg_dat, sRate, []);
            end    
     
    end

end
end
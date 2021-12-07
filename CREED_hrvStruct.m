function CREEDhrvRed = CREED_hrvReduct
hrv_dir = 'D:\DATA\CREED_ParticipantData\DEX\3.rHRV.proc';
% hrv_dir = uigetdir;

cd(hrv_dir)
dir_files = dir('*.mat');
part_names = char({dir_files.name});



for part_Idx = 1:size(part_names,1) 
% if ~ismember(part_names(1:9), CREEDhrv_summary.ID)   
    hrv_data = load(part_names(part_Idx,:));
    for
end

end
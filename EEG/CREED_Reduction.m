function  EEG = CREED_Reduction(EEG, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    Standard Post-ICA Processing of EEG/ERP Data                   %
% 1. ID eye-blink related IC's to remove artifacts (icablinkmetrices)               %
% 2. Interpolate any bad channels/data segments                                     %
% 3. Re-reference (DEFAULT = whole head)                                            %
% --------------------------------------------------------------------------------- %
% (Inputs)                                                                          %
%    i. EEG = EEG data (must have calculated ICA weights                            %
%   ii. wrk_dir = core directory for stored EEG data                                %
% (Optional)                                                                        % 
%  iii. ArtifactChannels = array of channels that may contain eyeblink artifacts    % 
%           Default: VEOG                                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(varargin)
   temp = struct(varargin{:}); 
end

try, temp.ArtifactChannels; catch, temp.ArtifactChannels = 'VEOG'; end
% Restore Bipolar eye channels for component comparisions 
EEG = movechannels(EEG, 'Direction', 'Restore', 'Channels', {'HEOG', 'VEOG'});

iChannel = find(ismember({EEG.chanlocs.labels}, {temp.ArtifactChannels})); 
% Identify eye-blink components (Pontifex et al Psychophys 2017) == addd in another run to ID Horizontal components
EEG.ic_mets= [];
for chan_i = 1:length(iChannel)
    try 
        ic_mets = icablinkmetrics(EEG, 'ArtifactChannel', EEG.data(iChannel(chan_i), :)); 
    catch
        ic_mets = [];
    end
    EEG.ic_mets = [EEG.ic_mets ; ic_mets];
end
% Remove ID'd component
EEG.ics_removed = unique([EEG.ic_mets.identifiedcomponents]);
if ~isempty(EEG.ics_removed > 0)
    EEG = pop_subcomp(EEG, EEG.ics_removed(find(EEG.ics_removed > 0)), 0);
end
% Remove BiPolar Channels & Interpolate any MISSING/BAD Channels 
EEG = movechannels(EEG, 'Direction', 'Remove', 'Channels', {'HEOG', 'VEOG'});
% chanset = complete 64 channel cap (-FCz [ref] and EOG channels)
chanset = {'Fp1' ,'Fz'  ,'F3'  ,'F7'  ,'FC5' ,'FC1' ,'C3'  ,'T7'  ,'CP5' ,'CP1' ,'Pz'  ,'P3'  ,...
           'P7'  ,'O1'  ,'Oz'  ,'O2'  ,'P4'  ,'P8'  ,'CP6' ,'CP2' ,'Cz'  ,'C4'  ,'T8'  ,'FC6' ,...
           'FC2' ,'F4'  ,'F8'  ,'Fp2' ,'AF7' ,'AF3' ,'AFz' ,'F1'  ,'F5'  ,'FT7' ,'FC3' ,'C1'  ,'C5'  ,'TP7',...
           'CP3' ,'P1'  ,'P5'  ,'PO7' ,'PO3' ,'POz' ,'PO4' ,'PO8' ,'P6'  ,'P2'  ,'CPz' ,'CP4' ,'TP8' ,'C6' ,...
           'C2'  ,'FC4' ,'FT8' ,'F6'  ,'AF8' ,'AF4' ,'F2'
           }; % 'TP10','TP9' ,'FT9' ,'FT10',
EEG = interpolate1010electrodearray(EEG, 'Array', chanset); 

% Re-Ref to WHOLE HEAD & Add back FCz (online reference)
EEG = pop_reref(EEG, [],'refloc',struct('labels',{'FCz'},'type',{''},'theta',{0},'radius',{0.12662},'X',{32.9279},'Y',{0},'Z',{78.363},'sph_theta',{0},...
           'sph_phi',{67.208},'sph_radius',{85},'urchan',{64},'ref',{'FCz'},'datachan',{0}));    
end
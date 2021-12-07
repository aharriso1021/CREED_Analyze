function [EEG, pol_inv] = CREED_PreICAcleaning(EEG, pol_check, prm)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%          Standard Preprocessing Steps for EEG data --> Prepare for ICA                 %   
% To Be Completed following Event Recoding Steps & Prior to ICA artifact correction      %
% Inputs                                                                                 %
%  EEG             = current loaded EEG dataset                                          %
%  'OnlineRef'     = Online Ref Electrode (def: FCz)                                     %
%  'nChan'         = number of recorded EEG channels (def: 64)                           %
%  'FilterDesign   = filter type ['Highpass'  | 'Lowpass' | 'Bandpass' (def)]            %
%  'loCutt'        = LOW END frequency cutoff (def: [1.0])                               %
%  'hiCutt'        = HIGH END frequency cutoff (def: [30.0])                             %
% Output                                                                                 %
%  EEG_forICA      = pre-processed dataset ready for ICA artifact decomposition          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%

% Load Channel Locations
if ispc
    chanloc_file = [prm.drvr '\MATLAB\eeglab\plugins\dipfit3.7\standard_BESA\standard-10-5-cap385.elp']; %% IF ERROR BELOW CHECK FILE PATH
elseif isunix
    chanloc_file = '/Volumes/HARRISON_TB/MATLAB/eeglab/plugins/dipfit3.7/standard_BESA/standard-10-5-cap385.elp';
end

try
    EEG = pop_chanedit(EEG, 'lookup', chanloc_file);
catch
    disp('Check Error in locating chanl_loc file and re-run before continuing')
    keyboard;
end

% Trim Data for ICA decomp
if prm.datatrim == 1
EEG = simpletrim(EEG, 'Pre', 1, 'Post', 1); 
end

% Remove Bipolar channels prior to badchannel ASR
EEG = movechannels(EEG, 'Location', 'skipchannels', 'Direction', 'Remove', 'Channels', {'HEOG', 'VEOG'});

% Remove Peripheral channels that may interfere with cleaning
if ~isempty(prm.KillChanID)
EEG = movechannels(EEG, 'Location', 'skipchannels', 'Direction', 'Remove', 'Channels', prm.KillChanID);
end

% Tweak to check polarity of VEOG channels for ICAMetrics (incase of mix up in set up)
if ~isempty(pol_check) && pol_check== 1
    EEG = polarityCheck(EEG);
    pol_inv = pol_check;
elseif isempty(pol_check)
    [EEG, pol_ch] = polarityCheck(EEG);
    pol_inv = pol_ch;
elseif ~isempty(pol_check) && pol_check== 0
    pol_inv = pol_check;    
end


% Butterworth bandpass filter == CHANGE TO pop_filtnew
if strcmpi(prm.FilterDesign, 'HighPass')
    EEG = simpleEEGfilter(EEG, 'Filter', prm.FilterDesign, 'Design', 'Windowed Symmetric FIR', 'Cutoff', [prm.hp], 'Order', (3*fix(EEG.srate/0.5)));
elseif strcmpi(prm.FilterDesign, 'BandPass')
    EEG = simpleEEGfilter(EEG, 'Filter', prm.FilterDesign, 'Design', 'Windowed Symmetric FIR', 'Cutoff', [prm.hp, prm.lp], 'Order', (3*fix(EEG.srate/0.5)));
else
end

% CLEANLINE Noise if NECESSARY
if prm.lp > 55
    EEG = pop_cleanline(EEG,...
                            'bandwidth', 2,...
                            'chanlist', [1:EEG.nbchan],...
                            'computepower', 1,...
                            'linefreqs', [60 120 240],...
                            'normSpectrum', 0,...
                            'p', 0.01,...
                            'pad', 2,...
                            'pad',2,...
                            'plotfigures',0,...
                            'scanforlines',1,...
                            'sigtype','Channels',...
                            'taperbandwidth',2,...
                            'tau',100,...
                            'verb',1,...
                            'winsize',4,...
                            'winstep',1);
else
end
clc;

EEG.original_chanlocs = EEG.chanlocs; % Saving original channel location data to use for later interpol (after ICA)

EEG.rec_info = cell2table(EEG.rec_info,"VariableNames", {'ChannelLabel' 'ChannelImp'});
EEG.rec_info.ChannelLabel = erase(string(EEG.rec_info.ChannelLabel), ':');

if ~isempty(find(ismember(EEG.rec_info.ChannelLabel(EEG.rec_info.ChannelImp > 15), {EEG.chanlocs.labels})))
    chx = {EEG.chanlocs(ismember({EEG.chanlocs.labels}, EEG.rec_info.ChannelLabel(EEG.rec_info.ChannelImp > 15))).labels};
    EEG = pop_select(EEG, 'nochannel', chx);
        EEG = letterkilla(EEG);
end


warning off

if prm.ASRclean == 1
fprintf('################################################################################\n\n');
fprintf('COMPUTING ARTIFACT SUBSPACE RECON\n\n');
fprintf('################################################################################\n\n'); 

    EEG = clean_artifacts(EEG,...
                'ChannelCriterion', 0.85,...
                'LineNoiseCriterion', 4,...
                'BurstCriterion', 5,...
                'WindowCriterion', 0.275,...
                'Highpass', [],...
                'FlatlineCriterion', 5,...
                'BurstRejection', 'off',...
                'Distance', 'Euclidian',...
                'MaxMem', 256);
else
fprintf('################################################################################\n\n');
fprintf('DETECTING BAD CHANNELS\n\n');
fprintf('################################################################################\n\n');     
    
    badchannels = catchbadchannels(EEG, 'LineNoise', 20, 'Smoothed', 20, 'PointByPoint', 20, 'Trim', 2);
    if ~isempty(badchannels)
        EEG = pop_select(EEG, 'nochannel', badchannels);
        EEG = letterkilla(EEG);
    end
end

end
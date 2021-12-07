function [EEG, pol_inv] = CREED_PreProcessing(EEG, chan_locfile, pol_check, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%          Standard Preprocessing Steps for EEG data --> Prepare for ICA            %   
% To Be Completed following Event Recoding Steps & Prior to ICA artifact correction %
% Inputs                                                                            %
%  wrk_driver = driver locating ALL custom functions and EEGLAB pluggins            %
%  EEG        = current loaded EEG dataset                                          %
%  'OnRef'    = Online Ref Electrode (def: FCz)                                     %
%  'nChan'    = number of recorded EEG channels (def: 64)                           %
%  'FiltDes   = Filter Design ['Windowed Symmetric FIR  | 'IIR Butterworth' (def)]  %
%  'Filt'     = filter type ['Highpass'  | 'Lowpass' | 'Bandpass' (def)]            %
%  'Freq'     = frequency cutoffs (def: [1.0 30.0])                                 %
% Output                                                                            %
%  EEG_forICA = pre-processed dataset ready for ICA artifact decomposition          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(varargin)
    temp = struct(varargin{:});
end
    try, temp.OnRef;   catch, temp.OnRef = 'FCz'; end
    try, temp.nChan;   catch, temp.nChan = 64; end
    try, temp.FiltDes; catch, temp.FiltDes = 'Windowed Symmetric FIR'; end
    try, temp.Filt;    catch, temp.Filt = 'Bandpass'; end
    try, temp.Freq;    catch, temp.Freq = [1.0 30.0]; end
% Load Channel Locations
% EEG = pop_chanedit(EEG, 'lookup', chan_locfile, 'insert', temp.nChan, 'changefield',{temp.nChan 'labels' temp.OnRef}, 'lookup', chan_locfile, 'setref', {['1:' num2str(temp.nChan)], temp.OnRef});

% Trim Data for ICA decomp
EEG = simpletrim(EEG, 'Pre', 2, 'Post', 2); 

% Butterworth bandpass filter 
EEG = simpleEEGfilter(EEG, 'Filter', temp.Filt, 'Design', temp.FiltDes, 'Cutoff', temp.Freq, 'Order', 3*fix(EEG.srate/0.5));

% Tweak to check polarity of VEOG channels for ICAMetrics (incase of mix up in set up)
if ~isempty(pol_check) && pol_check== 1
    EEG = EEG.polarityCheck(EEG);
    pol_inv = pol_check;
elseif isempty(pol_check)
    [EEG, pol_ch] = EEG.polarityCheck(EEG);
    pol_inv = pol_ch;
elseif ~isempty(pol_check) && pol_check== 0
    pol_inv = pol_check;    
end
% Remove Bipolar channels prior to badchannel ASR
EEG = movechannels(EEG, 'Direction', 'Remove', 'Channels', {'HEOG', 'VEOG'});

% Remove Peripheral channels that may interfere with cleaning
EEG = movechannels(EEG, 'Direction', 'Remove', 'Channels', {'TP9', 'FT9', 'TP10', 'FT10'});

% ID Bad Channels = clean_rawdata for bad channel ID only
% EEG = clean_rawdata(EEG, -1, [-1], 0.85, -1, 12, -1);
EEG.badlocs = catchbadchannels(EEG, 'LineNoise', 20, 'Smoothed', 20, 'PointByPoint', 20, 'Trim', 2, 'Skip', { 'HEOG', 'VEOG' });
    if ~isempty(EEG.badlocs)
        % Removes Previously ID'd bad channels from Dataset
        EEG = pop_select(EEG, 'nochannel', EEG.badlocs);
        EEG = letterkilla(EEG);
    end
end
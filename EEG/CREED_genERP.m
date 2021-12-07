function AvgERPs = CREED_genERP(EEG, bdf_path, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              Standard Epoching Steps for either stim/resp lock ERPs               %
%               ** Default settings Optimized for STIM LOCKED ERPS**                %
% Inputs:                                                                           %
%   ALLEEG   = structure containing ALL similar TASK files for the participant      %
%   bdf_path  = path to bdf                                                         %
% (Optional)                                                                        %
%   EpRange  = Epoch window (def: [-100 : 10000])                                   %
%   Baseline = Baseline Window (def: [-100 : 0])                                    %
%   Volt     = [MIN - MAX] voltage threshold for artif rej                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(varargin)
   temp = struct(varargin{:}); 
end
    try, temp.LockType; catch, temp.LockType = 'Stimulus';   end
    try, temp.EpRange;  catch, temp.EpRange = [-100 : 1000]; end
    try, temp.Baseline; catch, temp.Baseline = [-100 0];     end
    try, temp.Volt;     catch, temp.Volt = [-100 100];       end
    
% Generate Eventlist from EEG file 
EEG  = pop_creabasiceventlist(EEG, 'AlphanumericCleaning', 'on', 'BoundaryNumeric', {-99}, 'BoundaryString', {'boundary'});
% Seperate continuous data into BINS defined by .bdf
EEG  = pop_binlister( EEG , 'BDF', bdf_path, 'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput', 'EEG' );
% Seperate continuous data into EPOCHS & sync artifacts
EEG = pop_epochbin( EEG , temp.EpRange, temp.Baseline);
    if strcmp(temp.LockType, 'Response')
        EEG = simpleEEGfilter(EEG, 'Filter', 'LowPass', 'Design', 'Windowed Symmetric FIR', 'Cutoff', 12, 'Order', 3*fix(EEG.srate/0.5));
    end
% Run voltage threshold to catch final artifacts
EEG = pop_artextval(EEG, 'Channel', 1:EEG.nbchan, 'Flag', 1, 'Threshold', temp.Volt, 'Twindow', [temp.EpRange(1) , temp.EpRange(2)-1]);
% Average BINS
AvgERPs = pop_averager(EEG, 'Criterion', 'good', 'ExcludeBoundary', 'on', 'SEM', 'on');
end
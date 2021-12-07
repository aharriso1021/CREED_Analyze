function data_out = CREED_ERPtopo_inspection(EEG)
%% Visually inspect avg ERP at each channel location 
% Identify possible noisy channels, remove, and re-reference
%% 
xch_list = [];
ch_inspect = 1;

while ch_inspect == 1
figure;
%% Define PLOT OPTIONS:
options = {'chanlocs' EEG.chanlocs 'frames' EEG.pnts 'limits' [EEG.xmin EEG.xmax 0 0]*1000 ...
    'chans' 1:EEG.nbchan 'ydir' -1 'title' [EEG.subject '-' EEG.condition EEG.session]};
    xch = [];
    plottopo(mean(EEG.data,3), options{:});
    % pop_prop( EEG, 1, 30, NaN, {'freqrange',[2 50] });
    uiCh = input('Select noisy channel(s) to remove: (leave empty if none desired) ', 's');
    if ~isempty(uiCh) 
        xch = split(uiCh);
        EEG = pop_simpleremovechannel(EEG, 'Channels', xch);
        if strcmp(EEG.ref, 'average')            
            EEG = pop_reref(EEG, []);
        else
            error('Unrecognized reference format')
        end      
    else
        ch_inspect = 0;
    end
    
end
% EEG.
data_out = EEG;
end
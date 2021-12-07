function [EEG, pol_ch] = polarityCheck(EEG)
veCh = find(ismember({EEG.chanlocs.labels}', 'VEOG'));
[vePk, Pki] = max(abs(EEG.data(veCh,:)));
    if isnegative(EEG.data(veCh,Pki))
        EEG.data(veCh,:) = -(EEG.data(veCh,:));
        pol_ch = 1;
    else
        pol_ch = 0;
    end 
end
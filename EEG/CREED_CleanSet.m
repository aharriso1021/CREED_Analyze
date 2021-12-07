function [EEG, xRest] = CREED_CleanSet(EEG, prm, xRest)
% Channel Removal
% xCh = {};
% EEG = movechannels(EEG, 'Location', 'skipchannels', 'Direction', 'Remove', 'Channels', xCh);
%     EEG.original_chanlocs(ismember({EEG.original_chanlocs.labels}, xCh)) = [];
% Blink/Non-brain IC removal
EEG = pop_iclabel(EEG, 'default');
    iclabel = EEG.etc.ic_classification.ICLabel;
        for ci = 1:length(iclabel.classifications)
            [class_mx(ci,2), class_mx(ci,1)] = max(iclabel.classifications(ci,:));
        end 
    ncomps   = 1:length(class_mx);    
        brn_comp = find(class_mx(:,1) == 1 & class_mx(:,2) > 0.51); %prm.icthresh);
        rej_comp = setdiff(ncomps,brn_comp);
    
    EEG.etc.ic_classification.ICLabel.BCs = brn_comp;  
    EEG.etc.ic_classification.ICLabel.NBCs = rej_comp; 
%     spot_check = randi(100,1);
%         if spot_check > 75
%             pop_viewprops(EEG, 0, [1:EEG.nbchan], {'freqrange', [2,80]}, {}, 1, 'ICLabel');
%             keyboard;
%         end        
        clc;
    fprintf('################################################################################\n\n');
    fprintf('REMOVING NON-BRAIN ICs \n\n');
    fprintf('################################################################################\n\n');
    EEG.og_data = EEG.data;    
    EEG = pop_subcomp(EEG, rej_comp);
        
% Channel Interpolation
EEG = pop_interp(EEG, EEG.original_chanlocs, 'spherical');
        clc;
    fprintf('################################################################################\n\n');
    fprintf('INTERPOLATING REMOVED CHANNELS \n\n');
    fprintf('################################################################################\n\n');
    
% Re-Reference, compute FCz, & add FCz into data [COMPUTE AVG channel for
% RHRV) 

nch = EEG.nbchan;
    if ispc
        chanloc_file = [prm.eeglabdir,'\plugins\dipfit3.7\standard_BESA\standard-10-5-cap385.elp'];
    elseif isunix
        chanloc_file = [prm.eeglabdir,'/plugins/dipfit3.7/standard_BESA/standard-10-5-cap385.elp'];
    end
% 
% [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
if strcmp(EEG.condition, 'RHRV')
    if ischar(EEG.session)
        xRest{str2double(EEG.session)} = mean([EEG.data],1);
    elseif isnumeric(EEG.session)
        xRest{EEG.session} = mean([EEG.data],1);
    end
    EEG.xRest = mean([EEG.data],1);
    EEG = pop_chanedit(EEG, 'insert', nch+1, 'changefield', {nch+1,'labels','FCz'}, 'lookup', chanloc_file, 'setref',{['1:' num2str(nch)],'FCz'});
    EEG = pop_reref(EEG, [],'refloc',struct('labels',{'FCz'},'type',{''},'theta',{0},'radius',{0.12662},'X',{32.9279},'Y',{0},'Z',{78.363},'sph_theta',{0}, 'sph_phi',{67.208},'sph_radius',{85},'urchan',{nch+1},'ref',{'FCz'},'datachan',{0}));

else
% EEG = eeg_checkset( EEG );
% EEG = pop_reref(EEG, [],'refloc',struct('labels',{'FCz'},'type',{''},'theta',{0},'radius',{0.12662},'X',{32.9279},'Y',{0},'Z',{78.363},'sph_theta',{0},'sph_phi',{67.208},'sph_radius',{85},'urchan',{2},'ref',{''},'datachan',{0}));
    EEG = pop_chanedit(EEG, 'insert', nch+1, 'changefield', {nch+1,'labels','FCz'}, 'lookup', chanloc_file, 'setref',{['1:' num2str(nch)],'FCz'});
    EEG = pop_reref(EEG, [],'refloc',struct('labels',{'FCz'},'type',{''},'theta',{0},'radius',{0.12662},'X',{32.9279},'Y',{0},'Z',{78.363},'sph_theta',{0}, 'sph_phi',{67.208},'sph_radius',{85},'urchan',{nch+1},'ref',{'FCz'},'datachan',{0}));
% EEG = pop_reref( EEG, 42,'refloc',struct('labels',{'FCz'},'type',{''},'theta',{0},'radius',{0.12662},'X',{32.9279},'Y',{0},'Z',{78.363},'sph_theta',{0},'sph_phi',{67.208},'sph_radius',{85},'urchan',{42},'ref',{''},'datachan',{0},'sph_theta_besa',{22.792},'sph_phi_besa',{90}));
end

clc;
    fprintf('################################################################################\n\n');
    fprintf('DATA HAS BEEN RE-REF & FCz ADDED TO CH LIST \n\n');
    fprintf('################################################################################\n\n');

% Compute Surface Laplacian
if prm.calcCSD == 1
clc; 
    fprintf('################################################################################\n\n');
    fprintf('COMPUTING SURFACE LAPLACIAN \n\n');
    fprintf('################################################################################\n\n');
    if isempty(prm.mont_path)
        mont_path = which('10-5-System_Mastoids_EGI129.csd');
    else
        mont_path = prm.mont_path;
        
    end
    [EEG.csd, EEG.slap] = laplacian_CSD(EEG, mont_path);
end % End LAPL check

if prm.calcINF == 1
clc; 
    fprintf('################################################################################\n\n');
    fprintf('COMPUTING INFINITY REF \n\n');
    fprintf('################################################################################\n\n');
    % 
    EEG.infref = CREED_REST_reref(EEG);
end

end
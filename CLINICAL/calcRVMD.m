function [RVMDvars, PCScat] = calcRVMD(datain)
%% Calculate RPQ variables (including subscores from Potter et al. 2006)

PCScat = gen_PCScats(datain(~isnan(datain)));
RVMDvars = calc_RVMDvars(datain(~isnan(datain)));

end

function RVMDvars = calc_RVMDvars(data)
RVMDvars.raw = data;
RVMDvars.Total = sum(data);
RVMDvars.RPQ3 = sum(data(1:3));
RVMDvars.RPQ13 = sum(data(4:16));

% Subscales
RVMDvars.Somatic = (data(1)*0.64) + (data(2) * 0.7) + (data(3) * 0.5) + ...
    (data(4) * 0.61) + (data(5) * 0.67) + (data(6) * 0.76) + (data(13) * 0.43) + (data(14) * 0.61);
RVMDvars.Cognitive = (data(10) * 0.87) + (data(11) * 0.80) + (data(12) * 0.87);
RVMDvars.Emotional = (data(7) * 0.83) + (data(8) * 0.75) + (data(9) * 0.84) + (data(16) * 0.75);

end

function PCScat = gen_PCScats(data)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Uses various different PCS classifier strategies found in Voormolen et al 2018        %
% to identify participants with persisting symptoms                                     %
%     1 = Participant is defined as 'PCS' by strategy                                   %
%     0 = Participant is defined as 'Non-PCS' by strategy                               %      
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

RPQ16 = data(:);
RPQ03 = data(1:3);
DSM05 = data([1 2 5 6 7 10 11]);

%1. RPQ Total Score
if  sum(find([RPQ16] >= 2)) >= 12
    PCScat.PCSrpq16 = 1;
else
    PCScat.PCSrpq16 = 0;
end
% RPQ 3 Score
if ~isempty(find([RPQ03] >= 2))
    PCScat.PCSrpq03 = 1;
else
    PCScat.PCSrpq03 = 0;
end
% DSM-5/ICD-10 Mapped Symptoms
if sum([DSM05] >= 2) >= 3
    PCScat.PCSdsm05 = 1;
else
    PCScat.PCSdsm05 = 0;
end    
end
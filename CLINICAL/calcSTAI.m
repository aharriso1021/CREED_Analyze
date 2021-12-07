function STAIvars = calcSTAI(datain, scoring_tbl)
st_anx = datain(~isnan(datain(:,1)));
tr_anx = datain(~isnan(datain(:,2)));
STAIvars = struct();
if isempty(find(st_anx == -99))
    %% Re-tab STATE anxiety with scoring sheet
    for si = 1:length(st_anx)
        [STAIvars.STArecal(si)] = scoring_tbl.State(si,st_anx(si));
    end
    %% Calculating STATE score from re-calculated 
    STAIvars.STanx_score = sum([STAIvars.STArecal]);
else                                                % Twist if participant failed to complete
    STAIvars.STanx_score = -99;
end
if isempty(find(tr_anx == -99))    
    %% Re-tab TRAIT anxiety with scoring sheet
    for ti = 1:length(tr_anx)
        [STAIvars.TRArecal(ti)] = scoring_tbl.Trait(ti,tr_anx(ti));
    end
    %% Calculating TRAIT score from re-calculated 
    STAIvars.TRanx_score = sum([STAIvars.TRArecal]);
else                                               % Twist if participant failed to complete 
    STAIvars.TRanx_score = -99;
end

end
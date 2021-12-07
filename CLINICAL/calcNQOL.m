function NQOLvars = calcNQOL(datain, scoring_table)
%% Generate Raw Score, T-score, & T-score SE for NQOL sub-scales
% Column Headers:
% [Participation in SocRoles, Emotional Beh, Fatigue, Affect & Well Being, Sleep, Satisf SocRoles, Cognition]

scale_names = fieldnames(scoring_table);
for i = 1:size(datain,2)
    if isempty(find([datain(:,i)] == -99))
        NQOLvars.Score(i)= nansum(datain(:,i)); 
            curr_subscale = eval(string(strcat('scoring_table.', scale_names(i))));
        NQOLvars.Tscore(i) = curr_subscale(find([curr_subscale(:,1)] == NQOLvars.Score(i)), 2);
        NQOLvars.Tse(i) = curr_subscale(find([curr_subscale(:,1)] == NQOLvars.Score(i)), 3);
    else
        NQOLvars.Score(i)= -99;
        NQOLvars.Tscore(i) = -99;
        NQOLvars.Tse(i) = -99;
    end
end
end
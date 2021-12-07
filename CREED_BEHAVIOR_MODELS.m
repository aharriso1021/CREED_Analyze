function stat_strct = CREED_BEHAVIOR_MODELS(dataIN, grp_col, tsk_col, taskNames, var_col, test)
%% CLINICAL ANOVAS   %%%%%%%%%%%%%%%%%%%%%%%
% dataIN:  data table                      % 
% grp_col: col idx of grouping variable    %
% var_col: col idx of variables to analyze %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

stat_strct = struct();

varNames = dataIN.Properties.VariableNames(var_col);
grpVarName = dataIN.Properties.VariableNames{grp_col};

if ~isempty(tsk_col) % Define Task Variable & Remove instances of unused categories
    tskVarName = dataIN.Properties.VariableNames{tsk_col};
    tskCatList = categories(dataIN.(tskVarName));
    dataIN.(tskVarName) = removecats(dataIN.(tskVarName), tskCatList(~ismember(tskCatList, taskNames)));
end

for vi = 1:length(varNames)
    iVarName = varNames{vi};
switch test
%% Linear Regrssion
    case 'lm'
    modelspec = [varNames{vi} '~1+' grpVarName];
    stat_strct(vi).DepVar = varNames{vi};
    stat_strct(vi).Model  = fitlm(dataIN, modelspec, 'CategoricalVars', 2);

%% ANOVA
    case 'anova'
    [p,tbl,stat] = anova1(dataIN{:,var_col(vi)}, dataIN{:,ismember(dataIN.Properties.VariableNames, grpVarName)}, 'off');
    stat_strct(vi).DepVar = varNames{vi};
        ANOVAtbl = cell2table(tbl,"VariableNames", tbl(1,:), "RowNames", tbl(:,1));
            ANOVAtbl(1,:) = [];
            ANOVAtbl(:,1) = [];
    stat_strct(vi).ANOVAtbl = ANOVAtbl;
    stat_strct(vi).ANOVAstat= stat;
    stat_strct(vi).TestStat = ANOVAtbl.F{1};
    stat_strct(vi).Prob     = ANOVAtbl.("Prob>F"){1};
    stat_strct(vi).Eta2     = ANOVAtbl.SS{1} ./ ANOVAtbl.SS{3};
        if p < (0.05 / length(stat.n)) % BONFERRONI CORRECTION FOR MULTIPLE COMPARISONS
            mct = multcompare(stat, "Display", "off");
            stat_strct(vi).MComp =  array2table(mct,...
                "VariableNames", {'Grp1' 'Grp2' 'MeanDiff' 'CI_lb' 'CI_ub' 'Prob'});
        else
            stat_strct(vi).MComp = NaN;    
        end
%% TWO-WAY ANOVA
    case 'anova2'        
    [~,tbl,stat] = anovan(dataIN.(iVarName), {dataIN.(grpVarName) dataIN.(tskVarName)},...
        'model', 'interaction', 'varnames', {grpVarName, tskVarName}, 'display', 'off');
    %
    stat_strct(vi).DepVar = varNames{vi};
    ANOVAtbl = cell2table(tbl,"VariableNames", tbl(1,:), "RowNames", tbl(:,1));
        ANOVAtbl(1,:) = [];
        ANOVAtbl(:,1) = [];
    %
    stat_strct(vi).ANOVAtbl = ANOVAtbl;
    stat_strct(vi).ANOVAstat= stat;
    %
    stat_strct(vi).([grpVarName '_Fstat']) = ANOVAtbl.F{1};
    stat_strct(vi).([grpVarName '_Pv'])    = ANOVAtbl.("Prob>F"){1};
    stat_strct(vi).([grpVarName '_Eta2'])  = ANOVAtbl.("Sum Sq."){1} ./ ANOVAtbl.("Sum Sq."){5};
    %
    stat_strct(vi).([tskVarName '_Fstat']) = ANOVAtbl.F{2};
    stat_strct(vi).([tskVarName '_Pv'])    = ANOVAtbl.("Prob>F"){2};
    stat_strct(vi).([tskVarName '_Eta2'])  = ANOVAtbl.("Sum Sq."){2} ./ ANOVAtbl.("Sum Sq."){5};
    %
    stat_strct(vi).('X_Fstat') = ANOVAtbl.F{3};
    stat_strct(vi).('X_Pv')    = ANOVAtbl.("Prob>F"){3};
    stat_strct(vi).('X_Eta2')  = ANOVAtbl.("Sum Sq."){3} ./ ANOVAtbl.("Sum Sq."){5};
    otherwise
end
end
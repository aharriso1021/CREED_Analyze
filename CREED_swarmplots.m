var_col = [4:11];
field_names = fieldnames(PERFtbl);
grp_names = {'HC-' ; 'HCx-A' ; 'HCx-S'}; 
%%
cT = cbrewer('qual', 'Set1', 3);
cT = flipud(cT);
%%

%%
for v = 1:length(var_col)
figure;
% for t = 1:length(fieldnames())
% subplot(320+t)
t = 1;
hold on;
    data_tbl = PERFtbl.(field_names{t});
    task_cond = data_tbl.Task(1);
    
    %
    h{t,1} = swarmchart([ones([sum(data_tbl.GRP == 1) 1])], data_tbl{data_tbl.GRP == 1, var_col(v)}, 'filled');
        h{t,1}.MarkerFaceColor = cT(1,:);
        h{t,1}.XJitterWidth = 0.50;
    h{t,2} = plot(1, nanmean(data_tbl{data_tbl.GRP == 1, var_col(v)}), 'ks', 'MarkerFaceColor', 'k');
        h{t,2}.MarkerSize = 10;
        stErr = nanstd(data_tbl{data_tbl.GRP == 1, var_col(v)})/sqrt(sum(data_tbl.GRP == 1));
    h{t,3} = errorbar(1, nanmean(data_tbl{data_tbl.GRP == 1, var_col(v)}), stErr*1.5);
        h{t,3}.Color = [0 0 0];
    %%
    h{t,4} = swarmchart([ones([sum(data_tbl.GRP == 2) 1])+1], data_tbl{data_tbl.GRP == 2, var_col(v)}, 'filled');
        h{t,4}.MarkerFaceColor = cT(2,:);
        h{t,4}.XJitterWidth = 0.50;
    h{t,5} = plot(2, nanmean(data_tbl{data_tbl.GRP == 2, var_col(v)}), 'ks', 'MarkerFaceColor', 'k');
        h{t,5}.MarkerSize = 10;
        stErr = nanstd(data_tbl{data_tbl.GRP == 2, var_col(v)})/sqrt(sum(data_tbl.GRP == 2));
    h{t,6} = errorbar(2, nanmean(data_tbl{data_tbl.GRP == 2, var_col(v)}), stErr*1.5);
        h{t,6}.Color = [0 0 0];
    %%
    h{t,7} = swarmchart([ones([sum(data_tbl.GRP == 3) 1])+2], data_tbl{data_tbl.GRP == 3, var_col(v)}, 'filled');
        h{t,7}.MarkerFaceColor = cT(3,:);
        h{t,7}.XJitterWidth = 0.50;
    h{t,8} = plot(3, nanmean(data_tbl{data_tbl.GRP == 3, var_col(v)}), 'ks', 'MarkerFaceColor', 'k');
        h{t,8}.MarkerSize = 10;
        stErr = nanstd(data_tbl{data_tbl.GRP == 3, var_col(v)})/sqrt(sum(data_tbl.GRP == 3));
    h{t,9} = errorbar(3, nanmean(data_tbl{data_tbl.GRP == 3, var_col(v)}), stErr*1.5);
        h{t,9}.Color = [0 0 0];
    title([char(task_cond) ': ' data_tbl.Properties.VariableNames{var_col(v)}])
        set(gca, 'XTick', [1 2 3]);
        set(gca, 'XTickLabel', grp_names);
% end

end

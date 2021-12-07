function ButtonTrialPerf = calcButtonPerformance(datain, task_variant)
try
    datain = datain.c3d;
catch 
    datain = datain;
end

ButtonTrialPerf = struct('TrialNumber', [], 'StimulusType', {}, 'TrialAccuracy', [], 'TrialRT',[]);
ButtonTrialPerf = repmat(ButtonTrialPerf, [length(datain) 1]);

% Calculate Trial by Trial Variables
for trial_idx = 1:length(datain)
knEvents = deblank([datain(trial_idx).EVENTS.LABELS]);
knTimes  = [datain(trial_idx).EVENTS.TIMES].*1000; % Convert to ms
    ButtonTrialPerf(trial_idx).TrialNumber = datain(trial_idx).TRIAL.TRIAL_NUM;
        switch task_variant
            case 'GNGB' % Go-NoGo Response INFREQUENT
                if datain(trial_idx).TRIAL.TP_ROW == 1
                    ButtonTrialPerf(trial_idx).StimulusType = 'Target';
                    if ismember('Correct (GO)', knEvents)
                        ButtonTrialPerf(trial_idx).TrialAccuracy = 1;
                            i = ismember(knEvents, 'Target_ON (GO)');
                            j = ismember(knEvents, 'Correct (GO)');
                        ButtonTrialPerf(trial_idx).TrialRT = knTimes(j) - knTimes(i);        
                    elseif ismember('Go_Error', knEvents) % Go Error = OMISSION ERROR
                        ButtonTrialPerf(trial_idx).TrialAccuracy = -1;
                        ButtonTrialPerf(trial_idx).TrialRT = NaN;
                    end
                elseif datain(trial_idx).TRIAL.TP_ROW == 2
                    ButtonTrialPerf(trial_idx).StimulusType = 'Distractor';
                    if ismember('Correct (NO)', knEvents)
                        ButtonTrialPerf(trial_idx).TrialAccuracy = 1;
                        ButtonTrialPerf(trial_idx).TrialRT = NaN;
                    elseif ismember('NoGo_Error', knEvents) % NoGo Error = COMMISSION ERROR
                        ButtonTrialPerf(trial_idx).TrialAccuracy = -1;
                            i = ismember(knEvents, 'Target_ON (NO)');
                            j = ismember(knEvents, 'NoGo_Error');
                        ButtonTrialPerf(trial_idx).TrialRT = knTimes(j) - knTimes(i); 
                    end
                end
            case 'NGGB' % NoGo-Go Response FREQUENT
                if datain(trial_idx).TRIAL.TP_ROW == 1
                    ButtonTrialPerf(trial_idx).StimulusType = 'Distractor';
                    if ismember('Correct (NO)', knEvents)
                        ButtonTrialPerf(trial_idx).TrialAccuracy = 1;
                        ButtonTrialPerf(trial_idx).TrialRT = NaN;
                    elseif ismember('NoGo_Error', knEvents) % NoGo Error = COMMISSION ERROR
                        ButtonTrialPerf(trial_idx).TrialAccuracy = -1;
                            i = ismember(knEvents, 'Target_ON (NO)');
                            j = ismember(knEvents, 'NoGo_Error');
                        ButtonTrialPerf(trial_idx).TrialRT = knTimes(j) - knTimes(i);
                    end
                elseif datain(trial_idx).TRIAL.TP_ROW == 2
                    ButtonTrialPerf(trial_idx).StimulusType = 'Target';
                    if ismember('Correct (GO)', knEvents)
                        ButtonTrialPerf(trial_idx).TrialAccuracy = 1;
                            i = ismember(knEvents, 'Target_ON (GO)');
                            j = ismember(knEvents, 'Correct (GO)');                 
                            ButtonTrialPerf(trial_idx).TrialRT = knTimes(j) - knTimes(i);
                    elseif ismember('Go_Error', knEvents) % Go Error = OMISSION ERROR
                        ButtonTrialPerf(trial_idx).TrialAccuracy = -1;
                        ButtonTrialPerf(trial_idx).TrialRT = NaN;
                        
                            
                    end
                end
        end
end

end
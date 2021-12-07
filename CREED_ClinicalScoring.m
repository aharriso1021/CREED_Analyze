function CREED_ClinicalScoring
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%                              CREED CLINICAL SCORING                                                                           %
% 1. State/Trait Anxiety = converted score                                                                                      %
% 2. Beck's Depression Inventory                                                                                                %
% 3. Neuro-QOL (Short Form Scoring)                                                                                             % 
% 4. RPQ = Scoring + Sub-domain breakdown                                                                                       %
%       - For HistCx participants = re-cats based on RPQ                                                                        %             
% ----------------------------------------------------------------------------------------------------------------------------- %
%  OUTPUT = PARTICIPANT CLINICAL TABLE                                                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

% clinical_dir = uiimport;
% clinical_dir = '/Volumes/HARRISONext/DATA/CREED_ParticipantData/CLIN/';
if ispc
    drvr = input('Indicate working driver for (ex: D:\): ', 's');
clinical_dir = [drvr '/DATA/CREED_ParticipantData/CLIN/'];
matlab_dir = [drvr '/MATLAB/CREED_Analyze/'];
elseif isunix
matlab_dir = uiimport;
matlab_dir = '/Users/adam/Documents/MATLAB/CREED_Analyze/';
end
addpath(genpath(matlab_dir)); addpath(genpath(clinical_dir));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

RVMDtblvars = {'PCSrpq16', 'PCSrpq03', 'PCSdsm05', 'RPQ16', 'RPQ03', 'RPQ13', 'RPQcog', 'RPQemo', 'RPQsom'};
% RVMDtbl  = table();
BDI2_tblvars = {'BDItot', 'BDIcog', 'BDInon_cog'};
% BDI2tbl  = table();
STAI_tblvars = {'SAIsc', 'TAIsc'};
% STAItbl  = table();
NQOL_tblvars = {'NQL_FATGsc', 'NQL_FATGtsc', 'NQL_FATGse', 'NQL_COGFsc', 'NQL_COGFtsc', 'NQL_COGFse', 'NQL_EMOTsc', 'NQL_EMOTtsc', 'NQL_EMOTse',...
    'NQL_AFFsc', 'NQL_AFFtsc','NQL_AFFse', 'NQL_SLPsc', 'NQL_SLPtsc', 'NQL_SLPse', 'NQL_SRPsc', 'NQL_SRPtsc', 'NQL_SRPse', 'NQL_SRSsc', 'NQL_SRStsc', 'NQL_SRSse'};
% NQOLtbl  = table();
FATGtblvars = {'task_FAT01', 'task_FAT02', 'task_FAT03'};
% FATGtbl  = table();
tblVars = ['ID' 'RPQ_ReGrp', RVMDtblvars, BDI2_tblvars, STAI_tblvars, NQOL_tblvars, FATGtblvars];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

NQOLscoring = struct('partSR', [], 'Emot', [], 'Fatg', [],'Aff', [],  'Slp', [], 'satiSR', [], 'Cogf', []);
STAIscoring = struct('State', [], 'Trait', []);

%% Read in Scoring sheets for Neuro-QoL & STAI
    NQOLscoring.partSR = xlsread('NeuroQoL_scoring.xlsx', 6);
    NQOLscoring.Emot   = xlsread('NeuroQoL_scoring.xlsx', 3);
    NQOLscoring.Fatg   = xlsread('NeuroQoL_scoring.xlsx', 1);
    NQOLscoring.Aff    = xlsread('NeuroQoL_scoring.xlsx', 4);
    NQOLscoring.Slp    = xlsread('NeuroQoL_scoring.xlsx', 5);
    NQOLscoring.satiSR = xlsread('NeuroQoL_scoring.xlsx', 7);
    NQOLscoring.Cogf   = xlsread('NeuroQoL_scoring.xlsx', 2);    
    
    STAIscoring.State = xlsread('STAI_scoring.xlsx', 1);
    STAIscoring.Trait = xlsread('STAI_scoring.xlsx', 2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
cd(clinical_dir);
cln_files = dir('*.cln');
part_cln = char({cln_files.name}');
%% 
if exist('CREED_Clinicals.mat','file') == 2
    load('CREED_Clinicals.mat');  
else
    CREEDclin_tbl = table();
end

%% Run thru participant files %% 
for part_i = 1:size(part_cln,1)
    disp([part_cln(part_i,1:9),'cln.mat']);
if ~exist([part_cln(part_i,1:9),'cln.mat'],'file')    
clin_tbl = table('Size', [1,length(tblVars)],'VariableTypes', repmat({'double'},[1 length(tblVars)]),...
        'VariableNames', tblVars);    
    cd(fullfile(clinical_dir, part_cln(part_i, :)))
    dir_files = dir;
        xi = contains({dir_files.name}, '._');
            if sum(xi) > 0
                delete(dir_files(xi).name);
                dir_files = dir;
            end
        ID = str2double(part_cln(part_i,6:9));
        clin_tbl.ID = ID;
            part_clinicaldat = readmatrix(dir_files(3).name);
            part_fatiguedat  = readmatrix(dir_files(4).name);   
%% Split Clinical Data             
[RVMDvars, PCScat] = calcRVMD(part_clinicaldat(:,11));
    %% Re-grouping ASYM based on calculated PCS category
    if ismember(ID, [1000:1:1999])
        clin_tbl.RPQ_ReGrp = 1;
    elseif ismember(ID, [2000:1:2999]) && sum(struct2array(PCScat)) < 2
        clin_tbl.RPQ_ReGrp = 2;
    elseif ismember(ID, [2000:1:2999]) && sum(struct2array(PCScat)) >= 2
        clin_tbl.RPQ_ReGrp = 3;
    elseif ismember(ID, [3000:1:3999])
        clin_tbl.RPQ_ReGrp = 3;
    else
        error('Unable to calculate re-group');
    end
    clin_tbl(1,[3 4 5]) = table(PCScat.PCSrpq16, PCScat.PCSrpq03, PCScat.PCSdsm05);
    clin_tbl(1,[6:11]) = table(RVMDvars.Total, RVMDvars.RPQ3, RVMDvars.RPQ13, RVMDvars.Cognitive,...
        RVMDvars.Emotional, RVMDvars.Somatic);
BDIIvars = calcBDII(part_clinicaldat(:,3));
    clin_tbl(1,[12:14]) = table(BDIIvars.total, BDIIvars.cog, BDIIvars.ncog);
STAIvars = calcSTAI(part_clinicaldat(:,1:2), STAIscoring);
    clin_tbl(1,[15:16]) = table(STAIvars.STanx_score,STAIvars.TRanx_score);
NQOLvars = calcNQOL(part_clinicaldat(:,4:10), NQOLscoring);
% [Participation in SocRoles, Emotional Beh, Fatigue, Affect & Well Being, Sleep, Satisf SocRoles, Cognition]
    clin_tbl(1, {'NQL_SRPsc' , 'NQL_SRPtsc' , 'NQL_SRPse' }) = table(NQOLvars.Score(1), NQOLvars.Tscore(1), NQOLvars.Tse(1));
    clin_tbl(1, {'NQL_EMOTsc', 'NQL_EMOTtsc', 'NQL_EMOTse'}) = table(NQOLvars.Score(2), NQOLvars.Tscore(2), NQOLvars.Tse(2));
    clin_tbl(1, {'NQL_FATGsc', 'NQL_FATGtsc', 'NQL_FATGse'}) = table(NQOLvars.Score(3), NQOLvars.Tscore(3), NQOLvars.Tse(3));
    clin_tbl(1, {'NQL_AFFsc' , 'NQL_AFFtsc' , 'NQL_AFFse' }) = table(NQOLvars.Score(4), NQOLvars.Tscore(4), NQOLvars.Tse(4));
    clin_tbl(1, {'NQL_SLPsc' , 'NQL_SLPtsc' , 'NQL_SLPse' }) = table(NQOLvars.Score(5), NQOLvars.Tscore(5), NQOLvars.Tse(5));
    clin_tbl(1, {'NQL_SRSsc' , 'NQL_SRStsc' , 'NQL_SRSse' }) = table(NQOLvars.Score(6), NQOLvars.Tscore(6), NQOLvars.Tse(6));
    clin_tbl(1, {'NQL_COGFsc', 'NQL_COGFtsc', 'NQL_COGFse'}) = table(NQOLvars.Score(7), NQOLvars.Tscore(7), NQOLvars.Tse(7));
FATGvars = calcFATG([part_fatiguedat]);
    clin_tbl(1, [38:40]) = table(FATGvars.Pre, FATGvars.Mid, FATGvars.Pst);
save(strcat(part_cln(part_i,1:9),'cln.mat'), 'clin_tbl', 'STAIvars', 'BDIIvars', 'FATGvars', 'NQOLvars', 'PCScat', 'RVMDvars');

CREEDclin_tbl = [CREEDclin_tbl; clin_tbl];
elseif ~ismember(str2num(part_cln(part_i,6:9)), CREEDclin_tbl.ID)
    cd(part_cln(part_i,:)) 
    load([part_cln(part_i,1:9),'cln.mat'], 'clin_tbl')
CREEDclin_tbl = [CREEDclin_tbl; clin_tbl];
else

end % END EXIST CHECK
cd(clinical_dir)

end % END SUBJ LOOP

cd(clinical_dir)
CREEDclin_tbl = sortrows(CREEDclin_tbl, 1);
save(['CREED_Clinicals.mat'], 'CREEDclin_tbl')
end



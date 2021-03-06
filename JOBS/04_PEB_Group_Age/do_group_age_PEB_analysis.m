%% This is the Pipeline of our MAIN ANALYSIS, investigating the effect of the Group, the AGE 
% and the interaction between thi two on the 359 suibjects. 
clear all
% Settings
addpath('/PATH/TO/SPM') % ADD the path to your SPM repository
basedir = '/path/to/your/repository/' % Change this line with the pat to the downloaded github repository


subjdir = fullfile(basedir, 'Sub_359');
GCMdir = fullfile(basedir,'GCMs') ;
GCMfile = fullfile(GCMdir, 'GCM_estimated');
analysisfold = fullfile (basedir, 'Interaction_Group_Age_analysis');
if ~exist(analysisfold) 
    mkdir(analysisfold); 
end 
phenoDir = fullfile(basedir, 'pheno');
phenofile = fullfile(phenoDir, 'pheno_359.mat');
templates60 = fullfile(GCMdir,'GCM_templates_60models.mat');

load(phenofile)


%% Create the Design Matrix

% get regressors of interest index and extract the columns
[~,group_idx] = ismember('DX_GROUP',phenolabels);
[~,SRS_idx] = ismember('SRS_RAW_TOTAL',phenolabels);
[~,AGE_idx] = ismember('AGE_AT_SCAN',phenolabels);
[~,FD_idx] = ismember('FD_mean',phenolabels);  
[~,EYE_idx] = ismember('EYE_STATUS_AT_SCAN',phenolabels);  
[~,SITE_idx] = ismember('SITE_ID',phenolabels);  

Group = phenomat(:,group_idx);
SRS = phenomat(:,SRS_idx);
AGE = phenomat(:,AGE_idx);
FD = phenomat(:,FD_idx);
EYE = phenomat(:,EYE_idx);
Site = phenomat(:,SITE_idx);



% Get the subject list from the directory and check whether it is in the
% same order of the GCM

%Get the list
subj = dir(subjdir);
isub = [subj(:).isdir];
subj = {subj(isub).name};
subj = str2double(subj);
subj(isnan(subj)) = [];
subjlist = subj';
nsub = length(subjlist);

% Check the order
GCMfile_pre_estimated = fullfile (GCMdir, 'GCM_pre_estimated')
load(GCMfile_pre_estimated)

for i=  1:length(subjlist)
   subject = subjlist(i,1); 
   if ~contains(GCM{i,1},string(subject))
       error('Error In Subject Order!!!!')       
   end
end

% Create the Design Matrix with Mean, Group, AGE, group*AGE, meanFD
nvariables = 5;

DM = zeros(nsub,nvariables);
DM(:,1) = 1;

for i=1:length(subjlist)
     subject = subjlist(i,1);
        [~, index] = ismember(subject,phenomat(:,2));
        DM(i,2) = Group(index);
        DM(i,3) = AGE(index);
        DM(i,5) = FD(index);
     
end

% The second column is the group, change the 2s(TD) in to 0s
for i=1:height(DM)
    if DM(i,2)== 2
        DM(i,2) = 0; 
    end 
end

%Normalize and create the interaction regressor
DM(:,2:end) = normalize(DM(:,2:end));
DM(:,4) = DM(:,2).*DM(:,3);

%Labels
Labels = { 'Mean', 'Group','AGE' ,'Group*AGE', 'FD'};

%%% Save Design Matrix
filename = [analysisfold 'Int_Group_AGE_DM.mat'];
save(filename,'DM', 'Labels')

%% Second Level PEB

DesMat = fullfile(analysisfold, 'Int_Group_AGE_DM.mat');

% Load design matrix
DM = load(DesMat);
X        = DM.DM;
X_labels = DM.Labels;

% Load GCM
GCM=load(GCMfile);
GCM=GCM.GCM;


% PEB settings
M = struct();
M.Q      = 'all';
M.X      = X;
M.Xnames = X_labels;
M.maxit  = 256;   

% BUILD PEB on A Parameters (intrinsic connectivity)
[PEB_A,RCM_A] = spm_dcm_peb(GCM,M,{'A'});

PEBfilename = fullfile(analysisfold, 'PEB_groupage.mat');
save(PEBfilename,'PEB_A','RCM_A','-v7.3');

%60 MODELS
templates60 = load(templates60)

% Run model comparison
[BMA,BMR] = spm_dcm_peb_bmc(PEB_A, templates60.GCM_templates);

BMAfilename = fullfile(analysisfold, 'BMA_GroupAge.mat')
save(BMAfilename, 'BMA', 'BMR')


spm_dcm_peb_review_90ci(PEB_A, GCM))
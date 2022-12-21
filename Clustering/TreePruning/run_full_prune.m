sbci_dat = genpath('/pine/scr/a/a/aallen1/SBCI_Data')
misc_dat = genpath('/pine/scr/a/a/aallen1/MiscData')
prune_dat = genpath('/pine/scr/a/a/aallen1/TreePrune/PruneScripts')
eda_dat = genpath('/pine/scr/a/a/aallen1/EDA')
addpath(sbci_dat)
addpath(misc_dat)
addpath(prune_dat)
addpath(eda_dat); 

%% Get Mean SC/FC %% 
load('mean_sc.mat')
avg_sc = mean_sc; 

% Take Out Corpus Rows/Cols
load('corpus_mask.mat')
if size(mean_sc,1) >= 4124
    mean_sc(corpus_mask,:) = [];
    mean_sc(:,corpus_mask) = [];

    avg_sc(corpus_mask,:) = []; 
    avg_sc(:,corpus_mask) = []; 
end


my_link = linkage(mean_sc,'average','euclidean'); 

prune_struct = cost_comp_prune(my_link,avg_sc,@parc_info_loss);
prune_struct.link = my_link; 
save('/pine/scr/a/a/aallen1/TreePrune/GroupPruneResults/LowErr/scdist_ward_prune_struct.mat','prune_struct')




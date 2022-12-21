%% Add Needed Paths %% 
my_files = genpath('/21dayscratch/scr/a/a/aallen1'); 
addpath(my_files)

all_scs = []; 
frob_norm = [];
all_ids = [];
sub_count = 0; 

%% Start For Loop %% 
for i = 1:38
tic

    if i == 38
        %load('/overflow/zzhanglab/SBCI_Finished_ABCD_Data/sbci_finished_batch6/batch6_sbci_connectome/SBCI_sc_tensor_part'+string(i)+'_of_32.mat')
        %load('/overflow/zzhanglab/SBCI_Finished_ABCD_Data/sbci_finished_batch6/batch6_sbci_connectome/SBCI_sc_tensor_part32_of_32.mat')
        load('/overflow/zzhanglab/SBCI_Finished_ABCD_Data/sbci_connectome/batch3_sbci_connectome/SBCI_sc_tensor_part38_of_38.mat','sbci_sc_tensor','sub_ids')
    else
        %load('/overflow/zzhanglab/SBCI_Finished_ABCD_Data/sbci_finished_batch6/batch6_sbci_connectome/SBCI_sc_tensor_part_'+string(i)+'_of_32.mat')
        load('/overflow/zzhanglab/SBCI_Finished_ABCD_Data/sbci_connectome/batch3_sbci_connectome/SBCI_sc_tensor_part_'+string(i)+'_of_38.mat','sbci_sc_tensor','sub_ids')
    end

    all_ids = [all_ids; sub_ids];
    num_subs = size(sbci_sc_tensor,3); 

    for j = 1:num_subs

        tmp_sc = sbci_sc_tensor(:,:,j); 

        mask_sc = triu(true(size(tmp_sc)),-1);
        tmp_vect_sc = tmp_sc(mask_sc).';

        all_scs = [all_scs; tmp_vect_sc];
        frob_norm = [frob_norm norm(tmp_sc,"fro")];

        clear tmp_sc; 
        clear tmp_vect_sc; 
        clear mask_sc; 

    end
    
    clear sbci_sc_tensor; 

"One Tensor " + string(i) + " Finished"
toc
end


[~,all_scores,~,all_explain] = fastpca(all_scs); 


all_scores = [all_ids all_scores]; 

save('ALL_ABCD_PC_SCORES_3.mat','all_scores','-v7.3')
%save('ALL_ABCD_SC.mat','all_scs','-v7.3')


%% Create File Name %%


%% Save File
sub_count
result = 1;


function result = parcellate_abcd_mats(parc,batch_num)

%% Load Required Paths %%
sbci_tools = genpath('/pine/scr/a/a/aallen1/SBCI_Toolkit');
addpath(sbci_tools)

%% Load SBCI Data %%
[sbci_parc, sbci_mapping, ~] = load_sbci_data('/pine/scr/a/a/aallen1/SBCI_Data/ABCD/SBCI_AVE', 'ico4');
sbci_surf = load_sbci_surface('/pine/scr/a/a/aallen1/SBCI_Data/ABCD/SBCI_AVE');

%% Initalize Variables %%
sub_count = 0; 
if batch_num == 3
    load('abcd_b3_outliers.mat')
    outlier_list = abcd_b3_outliers;
    batch_size = 38;
elseif batch_num == 4
    batch_size = 38; 
elseif batch_num == 6
    load('abcd_b6_outliers.mat')
    outlier_list = abcd_b6_outliers;
    batch_size = 32; 
end
parc_tensor = zeros(5124,5124,batch_size); 

%% Loop Through Subjects %% 
  for i = 1:batch_size

        if i == batch_size
            load('/overflow/zzhanglab/SBCI_Finished_ABCD_Data/sbci_connectome/batch'+string(batch_num)+...
                '_sbci_connectome/SBCI_sc_tensor_part'+string(batch_size)+'_of_'+string(batch_size)+'.mat','sbci_sc_tensor','sub_ids')
        else
            load('/overflow/zzhanglab/SBCI_Finished_ABCD_Data/sbci_connectome/batch'+string(batch_num)+...
                '_sbci_connectome/SBCI_sc_tensor_part_'+string(i)+'_of_'+string(batch_size)+'.mat','sbci_sc_tensor','sub_ids')            
        end

        % Get subjects who aren't outliers 
        sub_in = ismember(sub_ids,outlier_list); %% Subjects who are outliers
        sub_size = 1:length(sub_ids); 
        sub_iter = sub_size(~sub_in); %% Take out outliers 

        % Iterate over non-outlier subjects
        for j = sub_iter   
            sub_count = sub_count + 1; 
            tmp_sc = sbci_sc_tensor(:,:,j); 
            tmp_sc = parcellate_sc(tmp_sc,sbci_parc(parc),sbci_mapping);
            parc_tensor(:,:,sub_count) = tmp_sc; 
        
        end

        clear sbci_sc_tensor; 
        "FINISHED BATCH " + string(bath_num) + " TENSOR: " + string(i)

   end

   sub_count
   
   %% Save Tensor %% 
   save('/pine/scr/a/a/aallen1/SC/ABCD_BATCH_3_PARC_'+string(parc)+'_tensor.mat','parc_tensor','v7.3')
   result = 1
end
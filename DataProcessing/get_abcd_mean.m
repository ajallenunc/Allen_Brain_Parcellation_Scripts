
% Initialize Variables
mean_fc = zeros(5124,5124); 
num_subs = 0; 
sub_count = 0; 

% Load Outlier Data 
misc_dat = genpath('/pine/scr/a/a/aallen1/MiscData');
addpath(misc_dat)

load('abcd_b3_outliers.mat')
load('abcd_b6_outliers.mat')

% Iterate over batches 
for batch = [3 6]

    if batch == 3

       for i = 1:38
            % Load batch 3 tensors 
            if i == 38
                load('/overflow/zzhanglab/SBCI_Finished_ABCD_Data/sbci_connectome/batch3_sbci_connectome/SBCI_fc_tensor_part38_of_38.mat','sbci_fc_tensor','sub_ids')
            else
                load('/overflow/zzhanglab/SBCI_Finished_ABCD_Data/sbci_connectome/batch3_sbci_connectome/SBCI_fc_tensor_part_'+string(i)+'_of_38.mat','sbci_fc_tensor','sub_ids')            
            end

            % Get subjects who aren't outliers 
            sub_in = ismember(sub_ids,abcd_b3_outliers); 
            sub_size = 1:length(sub_ids); 
            sub_iter = sub_size(~sub_in); 
            % Iterate over non-outlier subjects
            for j = sub_iter
            
                sub_count = sub_count + 1; 
                tmp_fc = sbci_fc_tensor(:,:,j); 

                has_data = ~(all(ismissing(tmp_fc), "all") | all(tmp_fc == 0, "all"));

                if has_data 
                    %tmp_sc = thresholdCorRows(tmp_sc,75, 0); 
    
                    %tmp_sc = log((10^5*tmp_sc)+1); 
                    mean_fc = mean_fc + tmp_fc;                                
                end
            
            end

            clear sbci_fc_tensor; 
            "FINISHED BATCH 3 TENSOR: " + string(i)

        end

    elseif batch == 6

       for k = 1:32
            % Load batch 6 tensors 
            if k == 32
                load('/overflow/zzhanglab/SBCI_Finished_ABCD_Data/sbci_connectome/batch6_sbci_connectome/SBCI_fc_tensor_part32_of_32.mat','sbci_fc_tensor','sub_ids')
            else
                load('/overflow/zzhanglab/SBCI_Finished_ABCD_Data/sbci_connectome/batch6_sbci_connectome/SBCI_fc_tensor_part_'+string(k)+'_of_32.mat','sbci_fc_tensor','sub_ids')            
            end

            % Get subjects who aren't outliers 
            sub_in = ismember(sub_ids,abcd_b6_outliers); 
            sub_size = 1:length(sub_ids); 
            sub_iter = sub_size(~sub_in); 

            % Iterate over non-outlier subjects
            for l = sub_iter
            
                sub_count = sub_count + 1; 
                tmp_fc = sbci_fc_tensor(:,:,l); 
                has_data = ~(all(ismissing(tmp_fc), "all") | all(tmp_fc == 0, "all"));

                if has_data 
                    %tmp_sc = thresholdCorRows(tmp_sc,75, 0); 
    
                    %tmp_sc = log((10^5*tmp_sc)+1); 
                    mean_fc = mean_fc + tmp_fc;                                
                end

            
          
            end
            clear sbci_fc_tensor; 
            "FINISHED BATCH 6 TENSOR: " + string(k)
        end
    end


end

"NUMBER OF SUBJECTS: " + string(sub_count)

mean_fc = mean_fc / sub_count; 


save('ABCD_B3_B6_MEAN_FC','mean_fc','-v7.3')

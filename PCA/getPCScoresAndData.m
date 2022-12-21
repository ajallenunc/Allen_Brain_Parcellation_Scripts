function result = getPCScoresAndData(parc,k,addDendo,horizCut,doLogT)

    %% Add Needed Paths %% 
    dogwoodpath = genpath('/21dayscratch/scr/a/a/aallen1');
    addpath(dogwoodpath)
%     sbci_dat = genpath('/pine/scr/a/a/aallen1/SBCI_Data'); 
%     prune_dat = genpath('/pine/scr/a/a/aallen1/TreePrune');
%     id_dat = genpath('/pine/scr/a/a/aallen1/PredictTraits/RScripts/data');
%     misc_data = genpath('/pine/scr/a/a/aallen1/MiscData');
%     pca_data = genpath('/pine/scr/a/a/aallen1/PCA');
%     
%     addpath(sbci_dat)
%     addpath(prune_dat)
%     addpath(id_dat)
%     addpath(misc_data)
%     addpath(pca_data)
    
    %% Create File Name %%
    
    if parc ~= "desk" && parc ~= "bn" && parc ~= "hcp" && parc ~= "full"
        filename = "/21dayscratch/scr/a/a/aallen1/SBCI_Data/SC/Parc_SCs/"+parc+"_"+string(k); 
    else
        filename = "/21dayscratch/scr/a/a/aallen1/SBCI_Data/SC/Parc_SCs/"+parc; 
    end
    
    if addDendo
        filename = filename + "_dendro";
    end
    if horizCut
        filename = filename + "_horiz";
    end
    
    filename = filename + "_sc_tensor.mat"; 
    
    % Need size of parcellation to preallocate data matrix 
    idx = getParcIDX(parc,k,horizCut);
    if(addDendo == 1)
        parc_size = 2*(length(unique(idx))-1) - 1; 
    else
        parc_size = length(unique(idx));
    end
    
    numb_cols = (parc_size*(parc_size-1))/2; 
    
    %% Loop Through Subject Matrices
    
    sc_tensor = load(filename); % Tensor called sc_tensor 
    all_ids = sc_tensor.all_ids;
    sc_tensor = sc_tensor.sc_tensor; 
    numb_subs = size(sc_tensor,3); 
    all_scs = zeros(numb_subs,numb_cols); 
    
    for i = 1:numb_subs
    
        tmp_sc = sc_tensor(:,:,i); 
            
        % check that tmp_sc is symmetric
        if istriu(tmp_sc) || istril(tmp_sc)
            tmp_sc = tmp_sc + tmp_sc.';
        end
    
        if doLogT
            tmp_sc = log((10^5 * tmp_sc)+1);
        end
    
        mask_sc = tril(true(size(tmp_sc)),-1);
        tmp_vect_sc = tmp_sc(mask_sc).';
        all_scs(i,:) = tmp_vect_sc;
    
    end
    
    if size(all_scs,1) < size(all_scs,2)
       [~,all_scores,~,all_explain] = fastpca(all_scs);
    else 
       [~,all_scores,~,~,all_explain] = pca(all_scs);
    end
    
    all_scores = [all_ids all_scores];
    all_scs = [all_ids all_scs]; 
    
    %% Create File Name %%
    if parc ~= "desk" && parc ~= "bn" && parc ~= "hcp" && parc ~= "full"
        filename_scores = "/21dayscratch/scr/a/a/aallen1/SBCI_Data/SC/Parc_SCs/SC_Scores/"+parc+"_"+string(k); 
        filename_allsc = "/21dayscratch/scr/a/a/aallen1/SBCI_Data/SC/Parc_SCs/SCDataMatrices/"+parc+"_"+string(k); 
    
    else
        filename_scores = "/21dayscratch/scr/a/a/aallen1/SBCI_Data/SC/Parc_SCs/SC_Scores/"+parc; 
        filename_allsc = "/21dayscratch/scr/a/a/aallen1/SBCI_Data/SC/Parc_SCs/SCDataMatrices/"+parc; 
    
    end
    
    if addDendo
        filename_scores = filename_scores + "_dendro";
        filename_allsc = filename_allsc + "_dendro";
    
    end
    if horizCut
        filename_scores = filename_scores + "_horiz";
        filename_allsc = filename_allsc + "_horiz";
    
    end
    
    filename_scores = filename_scores + "_pc_scores.mat"; 
    filename_allsc = filename_allsc + "_all_scs.mat";

    save(filename_scores,'all_scores','all_explain','parc','parc_size','-v7.3')
    save(filename_allsc,'all_scs','parc','parc_size','-v7.3')
    

    numb_subs

    result = 1; 

end

function idx = getParcIDX(parc,k,horizCut)

    my_files = genpath('/21dayscratch/scr/a/a/aallen1'); 
    addpath(my_files)
    
    % Load Pruning Information
    if (parc == "avgsc")
        load('avgsc_prune_struct.mat')
    elseif parc == "thresh80"
        load('thresh80_prune_struct.mat')
    end
    
    % Get IDX 
    if parc ~= "full" && parc ~= "desk" && parc ~= "bn" && parc ~= "hcp"
        if horizCut
            idx = cluster(prune_struct.link,'maxclust',k);
        else
            [idx,~,~] = fast_term_to_clusters(prune_struct.treeSeq,prune_struct.node_mat,find(prune_struct.lengthSeq <= k,1),prune_struct.link);
        end
    elseif parc == "full"
         idx = 1:4121;
    elseif parc == "desk"
         load('desikan_parc.mat');
         my_parc = desikan_parc;
         idx = my_parc.labels';
    elseif parc == "bn"
        load('bn_parc.mat');
        my_parc = bn;
        idx = my_parc.labels';
    elseif parc == "hcp"
        load('hcpmmp1_parc.mat');
        my_parc = hcpmmp1;
        idx = my_parc.labels';
    end

end
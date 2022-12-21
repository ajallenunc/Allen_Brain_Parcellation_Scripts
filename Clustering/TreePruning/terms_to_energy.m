%function [idx,term_nodes] = term_to_clusters(prune_list,node_matrix,max_leaf,choice,dendo)
function [energy_fcn,length_seq] = terms_to_energy(prune_struct,sc,maxDepth)

startIter = find(prune_struct.lengthSeq <= maxDepth,1); 
prune_list = prune_struct.treeSeq; 
node_matrix = prune_struct.node_mat; 
dendo = prune_struct.link; 
energy_fcn = []; 
length_seq = []; 
iter = 1; 

for choice = startIter:5:length(prune_list)
tic

    [~,my_idx] = fast_term_to_clusters(prune_list,node_matrix,choice,dendo); 
    my_idx = my_idx.';
    
    my_energy = parc_info_loss(my_idx,sc);
    my_length = length(unique(my_idx)); 

    energy_fcn = [energy_fcn my_energy]; 
    length_seq = [length_seq my_length]; 

    iter = iter + 1; 
toc
"Iter " + string(choice) + " of " + string(length(prune_list))
end

end
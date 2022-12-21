function [idx_corp,idx_no_corp,my_parc,term_nodes] = fast_term_to_clusters(prune_list,node_matrix,choice,dendo)

%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% update to use matrix without corpus
load('corpus_mask.mat')
load('anti_corpus.mat')
max_leaf = (size(node_matrix,1) + 1)/ 2; 
%[~,~,term_nodes] = dendrogram(dendo,0);  
term_nodes = 1:size(dendo,1)+1; 
%step = 1; 

step = 1; 
for prune_node = prune_list

    % Update Terminal Nodes
    
    term_nodes = [term_nodes prune_node]; 
    
    drop_leafs = find(node_matrix(prune_node,:)==1); 
     
    [~,col] = find(term_nodes == drop_leafs(:));
    term_nodes(col) = [];  
    
    if (step == choice)       
        break;
    end
    
    step = step+1; 

end

idx_no_corp = zeros(3611,1); 
idx_corp = zeros(4121,1);
id = 1; 
for t = term_nodes
    get_nest = find(node_matrix(t,:)==1); 
    get_obser = get_nest(get_nest <= max_leaf); 
    idx_corp(anti_corpus(get_obser)) = id; 
    idx_no_corp(get_obser) = id; 
    id = id+1; 
end

find_4 = find(idx_corp == 4); 
idx_corp(find_4) = id; 
idx_corp(corpus_mask) = 4; 

my_parc.labels = idx_corp; 
[~,I] = sort(idx_corp); 
my_parc.sorted_idx = I; 

end


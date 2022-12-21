%% Function Info %% 
% Input: full_sc (with CC removed), parc_sc, prune_struct, termn_nodes 
function [dendo_mat,node_list,self_cons] = addDendoToParc(full_sc,parc_sc,prune_struct,term_nodes)

% check that full_sc is symmetric 
if istriu(full_sc) || istril(full_sc)
    full_sc = full_sc + full_sc.';
end

max_leaf = size(full_sc,1); 
node_mat = prune_struct.node_mat; % Matrix with ancestral information for nodes 

% Remove CC from parcellated matrix (Coded as ROI 4 in tree parcellations) 
parc_sc(4,:) = []; 
parc_sc(:,4) = []; 

parc_size = size(parc_sc,1); % Size of parcelleated matri                                                                               x 

% Create dendo matrix with correct size 
dendo_mat = zeros((2*parc_size)-1,(2*parc_size)-1); 
upper_parc = parc_sc - tril(parc_sc); 
dendo_mat(1:parc_size,1:parc_size) = upper_parc; % Fill in terminal node connections

dendo_size = size(dendo_mat,1); 

node_list = []; 
% Add inner nodes to node list using node_matrix 
for t = term_nodes

    node_list = [node_list; find(node_mat(:,t) == 1)]; 

end
node_list = unique(node_list); 
node_list = [term_nodes.'; node_list]; 

self_cons = zeros(dendo_size,dendo_size); 

% Compute Self Connections
for i = 1:dendo_size
    for j = i

            nest = find(node_mat(node_list(i),:) == 1); 
            obs = nest(nest <= max_leaf); 
            
            get_sc = full_sc(obs,obs); 
            self_cons(i,j) = mean((get_sc(:))); 
    end
end

% Create Dendo Matrix
for i = 1:dendo_size

    for j = i:dendo_size
       
        % Keep Original Parcellated SC
        if (i <= parc_size) && (j <= parc_size)
            continue
        elseif (i == j) 
            continue 
        end
       
        % Get Terminal Makeup of Node I
        i_nest = find(node_mat(node_list(i),:) == 1); 
        [i_to_terms,~] = find(intersect(i_nest,term_nodes) == term_nodes.'); 
        i_to_terms = [i_to_terms find(node_list(i) == term_nodes.')];

        % Get Terminal Makeup of Node J
        j_nest = find(node_mat(node_list(j),:) == 1); 
        [j_to_terms,~] = find(intersect(j_nest,term_nodes) == term_nodes.'); 
        j_to_terms = [j_to_terms find(node_list(j) == term_nodes.')];

        connect_v = []; % Vector to hold Parcelleted SC Connections of Terminal Nodes 
        
        % Create All Combos of Child and Parent Term_Nodes
        % And Remove Duplicates (e.g. (4,2) and (2,4) are duplicates) 
        all_combos = combvec(i_to_terms.',j_to_terms.').'; 
        all_combos = unique(sort(all_combos,2),'rows','stable'); 

        for r = 1:size(all_combos,1)  

            combo = all_combos(r,:);                             
            if length(combo) == length(unique(combo))
                connect_v = [connect_v parc_sc(combo(1),combo(2))]; % Between connections
            else
                connect_v = [connect_v self_cons(combo(1),combo(2))]; % Self connections
            end  
        
        end
        
        dendo_mat(i,j) = mean(connect_v); % Take mean of all connections
                
    end
end

% Make dendo_mat symmetric and zero out diagonals 
dendo_mat = dendo_mat - diag(diag(dendo_mat)); 
dendo_mat = dendo_mat + dendo_mat.' - 2*diag(diag(dendo_mat));

end
 
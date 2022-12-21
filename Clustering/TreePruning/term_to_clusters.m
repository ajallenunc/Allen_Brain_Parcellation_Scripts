%function [idx,term_nodes] = term_to_clusters(prune_list,node_matrix,max_leaf,choice,dendo)
function [idx_corp,idx_no_corp,term_f,order_mat,lines_d,lines_out,copy_d,term_nodes] = term_to_clusters(prune_list,node_matrix,choice,dendo)

%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
lines_out =[];
energy_fcn = []; 
length_seq = []; 
fcn = 0; 
load('corpus_mask.mat')
load('anti_corpus.mat')
max_leaf = (size(node_matrix,1) + 1)/ 2; 
f1 = figure; 
[~,~,term_nodes] = dendrogram(dendo,0);  
%step = 1; 

step = 1; 
for prune_node = prune_list

    % Update Terminal Nodes
    
    term_nodes = [term_nodes prune_node]; 
    
    drop_leafs = find(node_matrix(prune_node,:)==1); 
     
    [~,col] = find(term_nodes == drop_leafs(:));
    term_nodes(col) = []; 
    
    
    if (step == choice)
       % figure(1)
       % dendrogram(dendo)
       f2 = figure; 
       d = dendrogram(dendo,0); % Plot Dendrogram 
       copy_d = d; 
       lines_d = 1:length(d); 
        for node = term_nodes     

           if node > max_leaf

                %Prune Dendrogram
                find_descen = find(node_matrix(node,:) == 1);
                [delete_lines,~] = find(dendo(:,1) == find_descen);
                lines_out = [lines_out; delete_lines]; 
                delete(d(delete_lines));
                set(gca,'xticklabel',{[]})
                title('SC Dendrogram Pruned- Number of Term Nodes = ' + string(length(term_nodes)))
                
                diff = setdiff(lines_d,lines_out);
                
                order_mat = []; 
                
                for i = diff
                    link_row = dendo(i,:);
                    link_row = link_row(1:2); 
                    for j = link_row
                        order_mat = [order_mat; j min(copy_d(i).XData)];
                    end
                end
                
                [find_row,~] = find(order_mat(:,1) == term_nodes);
                term_f = order_mat(find_row,:); 
                term_f = sortrows(term_f,2); 
                term_f = term_f(:,1); 

%                 %Relabel X Axis
%                 xspace = xticks(); 
%                 xlabel = xticklabels(); 
%                 
%                 find_obs = find_descen(find_descen < max_leaf); 
%                 
%                 labels = char(" " + string(find_obs)); 
%                 node
%                 [~,find_labels] = find(xlabel == labels)
%                 %find_labels
                
            end
            

        end
        
        break;

    end
    
    step = step+1; 

end
% length_seq
% length_seq(end) = 1; 
idx_corp = zeros(4121,1);
idx_no_corp = zeros(length(dendo)+1,1); 
id = 1; 
for t = term_f.'
    get_nest = find(node_matrix(t,:)==1); 
    get_obser = get_nest(get_nest <= max_leaf); 

    idx_corp(anti_corpus(get_obser),:) = id; 
    %idx_corp(get_obser) = id; 
    idx_no_corp(get_obser) = id; 
%     if t == 7498
%     get_obser
%     end


    id = id+1; 
end

find_4 = find(idx_corp == 4); 
idx_corp(find_4) = id; 
idx_corp(corpus_mask) = 4; 
%corp_l = corpus_mask(corpus_mask <= 2064); 
%corp_r = corpus_mask(corpus_mask >= 2065); 
%idx_corp(corpus_mask) = id; 
%idx_corp(corp_l) = id; 
%idx_corp(corp_r) = id+1; 

end


function [err,high_dim_mat] = parc_info_loss(idx,sc)
tic
high_dim_mat = sc; 
picks = 1:1:size(sc,1);

for id = unique(idx)
    
    group = find(idx == id); 

    if (length(group) < 2)
        continue 
    end
    
    % Get non-grouped columns of SC matrix
    not_group = setdiff(picks,group); 
    not_group_cols = sc(:,not_group);         
    
    find_mean = not_group_cols(group,:); % Group rows of non-group cols
    means = sum(find_mean,1)/length(group); % Calculate mean
    assign = repmat(means,length(group),1); % Fill up matrix with means
    high_dim_mat(group,not_group) = assign; 
    high_dim_mat(not_group,group) = assign.'; 
    
    group_nest = sc(group,group); % Set within cluster connections
    high_dim_mat(group,group) = mean(group_nest(:));
    
end
err = (high_dim_mat - sc).^2; 
err = mean(err(:)); 
toc
"FINISHED ENERGY CALCULATION"
end
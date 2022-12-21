function [thresh_mat, cor_mat] = thresholdCorRows(mat,p, is_binary)
    row_thresh = prctile(mat,p,2); 
     
    % Create Thresholded Matrix 
    if is_binary == 1 % Values above percentile set to 1. 
        thresh_mat = mat >= row_thresh; 
    else 
        thresh_mat = (mat .* (mat >= row_thresh)); 
    end
    
    % Calculate correlation of rows of thresholded matrix
    cor_mat = corrcoef(thresh_mat.'); 

end
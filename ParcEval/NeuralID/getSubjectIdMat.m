sbci_dat = genpath('/pine/scr/a/a/aallen1/SBCI_Data');
addpath(sbci_dat)
id_mat = zeros(11,100); 
counter = 0; 
for i = 1:11
    if i == 11
    
        load("scan_2_SC.mat",'full_id_set')
        batch_size = size(full_id_set,2); 
        id_mat(i,1:batch_size) = counter+1:counter+batch_size; 

    else
        load('sc_ids_'+ string(i) + '.mat')
    
        batch_size = size(sc_ids,2); 
        id_mat(i,1:batch_size) = counter+1:counter+batch_size; 
        counter = counter + batch_size; 
    
    end



    % Rescan Data
  


end

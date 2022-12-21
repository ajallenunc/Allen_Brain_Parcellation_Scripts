function [new_sc,old_sc,order] = reorderSC(sc,idx)
% Reorder rows and columns of matrix (sc) according to labels (idx) 
order = []; 
    for i = unique(idx).'
        order = [order; find(idx == i)]; 
    end

 new_sc = sc(order,order); 
 old_sc = sc; 

end


function result = createParcTensor(parc,k,addDendo,doHoriz)
%% Add Needed Paths %% 
my_files = genpath('/21dayscratch/scr/a/a/aallen1'); 
addpath(my_files)

%% Initialize Variables  
idx = getParcIDX(parc,k,doHoriz); 
if(addDendo == 1)
    parc_size = 2*(length(unique(idx))-1) - 1
else 
    parc_size = length(unique(idx)); 
end
sc_tensor = zeros(parc_size,parc_size,899); 
all_ids = zeros(899,1);
sub_count = 0; 

%% Start For Loop %% 
for i = 1:10
tic
    load('sc_ids_'+string(i))        
    load('sbci_sc_tensor_'+string(i)+'.mat') %Create tensors for each resolution   
    num_subs = size(sbci_sc_tensor,3); 

    for j = 1:num_subs

        sub_count = sub_count + 1; 

        tmp_sc = sbci_sc_tensor(:,:,j); 
 %      tmp_sc = tmp_sc + tmp_sc' - 2*diag(diag(tmp_sc)); 
        tmp_sc = scToParc(parc,k,tmp_sc,addDendo,doHoriz); 
        sc_tensor(:,:,sub_count) = tmp_sc; 
        all_ids(sub_count) = sc_ids(j); 


    end
"One Tensor Finished"
toc
end

%% Create File Name %%
if parc ~= "desk" && parc ~= "bn" && parc ~= "hcp" && parc ~= "full"
    filename = '/21dayscratch/scr/a/a/aallen1/SBCI_Data/SC/Parc_SCs/'+parc+'_'+string(k); 
else
    filename = '/21dayscratch/scr/a/a/aallen1/SBCI_Data/SC/Parc_SCs/'+parc; 
end

if addDendo
    filename = filename + '_dendro';
end
if doHoriz
    filename = filename + '_horiz';
end

filename = filename + '_sc_tensor.mat'; 


%% Save File
save(filename,'sc_tensor','all_ids','parc','parc_size','-v7.3')
sub_count
result = 1;

end

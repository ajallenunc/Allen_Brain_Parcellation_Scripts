function result = FastTensCreateSimMatrix(parc,k,addDendo,horizCut,batch_id)
%% Notes
% 9/8/2022 : Adding Dendo Info Returns a Symmetric Matrix 

%% Add Needed Paths %%
sbci_dat = genpath('/pine/scr/a/a/aallen1/SBCI_Data');
prune_dat = genpath('/pine/scr/a/a/aallen1/TreePrune');
id_dat = genpath('/pine/scr/a/a/aallen1/PredictTraits/RScripts/data');
misc_data = genpath('/pine/scr/a/a/aallen1/MiscData');
addpath(sbci_dat)
addpath(prune_dat)
addpath(id_dat)
addpath(misc_data)

%% Load Needed Stuff
load('all_ids.mat')
load('batch_ids_'+string(batch_id)+'.mat')

%% Create Tensor Containing All Scan SC Matrices 
scan_tens = []; 
scan_id_match = []; 
sub_count = 1; 
for i = 1:10

    load('sc_ids_'+string(i)+'.mat')
    [r,c] = find(batch_ids(:,1) == sc_ids); 
    r_count = 1; 
    if isempty(c)
        continue
    else

        load('sbci_sc_tensor_'+string(i)+'.mat')
        for j = c.' 
           
           scan_sc = sbci_sc_tensor(:,:,j);
           scan_sc = scan_sc + scan_sc.' - 2*diag(diag(scan_sc)); 
           scan_sc = scToParc(parc,k,scan_sc,addDendo,horizCut); 
           
           scan_tens(:,:,sub_count) = scan_sc; 
           sub_count = sub_count + 1; 
           
           scan_id_match = [scan_id_match r(r_count)];
           r_count = r_count + 1; 
        
        end

    end

    clear sbci_sc_tensor; 
    clear scan_sc; 

end

load('scan_2_SC.mat','Y_scan_2') % Rescan Subjects
num_rescan = size(Y_scan_2,3);
test_retest_mat = zeros(num_rescan,899); % Total # of Subjects Hardcoded

for i = 1:num_rescan

    % Load Rescan matrix
    rescan_sc = Y_scan_2(:,:,i); %Rescan mats already symmetric
    rescan_sc = scToParc(parc,k,rescan_sc,addDendo,horizCut);

    for j = 1:size(scan_tens,3)
    
        test_retest_mat(i,scan_id_match(j)) = mean(diag(cor(rescan_sc,scan_tens(:,:,j))));
    end

end

clear rescan_sc; 
clear Y_scan_2; 


if addDendo
    save('retest_mats/fast_dendo_'+parc+'_'+string(k)+'_RETEST_MAT_'+string(batch_id)+'.mat',"test_retest_mat","scan_id_match","-v7.3")
elseif horizCut
    save('retest_mats/fast_horiz_'+parc+'_'+string(k)+'_RETEST_MAT_'+string(batch_id)+'.mat',"test_retest_mat","scan_id_match","-v7.3")
else
    save('retest_mats/fast_'+parc+'_'+string(k)+'_RETEST_MAT_'+string(batch_id)+'.mat',"test_retest_mat","scan_id_match","-v7.3")


end

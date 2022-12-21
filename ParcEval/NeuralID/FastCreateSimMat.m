function result = FastCreateSimMat(parc,k,batch_id)

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
load('batch_'+string(id)+'_ids.mat')

%% Loop through Retest Data
load('scan_2_SC.mat') % Rescan Subjects
num_rescan = size(Y_scan_2,3);
test_retest_mat = zeros(num_rescan,899); % Total # of Subjects Hardcoded 

for i = 1:num_rescan

    % Load Rescan matrix
    rescan_sc = Y_scan_2(:,:,i); %Rescan mats already symmetric
    rescan_sc = scToParc(parc,k,rescan_sc,addDendo); 

    for j = 1:10
    
        load('sc_ids_'+string(j)+'.mat')

        [r,c] = find(batch_ids(:,1) == sc_ids); 

        if isempty(c)
            continue
        else
            load('sbci_sc_tensor_'+string(j)+'.mat')
            
            for ind = c.' 

                % Load Scan Matrix
                scan_sc = sbci_sc_tensor(:,:,ind); 
                scan_sc = scan_sc + scan_sc.' - 2*diag(diag(scan_sc)); 
                scan_sc = scToParc(parc,k,scan_sc,addDendo); 

                find_place = batch_id(r(ind),2); 
                find_place = str2num(find_place); 
                test_retest_mat(i,find_place) = mean(diag(cor(rescan_sc,scan_sc)));

            end

        end
    
    end

    'FINISHED RESCANNED SUBJECT: ' + string(i)
    
end


if addDendo 
    save('results/fast_dendo_'+parc+'_'+string(k)+'_RETEST_MAT_'+string(batch_id)+'.mat',"test_retest_mat","-v7.3")
else
    save('results/fast_'+parc+'_'+string(k)+'_RETEST_MAT_'+string(batch_id)+'.mat',"test_retest_mat","-v7.3")
end

"FINISHED" + parc + "RETEST MATRIX"

clear all; 
result = 1; 

end

function result = gatherSilhouettes(parc)


%% Load SC Data
sbci_path = genpath('/pine/scr/a/a/aallen1/SBCI_Data/'); 
addpath(sbci_path)
misc_path = genpath('/pine/scr/a/a/aallen1/MiscData/');
addpath(misc_path)

load('mean_sc.mat')

%% Remove CC from Mean SC 

if size(mean_sc,1) >= 4120

    load('corpus_mask.mat')

    mean_sc(corpus_mask,:) = []; 
    mean_sc(:,corpus_mask) = []; 

end

%% Collect Sillhouette Values 

kseq = [5 10 15 25 50 68 75 100 125 150 175 200 225 250 275 300 325 350 375 400 425 450 475 500 600 700 800 900 1000];

mySils = zeros(4121,size(kseq,1));
col_count = 1; 

for k = kseq
    
    parc_idx = getParcIDX(parc,k,0); 

    sils = silhouette(mean_sc,parc_idx); 

    mySils(:,col_count) = sils;
   
    col_count = col_count + 1; 

end

save('Silhouette\'+parc+'_silhou_mat.mat','-v7.3')

end

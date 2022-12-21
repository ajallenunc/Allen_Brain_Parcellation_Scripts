%% Load Data
load('D:\Research\Tree Pruning\Data\SCData\HCP\mean_sc.mat')
load('D:\Research\Tree Pruning\Data\MiscData\HCP\corpus_mask.mat')
load('D:\Research\Tree Pruning\Data\MiscData\HCP\anti_corpus.mat')
mean_sc(corpus_mask,:) = []; 
mean_sc(:,corpus_mask) = []; 

%% Start KSeq Loop 

for k = [5 10 15 25 50 68 75 100 125 150 175 200 225 250 275 300 325 350 375 400]

    idx_kmeans_f = zeros(4121,1);
    idx_spect_f = zeros(4121,1);

    %% KMeans 
    idx_kmeans = kmeans(mean_sc,k); 
    idx_kmeans_f(anti_corpus) = idx_kmeans; 
    find_4 = find(idx_kmeans_f == 4); 
    idx_kmeans_f(find_4) = k+1; 
    idx_kmeans_f(corpus_mask) = 4; 

    %% SpectClust
    idx_spect = spectralcluster(mean_sc,k,'distance','precomputed'); 
    idx_spect_f(anti_corpus) = idx_spect; 
    find_4 = find(idx_spect_f == 4); 
    idx_spect_f(find_4) = k+1; 
    idx_spect_f(corpus_mask) = 4;    

    save('ClustAlgs/idx_kmeans_'+string(k)+'.mat','idx_kmeans_f')
    save('ClustAlgs/idx_spect_'+string(k)+'.mat','idx_spect_f')
end

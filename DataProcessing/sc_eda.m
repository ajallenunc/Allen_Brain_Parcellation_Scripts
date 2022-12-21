% Load Data
% Load SBCI Variables 
[sbci_parc, sbci_mapping, adjacency] = load_sbci_data('D:\Research\Tree Pruning\MatlabCode\SBCI_Stuff\example_data', 0.94);
sbci_surf = load_sbci_surface('D:\Research\Tree Pruning\MatlabCode\SBCI_Stuff\example_data');
%load('E:\Research\Tree Pruning\example_data\example_sc.mat')
%load('D:\Research\Tree Pruning\example_data\example_sc.mat'); % Example SC Matrix
%load('D:\Research\Tree Pruning\example_data\example_fc.mat'); % Example FC Matrix
%load('sc_geo_dist.mat')
% 
% % Takes top half of sc to make symmetric matrix
% sc_sym = tril(sc.',1) + triu(sc); 
% sc_dat = log((10^7*sc_sym)+1); % log transform data  
% 
% % FC data
% fc_sym = tril(fc.',1) + triu(fc); 
% fc_dat = fc_sym;  
% 
% load('adj_mesh.mat')

%%% Random Stuff %%%
% vtk_left = read_vtk('E:\Research\Tree Pruning\example_data\lh_sphere_avg_0.94.vtk'); 
% vtk_right = read_vtk('E:\Research\Tree Pruning\example_data\rh_sphere_avg_0.94.vtk'); 
% 
% tri_mesh_l = vtk_left.tri; 
% tri_mesh_r = vtk_right.tri; 
% 
% adj_mesh = zeros(4121); 
% for i = 1:2064
%     for j = i:2064
%         [row_find,~] = find(tri_mesh_l == i); 
%         adj_mesh(i,j) = ismember(j,tri_mesh_l(row_find,:)); 
%     end
% end
% for i = 1:2057
%     for j = i:2057
%         [row_find,~] = find(tri_mesh_r == i); 
%         adj_mesh(2064+i,2064+j) = ismember(j,tri_mesh_r(row_find,:)); 
%     end
% end
% adj_mesh = tril(adj_mesh.',1) + triu(adj_mesh); 
% adj_mesh = adj_mesh - diag(diag(adj_mesh));
%%%%%%%%%%%%%%%%%%%%%



% Geodesic Distance data

% % Histogram of Original Data
% figure(1)
% histogram(sc_sym(:))
% title('Histogram of Data (No Transforms)')
% 
% % Histogram of Transformed Data
% figure(2)
% histogram(sc_dat(:))
% title('Histogram of Data (Log(10^7*x+1) Tranformation)')
% 
% 
% % Heatmap of Original Data
% figure(3)
% imagesc(sc_sym);
% 
% xticks([]); xticklabels([]);
% yticks([]); yticklabels([]);
% title('Heatmap of Structural Connectivity Data (No Transforms)')
% 
% % Heatmap of Tranformed Data 
% figure(4)
% imagesc(sc_dat);
% 
% xticks([]); xticklabels([]);
% yticks([]); yticklabels([]);
% title('Heatmap of Structural Connectivity Data (Log(10^7*x+1) Tranformation)')
% 
% 
% Create Histogram of Rowsums
% figure(5)
% fc_rowsums = sum(fc_sym,2); 
% [B,I] = sort(fc_rowsums); 
% histogram(fc_rowsums)
% title('Histogram of FC Rowsums')
% 
% Create Scatterplot of Row mean vs Row Std. Dev
%  fc_rowmean = mean(fc_sym,2); 
%  fc_rowstd = std(fc_sym,0); 
%  figure(6)
%  scatter(fc_rowmean,fc_rowstd,50,'.')
%  title('Row mean vs Row Standard Deviation of FC Matrix')
% 
% % Create Histogram of Rowsums
% figure(7)
% sc_rowsums = sum(sc_dat,2); 
% [B,I] = sort(sc_rowsums); 
% histogram(sc_rowsums)
% title('Histogram of Rowsums (Log(10^7*x+1) Tranformation))')
% 
% %Create Scatterplot of Row mean vs Row Std. Dev
%  sc_rowmean = mean(sc_dat,2); 
%  sc_rowstd = std(sc_dat,0); 
%  figure(8)
%  scatter(sc_rowmean,sc_rowstd,50,'.')
%  title('Row mean vs Row Standard Deviation of SC Matrix (Log(10^7*x+1) Tranformation)')

% % Geodesic Distances vs Connectivity 
%lh_vtx = read_vtk('E:\Research\Tree Pruning\example_data\lh_sphere_avg_0.94.vtk').vtx;
%rh_vtx = read_vtk('E:\Research\Tree Pruning\example_data\rh_sphere_avg_0.94.vtk').vtx; 
% 
% lh_vtx = lh_vtx.'; 
% rh_vtx = rh_vtx.'; 
% 
% sc_vtx_combined = [lh_vtx; rh_vtx]; 
% 
% sc_geo_dist = pdist(sc_vtx_combined, @geodesic);
% sc_geo_dist = squareform(sc_geo_dist); 
% 
% for i = 1:4121
%     for j = 1:4121
%         if (i <= 2064 && j >= 2057)
%             sc_geo_dist(i,j) = 3.14; 
%         elseif (i <= 2057 && j >= 2064)
%             sc_geo_dist(i,j) = 3.14; 
%         end
%     end
% end

% sc_geo_dist(2064:4121, 2057:4121) = 3.14;
% sc_geo_dist(2057:4121, 2064:4121) = 3.14; 
%sc_geo_dist = sc_geo_dist - diag(diag(sc_geo_dist)); 

% Find and Remove NaN rows
%[na_rows, na_columns] = (find(isnan(patch_centers)));
%na_rows = unique(na_rows,'rows'); 
%patch_centers(na_rows,:) = []; 

% Compute Distance
% Left Side
% sc_geo_dist_l = pdist(patch_centers(1:2064,:),@geodesic); 
% 
% sc_sym_nona = sc_dat;
% %sc_sym_nona(na_rows,:)=[]; 
% %sc_sym_nona(:,na_rows)=[]; 
% sc_sym_nona = sc_sym_nona(1:2064,1:2064); 
% sc_sym_sq_l = squareform(sc_sym_nona); 
% 
% figure(3)
% scatter(sc_geo_dist_l,sc_sym_sq_l) 
% title('SC vs Geodesic Distance (Left Hemisphere)')
% 
% 
% l_geo_dist = pdist(lh_vtx, @geodesic);
% r_geo_dist = pdist(rh_vtx, @geodesic);

%%%%%%%% PCA %%%%%%%%%%%

% %[sc_pca_coef, sc_pca_score, sc_pca_latent] = pca(sc_dat); 
% 
% s = RandStream('mlfg6331_64'); % Random Number Stream
% rand_clusts = randsample(s,1:3000,500,false).'; 
% 
% sc_3700 = sc_sym(:,3700); 
% sc_3700 = sc_3700.'; 
% ind = [1:1:4121]; 
% scatter(ind,sc_3700,'filled');
% hold on 
% for reg = rand_clusts.'
%     sc_temp = sc_sym(:,reg); 
%     sc_temp = sc_temp.'; 
%     scatter(ind,sc_temp); 
% end



%%%%%%%% Functions %%%%%%%%%%%

function sc_geo_dist = create_geo_matrix()
lh_vtx = read_vtk('E:\Research\Tree Pruning\example_data\lh_sphere_avg_0.94.vtk').vtx; % Position of Region Center L
rh_vtx = read_vtk('E:\Research\Tree Pruning\example_data\rh_sphere_avg_0.94.vtk').vtx; % Position of Region Center R

% Create Geodesic Distance Matrix
lh_vtx = lh_vtx.'; 
rh_vtx = rh_vtx.'; 

sc_vtx_combined = [lh_vtx; rh_vtx]; 

sc_geo_dist = pdist(sc_vtx_combined, @geodesic);
sc_geo_dist = squareform(sc_geo_dist); 

for i = 1:4121
    for j = 1:4121
        if (i <= 2064 && j > 2064)
            sc_geo_dist(i,j) = 3.14;  
        elseif (j <= 2064 && i > 2064)
            sc_geo_dist(i,j) = 3.14;  
        end
    end
end

end

function [combo_dist_mat, combo_dist] = create_combo(weights,sc,fc,geo)
% Weights

w_1 = weights(1); 
w_2 = weights(2); 
w_3 = weights(3); 

% Prep Matrices
sc_dist = squareform(pdist(sc)); 
fc_dist = squareform(pdist(fc)); 

% Normalize Matrices 
sc_dist = sc_dist/(norm(sc_dist,'fro')); 
fc_dist = fc_dist/(norm(fc_dist,'fro')); 
geo = geo/(norm(geo,'fro')); 

% Create Distance Matrix Considering SC, FC, Geo
combo_dist_mat = w_1 * sc_dist + w_2 * fc_dist + w_3 * geo; 
combo_dist = squareform(combo_dist_mat); % Convert matrix to linkage input
end 

function geo_dist = geodesic(XI,XJ) % Function to calculate geodesic distance 
 n = size(XJ,1);
 dist = []; 
 for i = 1:n
      dist = [dist atan2(norm(cross(XI,XJ(i,:))),dot(XI,XJ(i,:)))];
 end
 geo_dist = dist;
end 

function D3 = euctry(XI,XJ)  
 n = size(XJ,1);
 dist = []; 
 for i = 1:n
      dist = [dist norm(XI - XJ(i,:))];
     %dist = [dist atan2(norm(cross(XI,XJ(i,:))),dot(XI,XJ(i,:)))];
 end
 D3 = dist;
end 






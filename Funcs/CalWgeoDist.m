function Wgeo = CalWgeoDist(adjcMatrix, weightMatrix, clipVal, geo_sigma)
% Compute boundary connecity values for all superpixels

% Code Author: Wangjiang Zhu
% Email: wangjiang88119@gmail.com
% Date: 3/24/2014
% Modified by Xiang Wang 5/10/2015


% No link boundary
adjcMatrix = tril(adjcMatrix, -1);
edgeWeight = weightMatrix(adjcMatrix > 0);
edgeWeight = max(0, edgeWeight - clipVal);
% Cal pair-wise shortest path cost (geodesic distance)
geoDistMatrix = graphallshortestpaths(sparse(adjcMatrix), 'directed', false, 'Weights', edgeWeight);

spNum = size(geoDistMatrix, 1);
Wgeo = exp(-geoDistMatrix.^2 ./ (2 * geo_sigma * geo_sigma));

if any(1 ~= Wgeo(1:spNum+1:end))
    error('Diagonal elements in the weight matrix should be 1');
end


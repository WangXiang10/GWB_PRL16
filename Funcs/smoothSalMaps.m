function salmapSm = smoothSalMaps(srcName, saliencymap)
srcImg = imread(srcName);
[idxImgGb, ~, adjcMatrixGb] = mexFelzenSegmentIndex(srcImg, 0.5, 50, 50); 
spNumGb = size(adjcMatrixGb, 1);
pixelListGb = cell(spNumGb, 1);
for n = 1:spNumGb
    pixelListGb{n} = find(idxImgGb == n);
end

salmapSm = saliencymap * 0;
for n = 1:spNumGb
    salmapSm(pixelListGb{n}) = mean(saliencymap(pixelListGb{n}));
end

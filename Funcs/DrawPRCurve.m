function [rec, prec, mae, a, b, c] = DrawPRCurve(SMAP, smapSuffix, GT, gtSuffix, targetIsFg, targetIsHigh, filename)
a = 0;
b = 0;
c = 0;
mae = 0;
% Draw PR Curves for all the image with 'smapSuffix' in folder SMAP
% GT is the folder for ground truth masks
% targetIsFg = true means we draw PR Curves for foreground, and otherwise
% we draw PR Curves for background
% targetIsHigh = true means feature values for our interest region (fg or
% bg) is higher than the remaining regions.
% color specifies the curve color

% Code Author: Wangjiang Zhu
% Email: wangjiang88119@gmail.com
% Date: 3/24/2014

files = dir(fullfile(SMAP, strcat('*', smapSuffix)));
num = length(files);
if 0 == num
    error('no saliency map with suffix %s are found in %s', smapSuffix, SMAP);
end

%precision and recall of all images
ALLPRECISION = zeros(num, 256);
ALLRECALL = zeros(num, 256);
for k = 1:num
    smapName = files(k).name;
    smapImg = imread(fullfile(SMAP, smapName));    
    smapImg = uint8(mynormalize(double(smapImg), 0, 255));
    gtName = strrep(smapName, smapSuffix, gtSuffix);
    gtImg = imread(fullfile(GT, gtName));
    if k == 64
        stop = 1;
    end
    [precision, recall] = CalPR(smapImg, gtImg, targetIsFg, targetIsHigh, k);
    gtImg2 = double(gtImg(:,:,1));
    smapImg2 = double(smapImg);
    mae_img = sum(sum(abs(smapImg2 ./ (max(smapImg2(:))+realmin) - gtImg2 ./ (max(gtImg2(:))+realmin))) ) / numel(gtImg2);
    mae = mae + mae_img;
    ALLPRECISION(k, :) = precision;
    ALLRECALL(k, :) = recall;
end

prec = mean(ALLPRECISION, 1);   %function 'mean' will give NaN for columns in which NaN appears.
rec = mean(ALLRECALL, 1);
mae = mae / num;
% plot
save(filename, 'prec', 'rec', 'mae');
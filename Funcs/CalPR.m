function [precision, recall] = CalPR(smapImg, gtImg, targetIsFg, targetIsHigh, k)
% Code Author: Wangjiang Zhu
% Email: wangjiang88119@gmail.com
% Date: 3/24/2014
eps = 10^(-8);
smapImg = double(smapImg(:,:,1));
if max(smapImg(:)) ~= 0
    smapImg = smapImg / max(smapImg(:)) * 255;
end
gtImg = double(gtImg(:,:,1));
gtImg = gtImg / max(gtImg(:)) * 255;
gtImg = gtImg(:,:,1) > 128;
smapImg = imresize(smapImg,[size(gtImg,1), size(gtImg,2)]);
if any(size(smapImg) ~= size(gtImg))
    error('saliency map and ground truth mask have different size');
end

if ~targetIsFg
    gtImg = ~gtImg;
end

gtPxlNum = sum(gtImg(:));
if 0 == gtPxlNum
    disp(k);
    warning(['error ',num2str(k),'\n']);
    error('no foreground region is labeled');
end

targetHist = histc(smapImg(gtImg), 0:255);
nontargetHist = histc(smapImg(~gtImg), 0:255);

if targetIsHigh
    targetHist = flipud(targetHist);
    nontargetHist = flipud(nontargetHist);
end
targetHist = cumsum( targetHist );
nontargetHist = cumsum( nontargetHist );

precision = targetHist ./ (targetHist + nontargetHist + eps);
if any(isnan(precision))
    warning('there exists NAN in precision, this is because of your saliency map do not have a full range specified by cutThreshes\n');
end
recall = targetHist / gtPxlNum;
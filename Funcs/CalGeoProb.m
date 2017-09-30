function [PrI_sal, PrI_bg, PrO_sal, PrO_bg, In_Ind, Out_Ind] = CalGeoProb(srcName, hull, LAYER)
%% Ackonwledegment
% Part of this code is from Wangjiang Zhu[1]
% [1] Wangjiang Zhu, Shuang Liang, Yichen Wei, and Jian Sun.
% Saliency Optimization from Robust Background Detection. In CVPR, 2014.

srcImg = imread(srcName);

% im = srcImg;%cv.cvtColor(srcImg,'RGB2HSV');
%      edges = {linspace(0,256,32+1), linspace(0,256,32+1), linspace(0,256,32+1)};
%      imt= double(im(:,:,1));
%      tic
%      h = cv.calcHist(imt(:),linspace(0,256,32+1), 'Uniform', false);
%      toc
%      tic
%      h2 = hist(imt(1:3000),32);
%      toc
%      Uniform


[h, w, ~] = size(srcImg);


imglbp = CalLbp(srcImg);

imglbp2 = CalLbp255(srcImg);


%% Segment input rgb image into patches
pixNumInSP = 600;                           % pixels in each superpixel
spnumber = round( h * w / pixNumInSP );     % super-pixel number for current image
if(size(srcImg,3) ~= 3)
    SrcImgCol = zeros(h, w, 3);
    SrcImgCol(:,:,1) = srcImg(:, :, 1);
    SrcImgCol(:,:,2) = srcImg(:, :, 1);
    SrcImgCol(:,:,3) = srcImg(:, :, 1);
    srcImg = SrcImgCol;
end


[idxImg, adjcMatrix, pixelList] = SLIC_Split(srcImg, spnumber);
% sp_out = draw_superpixels_bnd(idxImg, srcImg, 0);
% imwrite(sp_out, 'overview/res/1.png');
spNum = size(adjcMatrix, 1);

%% convert rgb to lab colorspace

SrcImgLab = colorspace('Lab<-', double(srcImg)/255);
SrcImgLab(:,:,1) = SrcImgLab(:,:,1) * 2.5;
SrcImgLab(:,:,2) = SrcImgLab(:,:,2) + 128;
SrcImgLab(:,:,3) = SrcImgLab(:,:,3) + 128;
SrcImgLab = round(SrcImgLab);

%% Calculate the feature similarities
% meanPosSlic = GetNormedMeanPos(pixelList, h, w);

% pixelListT = cell(spNum, 1);
% for n = 1:spNum
%     pixelListT{n} = find(idxImg' == n);
% end


ColorSim = ColorSimimaritySpeedUp(SrcImgLab, pixelList, 32);                       % Color similarity]



% ColorSimMex = ColorSimimarity_mex(SrcImgLab, pixelListT, 32);
% ColorDistM = 1 - ColorSim;
% LbpDistM = GetLbpDistanceMatrix(imglbp, pixelList, spNum);
% PosDistM = GetDistanceMatrix(meanPosSlic);


LbpSim = LbpSimimarity(imglbp, pixelList, 32);

% Texture similarity


ComBorRat = CommonBorderRatioSpeedUp(SrcImgLab, pixelList, idxImg, adjcMatrix);    % Common Border Ratio

%% Combined similarity

w_rp = [8.9893, 2.2544, 1.4030, -3.2761];                                   % Parameters learned using SVM
% w_rp = [4.8227, 4.5875, 2.5811, -6.2705];
comSim = w_rp(1) * ColorSim  + w_rp(2) * LbpSim + w_rp(3) * ComBorRat +  w_rp(4);

EdgeWeight = 1./(1 + exp(-comSim / 3));
EdgeWeight = 1 - EdgeWeight;                                                % Edge Weight
EdgeWeight(1: spNum + 1 :end) = 0;

[clipValrg, geoSigmarg] = EstimateDynamicParasrg(adjcMatrix, EdgeWeight);

%% Geodesic Distance
% two-layer neighbor

if LAYER == 2
    adjcMatrix2 = adjcMatrix;
    for i = 1: size(adjcMatrix, 1)
        Ni = find(adjcMatrix(i, :) ~= 0);
        adjcMatrix2(:, Ni) = bsxfun(@plus, adjcMatrix(:, i), adjcMatrix2(:, Ni)) ;
    end
    adjcMatrix2 = full(double(adjcMatrix2 > 0));
    adjcMatrix = adjcMatrix2;
end



WgeoDist = CalWgeoDist(adjcMatrix, EdgeWeight, clipValrg, geoSigmarg);
%% Extracting Initial Salient Regions
% Ctr = CalContrast(max(LbpDistM, ColorDistM), PosDistM);
% [CtrImg, ~] = CreateImageFromSPs(Ctr, pixelList, h, w, true);
% salhull = find(CtrImg ~= 0);
% thresh = mean(CtrImg(salhull));
% thresh = mean([thresh th]);
% IniSalReg = double(CtrImg >= thresh);


maxVal = max(hull(:));
IniSalReg = (hull > maxVal / 2);
In_Ind = find(IniSalReg == 1 );
Out_Ind = find(IniSalReg == 0);
SalSPs = [];
for si = 1: spNum
    if sum(IniSalReg(pixelList{si})) >= 0.5 * length(pixelList{si})
        SalSPs = [SalSPs, si];
    end
end

%% Calculate probabilities of the Bayesian formulation

[PrI_sal, PrI_bg, PrO_sal, PrO_bg] = likelihoodprobSPSpeedUp(double(SrcImgLab), imglbp2, In_Ind, Out_Ind, pixelList, SalSPs, WgeoDist);



function [PrI_sal, PrI_bg, PrO_sal, PrO_bg] = likelihoodprobSPSpeedUp(input_imlab, imglbp, ind, out_ind, pixelListSlic, hullSP, Wgeo)
%% Ackonwledegment
% this code is modified from [1]
% [1] Yulin Xie, Huchuan Lu, M.-H. Y. (2013). Bayesian Saliency via Low and Mid Level Cues. In TIP (Vol. 22, pp. 1757¨C1761).

imsize = numel((ind)) +  numel((out_ind));
mat_im = [reshape(input_imlab(:,:,1),1,imsize);reshape(input_imlab(:,:,1),1,imsize);reshape(input_imlab(:,:,1),1,imsize)];
maxValI = max(mat_im(:,ind),[],2);
minValI = min(mat_im(:,ind),[],2);
maxValO = max(mat_im(:,out_ind),[],2);
minValO = min(mat_im(:,out_ind),[],2);
numBin = [60,60,60,60,100,100,100]; % Number of bins in histogram

maxValI(4) = max(imglbp(:));
minValI(4) = min(imglbp(:));
maxValO(4) = max(imglbp(:));
minValO(4) = min(imglbp(:));

if max(imglbp(:)) == 255
    numBin(4) = 60;
    
elseif max(imglbp(:)) == 58
    numBin(4) = 58;
end

PrI_Hist = 0;
PrO_Hist = 0;
Sum_W_Sal = 0;
Sum_W_Bg = 0;
spNum = length(pixelListSlic);

%% hist
input_imlab_Ind_In = zeros(imsize, 3);
input_imlab_Ind_Out = zeros(imsize, 3);
for i = 1: 3
    cur_im = input_imlab(:,:,i);
    input_imlab_Ind_In(:, i) = max( min(ceil(numBin(i)*(double(cur_im(:)-minValI(i))/(maxValI(i)-minValI(i)))),numBin(i)),1);
    input_imlab_Ind_Out(:, i) = max( min(ceil(numBin(i)*(double(cur_im(:)-minValO(i))/(maxValO(i)-minValO(i)))),numBin(i)),1);
end

i = 4;

imglbp_Ind_In  = max( min(ceil(numBin(i)*(double(imglbp(:)-minValI(i))/(maxValI(i)-minValI(i)))),numBin(i)),1);
imglbp_Ind_Out = max( min(ceil(numBin(i)*(double(imglbp(:)-minValO(i))/(maxValO(i)-minValO(i)))),numBin(i)),1);

bgSP = setdiff((1:spNum), hullSP);

for k = hullSP
    PrI_salSP = ind * 0;
    delta = 1;
    
    for i = 1: 3
        edges = linspace(1, numBin(i) + 1, numBin(i) + 1);
        dataMat = input_imlab_Ind_In(pixelListSlic{k}, i);
        innerHist = cv.calcHist(dataMat, edges);
        innerHist = innerHist ./ sum(innerHist);
        
        PrI_salSP(delta: delta + length(innerHist) - 1) = innerHist;
        delta = delta + length(innerHist);
    end
    
    i = 4;
    edges = linspace(1, numBin(i) + 1, numBin(i) + 1);
    dataMat = imglbp_Ind_In(pixelListSlic{k});
    innerHist = cv.calcHist(dataMat, edges);
    innerHist = innerHist ./ sum(innerHist);

    PrI_salSP(delta: delta + length(innerHist) - 1) = innerHist;
    
    
    PrI_Hist = PrI_Hist + PrI_salSP  * mean(Wgeo(k, hullSP)) ;%*  mean(LbpSim(k, hullSP));
    Sum_W_Sal = Sum_W_Sal +  mean(Wgeo(k, hullSP));% *  mean(LbpSim(k, hullSP));
end


PrO_bgSP = out_ind * 0 ;
delta = 1;
for i = 1: 3
    
    edges = linspace(1, numBin(i) + 1, numBin(i) + 1);
    dataMat = input_imlab_Ind_Out(out_ind, i);
    outerHist = cv.calcHist(dataMat, edges);
    outerHist = outerHist ./ sum(outerHist);

    
    PrO_bgSP(delta: delta + length(outerHist) - 1) = outerHist;
    delta = delta + length(outerHist);
    
end

i = 4;

edges = linspace(1, numBin(i) + 1, numBin(i) + 1);
dataMat = imglbp_Ind_Out(out_ind);
outerHist = cv.calcHist(dataMat, edges);
outerHist = outerHist ./ sum(outerHist);
      

PrO_bgSP(delta: delta + length(outerHist) - 1) = outerHist;
for k = bgSP
    PrO_Hist = PrO_Hist + PrO_bgSP  * mean(Wgeo(k, hullSP));% *  mean(LbpSim(k, hullSP));
    Sum_W_Bg = Sum_W_Bg +  mean(Wgeo(k, hullSP));% *  mean(LbpSim(k, hullSP));
end

PrI_Hist = PrI_Hist / Sum_W_Sal;
PrO_Hist = PrO_Hist / Sum_W_Bg;
delta = 0;
PrI_sal = 1;
PrO_bg = 1;
PrI_bg = 1;
PrO_sal = 1;

for i = 1: 3
    
    inInd = input_imlab_Ind_In(ind, i);
    outInd = input_imlab_Ind_Out(out_ind, i);
        
    PrI_sal = PrI_sal .* PrI_Hist(inInd + delta);
    PrI_bg = PrI_bg .* PrO_Hist(inInd + delta);
    PrO_bg = PrO_bg .* PrO_Hist(outInd + delta);
    PrO_sal = PrO_sal .* PrI_Hist(outInd + delta);
    delta = delta + numBin(i);
end


inInd = imglbp_Ind_In(ind);
outInd = imglbp_Ind_Out(out_ind);
PrI_sal = PrI_sal .* PrI_Hist(inInd + delta);
PrI_bg = PrI_bg .* PrO_Hist(inInd + delta);
PrO_bg = PrO_bg .* PrO_Hist(outInd + delta);
PrO_sal = PrO_sal .* PrI_Hist(outInd + delta);




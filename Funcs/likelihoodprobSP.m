function [PrI_sal, PrI_bg, PrO_sal, PrO_bg] = likelihoodprobSP(input_imlab, imglbp, ind, out_ind, pixelListSlic, hullSP, Wgeo)
%% Ackonwledegment
% this code is modified from [1]
% [1] Yulin Xie, Huchuan Lu, M.-H. Y. (2013). Bayesian Saliency via Low and Mid Level Cues. In TIP (Vol. 22, pp. 1757–1761). 

imsize = numel((ind)) +  numel((out_ind));
mat_im = [reshape(input_imlab(:,:,1),1,imsize);reshape(input_imlab(:,:,1),1,imsize);reshape(input_imlab(:,:,1),1,imsize)];
maxValI = max(mat_im(:,ind),[],2);
minValI = min(mat_im(:,ind),[],2);
maxValO = max(mat_im(:,out_ind),[],2);
minValO = min(mat_im(:,out_ind),[],2);
numBin=[60,60,60,60,100,100,100]; % Number of bins in histogram
smoothFactor=[5,6,6,6,6,6,6]; % Smoothing factor
smoothingKernel=cell(1,7);

maxValI(4) = max(imglbp(:));
minValI(4) = min(imglbp(:));
maxValO(4) = max(imglbp(:));
minValO(4) = min(imglbp(:));
if max(imglbp(:)) == 255
    numBin(4) = 60;
    smoothFactor(4) = 6;
elseif max(imglbp(:)) == 58
    numBin(4) = 58;
    smoothFactor(4) = 6;
end

PrI_Hist = 0;%numel(ind)/(row*col)
PrO_Hist = 0;
Sum_W_Sal = 0;
Sum_W_Bg = 0;
spNum = length(pixelListSlic);

%% hist
input_imlab_Ind_In = zeros(imsize, 3);
input_imlab_Ind_Out = zeros(imsize, 3);
for i = 1: 3
    cur_im = input_imlab(:,:,i);
%     input_imlab_Ind_In(:,:, i) = round( (cur_im - minValI(i)) ./ ( maxValI(i) - minValI(i) ) * (numBin(i) -  1) + 1);
%     input_imlab_Ind_Out(:,:, i) = round( (cur_im - minValO(i)) ./ ( maxValO(i) - minValO(i) ) * (numBin(i) -  1) + 1);
    input_imlab_Ind_In(:, i)= max( min(ceil(numBin(i)*(double(cur_im(:)-minValI(i))/(maxValI(i)-minValI(i)))),numBin(i)),1);
    input_imlab_Ind_Out(:, i)= max( min(ceil(numBin(i)*(double(cur_im(:)-minValO(i))/(maxValO(i)-minValO(i)))),numBin(i)),1);
end

i = 4;

imglbp_Ind_In  = max( min(ceil(numBin(i)*(double(imglbp(:)-minValI(i))/(maxValI(i)-minValI(i)))),numBin(i)),1);
imglbp_Ind_Out = max( min(ceil(numBin(i)*(double(imglbp(:)-minValO(i))/(maxValO(i)-minValO(i)))),numBin(i)),1);

%%
for k = 1: spNum
    if ismember(k, hullSP)
        PrI_salSP = ind * 0;
        delta = 1;
        for i = 1: 3
%             cur_im = input_imlab(:,:,i);
%             dataMat = cur_im(pixelListSlic{k});
%             [innerHist2,~] = ComputeHistogram(dataMat,numBin(i),minValI(i),maxValI(i));
            %%
            dataMat = input_imlab_Ind_In(pixelListSlic{k}, i);
            innerHist = ComputeHistogramSpeedUp(dataMat,numBin(i));
%             tmp = innerHist - innerHist2;
%             if sum(abs(tmp)) ~= 0
%                 disp('stop1');
%                
%             end
            %%
            smoothingKernel{i} = getSmoothKernel_(smoothFactor(i));
            innerHist = filterDistribution_(smoothingKernel{i},innerHist',numBin(i));
            
            PrI_salSP(delta: delta + length(innerHist) - 1) = innerHist;
            delta = delta + length(innerHist);
        end
        i = 4;
        dataMat = imglbp_Ind_In(pixelListSlic{k});
        innerHist = ComputeHistogramSpeedUp(dataMat,numBin(i));
        smoothingKernel{i} = getSmoothKernel_(smoothFactor(i));
        innerHist = filterDistribution_(smoothingKernel{i},innerHist',numBin(i));
        PrI_salSP(delta: delta + length(innerHist) - 1) = innerHist;
        
        
        PrI_Hist = PrI_Hist + PrI_salSP  * mean(Wgeo(k, hullSP)) ;%*  mean(LbpSim(k, hullSP));
        Sum_W_Sal = Sum_W_Sal +  mean(Wgeo(k, hullSP));% *  mean(LbpSim(k, hullSP));
        
    else
        PrO_bgSP = out_ind * 0 ;
        delta = 1;
        for i = 1: 3
%             cur_im = input_imlab(:,:,i);
%             dataMat = cur_im(out_ind);
%             [outerHist2,~] = ComputeHistogram(dataMat,numBin(i),minValO(i),maxValO(i));
            dataMat = input_imlab_Ind_Out(out_ind, i);
            outerHist = ComputeHistogramSpeedUp(dataMat,numBin(i));
            
%             tmp = outerHist - outerHist2;
%             if sum(abs(tmp)) ~= 0
%                 disp('stop2');
%                 
%             end
            
            smoothingKernel{i}=getSmoothKernel_(smoothFactor(i));
            outerHist=filterDistribution_(smoothingKernel{i},outerHist',numBin(i));
            
            PrO_bgSP(delta: delta + length(outerHist) - 1) = outerHist;
            delta = delta + length(outerHist);
            
        end
        
        i = 4;
        dataMat = imglbp_Ind_Out(out_ind);
        outerHist = ComputeHistogramSpeedUp(dataMat, numBin(i));
        smoothingKernel{i} = getSmoothKernel_(smoothFactor(i));
        outerHist = filterDistribution_(smoothingKernel{i},outerHist',numBin(i));
        PrO_bgSP(delta: delta + length(outerHist) - 1) = outerHist;
        
        PrO_Hist = PrO_Hist + PrO_bgSP  * mean(Wgeo(k, hullSP));% *  mean(LbpSim(k, hullSP));
        Sum_W_Bg = Sum_W_Bg +  mean(Wgeo(k, hullSP));% *  mean(LbpSim(k, hullSP));
    end
end
PrI_Hist = PrI_Hist / Sum_W_Sal;
PrO_Hist = PrO_Hist / Sum_W_Bg;
delta = 0;
PrI_sal = 1;
PrO_bg = 1;
PrI_bg = 1;
PrO_sal = 1;
for i = 1: 3
%     cur_im = input_imlab(:,:,i);
%     dataMat = cur_im(ind);
%     inInd = max( min(ceil(numBin(i) * (double(dataMat - minValI(i)) / (maxValI(i) - minValI(i)))), numBin(i)), 1);
%     dataMat = cur_im(out_ind);
%     outInd = max( min(ceil(numBin(i) * (double(dataMat -minValO(i)) / (maxValO(i) - minValO(i)))), numBin(i)), 1);
    
    inInd = input_imlab_Ind_In(ind, i);
    outInd = input_imlab_Ind_Out(out_ind, i);
    
    PrI_sal = PrI_sal .* PrI_Hist(inInd + delta);
    PrI_bg = PrI_bg .* PrO_Hist(inInd + delta);
    PrO_bg = PrO_bg .* PrO_Hist(outInd + delta);
    PrO_sal = PrO_sal .* PrI_Hist(outInd + delta);
    delta = delta + numBin(i);
end


% dataMat = imglbp(ind);
% inInd = max( min(ceil(numBin(i) * (double(dataMat - minValI(i)) / (maxValI(i) - minValI(i)))), numBin(i)), 1);
% dataMat = imglbp(out_ind);
% outInd = max( min(ceil(numBin(i) * (double(dataMat -minValO(i)) / (maxValO(i) - minValO(i)))), numBin(i)), 1);
inInd = imglbp_Ind_In(ind);
outInd = imglbp_Ind_Out(out_ind);

PrI_sal = PrI_sal .* PrI_Hist(inInd + delta);
PrI_bg = PrI_bg .* PrO_Hist(inInd + delta);
PrO_bg = PrO_bg .* PrO_Hist(outInd + delta);
PrO_sal = PrO_sal .* PrI_Hist(outInd + delta);


function intHist = ComputeHistogramSpeedUp(binInd,numBin)
%% function [intHist,binInd]=ComputeHistogram(dataMat,numBin,minVal,maxVal)
%input:
%  dataMat:L or A orB with inner or outer index
%  numBin: number of bins
%  minVal: mimimal value of dataMat
%  maxVal: maximal value of dataMat
%output:
%  intHist: histogram of dataMat
%  binInd : regularized image

intHist=zeros(numBin,1);

binIndTmp = tabulate(binInd);
intHist(1:max(binInd)) = binIndTmp(:, 2);

function [intHist,binInd]=ComputeHistogram(dataMat,numBin,minVal,maxVal)
%% function [intHist,binInd]=ComputeHistogram(dataMat,numBin,minVal,maxVal)
%input:
%  dataMat:L or A orB with inner or outer index
%  numBin: number of bins
%  minVal: mimimal value of dataMat
%  maxVal: maximal value of dataMat
%output:
%  intHist: histogram of dataMat
%  binInd : regularized image

binInd = max( min(ceil(numBin*(double(dataMat-minVal)/(maxVal-minVal))),numBin),1);% 将像素值 转换到[1 - 60]之间，大小中原图等同
intHist=zeros(numBin,1);
for i = 1:length(dataMat)
    intHist(binInd(i))=intHist(binInd(i))+1;
end
%% Get smoothing filter
function [smKer]=getSmoothKernel_(sigma)

if sigma==0
    smKer=1;
    return;
end

dim=length(sigma); % row, column, third dimension
sz=max(ceil(sigma*2),1);
sigma=2*sigma.^2;

if dim==1
    d1=-sz(1):sz(1);
    
    smKer=exp(-((d1.^2)/sigma));
    
elseif dim==2
    [d2,d1]=meshgrid(-sz(2):sz(2),-sz(1):sz(1));
    
    smKer=exp(-((d1.^2)/sigma(1)+(d2.^2)/sigma(2)));
    
elseif dim==3
    [d2,d1,d3]=meshgrid(-sz(2):sz(2),-sz(1):sz(1),-sz(3):sz(3));
    
    smKer=exp(-((d1.^2)/sigma(1)+(d2.^2)/sigma(2)+(d3.^2)/sigma(3)));
    
else
    error('Not implemented');
end

smKer=smKer/sum(smKer(:));





%% Smooth distribution
function dist=filterDistribution_(filterKernel,dist,numBin)

if numel(filterKernel)==1
    dist=dist(:)/sum(dist(:));
    return;
end

numDim=length(numBin);

if numDim==1
    %smoothDist=conv(dist,filterKernel,'same');
    
    lenDist=length(dist);
    hlenKernel=(length(filterKernel)-1)/2;
    
    dist = [dist(1) * ones(1, hlenKernel), dist, dist(end) * ones(1, hlenKernel)];
    dist = conv(dist, filterKernel);
    lenSmoothDist = length(dist);
    offset = (lenSmoothDist - lenDist)/2;
    dist = dist((offset + 1):(lenSmoothDist - offset));
    
elseif numDim==2
    dist=reshape(dist,numBin);
    
    dist=conv2(filterKernel,filterKernel,dist,'same');
    
else
    dist=reshape(dist,numBin);
    
    for i=1:numDim
        fker=ones(1,numDim);
        fker(i)=length(filterKernel);
        fker=zeros(fker);
        fker(:)=filterKernel(:);
        
        dist=convn(dist,fker,'same');
        
    end
    
end

dist=dist(:)/sum(dist(:));
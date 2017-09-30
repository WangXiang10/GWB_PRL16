function LbpSim = LbpSimimarity(imglbp, pixelList, bins)
imglbp = mynormalize(imglbp, 0, 255);
spnum = size(pixelList, 1);
spHist = zeros(spnum, bins);
edges = linspace(0,256,bins+1);


for i = 1: spnum
    var = imglbp(pixelList{i});
    len = length(pixelList{i});
    spHist(i,:) = cv.calcHist(var, edges)'/len;
end

LbpSim = squareform(pdist(spHist,@distfun));
LbpSim(1: spnum + 1 : end) = 1;
% LbpSim = ones(spnum, spnum)*NaN;
% for i = 1 : spnum-1
%     LbpSim(i, i) = 1;
%     for j = i + 1 : spnum
%         LbpSim(i, j) = sum(min(spHist{i}, spHist{j}));
%         LbpSim(j, i) = LbpSim(i, j);
%     end
% end
% LbpSim(spnum, spnum) = 1;
end
        

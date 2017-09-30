
function ColorSim = ColorSimimaritySpeedUp(noFrameImgLab, pixelList, bins)
spnum = size(pixelList, 1);
spHist = zeros(spnum, bins * 3);

edges = linspace(0,256,bins+1);
L = noFrameImgLab(:,:,1);
A = noFrameImgLab(:,:,2);
B = noFrameImgLab(:,:,3);

for i = 1:spnum
    
    
    varL = L(pixelList{i});
    varA = A(pixelList{i});
    varB = B(pixelList{i});
    
    len = length(pixelList{i});
    spHist(i,:) = [cv.calcHist(varL, edges)'/len, cv.calcHist(varA, edges)'/len, cv.calcHist(varB, edges)'/len] / 3;

end

ColorSim = squareform(pdist(spHist,@distfun));
ColorSim(1: spnum + 1 : end) = 1;

end


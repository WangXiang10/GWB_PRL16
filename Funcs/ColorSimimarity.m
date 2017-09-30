function ColorSim = ColorSimimarity(noFrameImgLab, pixelList, bins)
spnum = size(pixelList, 1);
spHist = cell(1, spnum);
for i = 1:spnum
   
    L = noFrameImgLab(:,:,1);
    A = noFrameImgLab(:,:,2);
    B = noFrameImgLab(:,:,3);
    varL = L(pixelList{i});
    varA = A(pixelList{i});
    varB = B(pixelList{i});
    
    binL = Calbin(varL,bins);
    binA = Calbin(varA,bins);
    binB = Calbin(varB,bins);
   
    bin = binL*bins*bins + binA*bins + binB;
    
    spHist{i} = hist(bin,0:bins*bins*bins-1)/length(pixelList{i});
   
end
ColorSim = ones(spnum, spnum);

for i = 1:spnum-1
    for j = i+1:spnum
        ColorSim(i, j) = sum(min(spHist{i}, spHist{j}));
        ColorSim(j, i) = ColorSim(i, j);
    end
end

end
        

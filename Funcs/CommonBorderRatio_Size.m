function [ComBorRat, fSize] = CommonBorderRatio_Size(noFrameImgLab, pixelList, idxImg, adjcMatrix)
adjcMatrix = full(adjcMatrix);
spnum = size(pixelList, 1);
[h, w] = size(noFrameImgLab(:,:,1));
region_prop = regionprops(idxImg,'Perimeter','FilledArea');
%Get edge pixel locations (4-neighbor)
topbotDiff = diff(idxImg, 1, 1) ~= 0;
topEdgeIdx = find( padarray(topbotDiff, [1 0], false, 'post') ); %those pixels on the top of an edge
botEdgeIdx = topEdgeIdx + 1;

leftrightDiff = diff(idxImg, 1, 2) ~= 0;
leftEdgeIdx = find( padarray(leftrightDiff, [0 1], false, 'post') ); %those pixels on the left of an edge
rightEdgeIdx = leftEdgeIdx + h;
it = idxImg(topEdgeIdx); 
ib = idxImg(botEdgeIdx);
il = idxImg(leftEdgeIdx);
ir = idxImg(rightEdgeIdx);
ComBorRat = zeros(spnum, spnum);
fSize = zeros(spnum, spnum);
for i = 1:spnum-1
    ComBorRat(i, i) = 1;
    fSize(i, i) = 1;
    for j = i+1:spnum
        if adjcMatrix(i, j) ~= 0 
            len = [intersect(find(it == i),find(ib == j))',intersect(find(it == j),find(ib == i))',...
                intersect(find(il == i),find(ir == j))',intersect(find(il == j),find(ir == i))'];
           ComBorRat(i, j) = max(length(unique(len))/region_prop(i).Perimeter, length(unique(len))/region_prop(j).Perimeter); 
           ComBorRat(j, i) = ComBorRat(i, j);
           fSize(i, j) = 1 - (region_prop(i).FilledArea + region_prop(j).FilledArea)/(h * w);
           fSize(j, i) = fSize(i, j);
        end
    end
end
ComBorRat(spnum, spnum) = 1;
fSize(spnum, spnum) = 1;
end
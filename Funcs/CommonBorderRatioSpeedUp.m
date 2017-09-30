function ComBorRat = CommonBorderRatioSpeedUp(rgb, pixelList, idxImg, adjcMatrix)
%%
% 基本思想：
% 不考虑角点，则边界上的点只能属于两个区域，找到每个边界点属于的区域即可计算交接长度
%%

labels = unique(idxImg);
spNum = length(labels);

% compute means and edges
e = zeros(size(idxImg));
s = zeros(size(idxImg));
se = zeros(size(idxImg));

e(:,1:end-1) = idxImg(:,2:end);
s(1:end-1,:) = idxImg(2:end,:);
se(1:end-1,1:end-1) = idxImg(2:end,2:end);

edges = (idxImg~=e | idxImg~=s | idxImg~=se);
edges(end,:) = (idxImg(end,:)~=e(end,:));
edges(:,end) = (idxImg(:,end)~=s(:,end));
edges(end,end) = 0;

edgeInd = find(edges == 1);

[h, w] = size(idxImg);
bnd = sub2ind([h, w], ones(1, w), 1: w);
bnd = [bnd, sub2ind([h, w], h * ones(1, w), 1: w)];
bnd = [bnd, sub2ind([h, w], 1: h, ones(1, h))];
bnd = [bnd, sub2ind([h, w], 1: h, w * ones(1, h))];
% 去掉图像边缘上的点
edgeInd = setdiff(edgeInd, bnd);


edge1 = edgeInd - 1;
edge2 = edgeInd + 1;
edge3 = edgeInd - size(idxImg, 1);
edge4 = edgeInd + size(idxImg, 1);

reg1 = idxImg(edge1);
reg2 = idxImg(edge2);
reg3 = idxImg(edge3);
reg4 = idxImg(edge4);

% reg = [reg1, reg2, reg3, reg4];
% regEdge = [];
% tic
% for i =  1: size(reg, 1)
%     tmp = sort(unique(reg(i, :)));
%     if length(tmp) ~= 1
%         regEdge = [regEdge; tmp(1:2), tmp(1) * num_sp + tmp(2)];
%     end
% end

regEdge = [reg1, reg2];
tmp = regEdge(:, 1) - regEdge(:, 2);
f0 = find(tmp == 0);
regEdge(f0, 2) = reg3(f0);
tmp = regEdge(:, 1) - regEdge(:, 2);
f0 = find(tmp == 0);
regEdge(f0, 2) = reg4(f0);
tmp = regEdge(:, 1) - regEdge(:, 2);
f0 = find(tmp == 0);
regEdge(f0, :) = [];

regEdge = sort(regEdge, 2);
regEdge(:, 3) = regEdge(:, 1) * spNum + regEdge(:, 2);
regSide = tabulate([regEdge(:,1); regEdge(:,2)]);
regSide = regSide(:, 2);
comSide = tabulate(regEdge(:, 3));
comSide = comSide(:, 2);
comSide(end+1: spNum * spNum) = 0;

ComBorRat = zeros(spNum, spNum);
for i = 1: spNum - 1
    ComBorRat(i, i) = 1;
    for j = i + 1: spNum
        if adjcMatrix(i, j)
            ComBorRat(i, j) = max(comSide(i * spNum + j ) / regSide(i), comSide(i * spNum + j ) / regSide(j));
            ComBorRat(j, i) =  ComBorRat(i, j);
        end
    end
end
ComBorRat(spNum, spNum) = 1;

end




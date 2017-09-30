function lbpDistM = GetLbpDistanceMatrix(imglbp, pixelList, spNum)
histlbp = cell(1, spNum);
bins = 32;
for i = 1:spNum
    tmp = hist(imglbp(pixelList{i}), 0: bins - 1)';
    histlbp{i} = tmp/sum(tmp);
    %                 lbpList{i} = vl_homkermap(histlbp{i}, 10);
end
lbpDistM = ones(spNum, spNum);
for i = 1:spNum-1
    for j = i+1:spNum
%         lbpDistM(i,j) = vl_alldist(histlbp{i}, histlbp{j}, 'kchi2') ;
        lbpDistM(i,j) = sum(min(histlbp{i}, histlbp{j}));
        lbpDistM(j,i) = lbpDistM(i,j);
    end
end
lbpDistM = 1 - lbpDistM;
end
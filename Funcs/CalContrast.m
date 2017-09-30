function wCtr = CalContrast(colDistM, posDistM )
% Calculate background probability weighted contrast

% Code Author: Wangjiang Zhu
% Email: wangjiang88119@gmail.com
% Date: 3/24/2014
% aera = sqrt(aera);
% aeraMatrix = aera * aera';
spaSigma = 0.4;     %sigma for spatial weight
posWeight = Dist2WeightMatrix(posDistM, spaSigma);

%bgProb weighted contrast
% wCtr = colDistM .* posWeight./aeraMatrix * bgProb;
wCtr = sum(colDistM .* posWeight, 2);
% wCtr = wCtr.*(log(1+bgProb));
wCtr = (wCtr - min(wCtr)) / (max(wCtr) - min(wCtr) + eps);

%post-processing for cleaner fg cue
removeLowVals = true;
if removeLowVals
    thresh = graythresh(wCtr);  %automatic threshold
    wCtr(wCtr < thresh) = 0;
end
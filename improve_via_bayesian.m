

for k = 1:len
    tic
    disp(k)
    srcName = [Src, '\', files(k).name];
    [~, noSuffixName, ~] = fileparts(srcName);
    [pathstr, name, ext] = fileparts(files(k).name);
    salname = [Result, '\', noSuffixName, '_GWB.png'];
    
    % Calculate Probabilities in the Bayesian Formulation
    iniRegion = double(imread([IniSalRegion, '\', name, crfSuffix]));
    iniRegion = iniRegion(:,:, 1);
    
    [PrI_sal, PrI_bg, PrO_sal, PrO_bg, In_Ind, Out_Ind] = CalGeoProb(srcName, iniRegion, 2);
    
    
    psalName = strrep(files(k).name, srcSuffix, OriSauffix);
    psal = imread([OriSalMaps, '\', psalName]);
    
    % Calculate improved salienct map using GWB
    
    salmap = CalImprovedMap(psal, PrI_sal, PrI_bg, PrO_sal, PrO_bg, In_Ind, Out_Ind);
    
    % Smooth saliency map using graph-based segmentation
    % salmap = smoothSalMaps(srcName, salmap);
    imwrite(salmap, salname);
    
    figure;
    subplot(121);
    imshow(psal);
    title('RC');
    subplot(122);
    imshow(salmap);
    title('RC\_improved')
    toc
end


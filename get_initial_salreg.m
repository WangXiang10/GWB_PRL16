
for i = 1:len
    disp(i);
    
    image = imread([Src, '\', files(i).name]);
    if length(size(image)) == 2
        img3 = zeros(size(image,1), size(image,2), 3);
        img3(:,:,1) = image;
        img3(:,:,2) = image;
        img3(:,:,3) = image;
        image = img3;
    end
    
    [pathstr, name, ext] = fileparts(files(i).name);
    % LBP
    imglbp = CalLbp(image);
    % Superpixel 
    [h, w, chn] = size(image);
    pixNumInSP = 600;
    spnumber = round( h * w / pixNumInSP );
    
    [idxImg, adjcMatrix, pixelList] =  SLIC_Split(image, spnumber);
    
    
    spNum = size(adjcMatrix , 1);
    
    %% RGB to LAB
    imageLab = colorspace('Lab<-', double(image)/255);
    imageLab(:,:,1) = imageLab(:,:,1) * 2.5;
    imageLab(:,:,2) = imageLab(:,:,2) + 128;
    imageLab(:,:,3) = imageLab(:,:,3) + 128;
    imageLab = round(imageLab);
    
    %% Get super-pixel properties
    
    meanRgbCol = GetMeanColor(image, pixelList);
    meanLabCol = colorspace('Lab<-', double(meanRgbCol)/255);
    meanPos = GetNormedMeanPos(pixelList, h, w);
    meanPos(:, 1) = meanPos(:, 1) * h;
    meanPos(:, 2) = meanPos(:, 2) * w;
    
    Lbpbins = 8;
    [LbpSim, spLbpHist] = LbpSimimarity2(imglbp, pixelList, Lbpbins);
    tic
    psalName = [SrcPsal, '\', name, Psal_suffix];
    psal = imread(psalName);
    unary = zeros(spNum, 1);
    for sp = 1:spNum
        unary(sp) = mean(psal(pixelList{sp}));
    end
    unary(:,2) = unary(:,1);
    unary(:,1) = 255 - unary(:,1);
    unary = -single(unary);
    
    % dense CRF inference
    D = Densecrf(meanLabCol, spLbpHist, unary, meanPos);
    
    D.compile('densecrf', 1);
    D.gaussian_x_stddev = 3;
    D.gaussian_y_stddev = 3;
    D.gaussian_weight = 1;
    
    D.bilateral_x_stddev = 60;
    D.bilateral_y_stddev = 60;
    D.bilateral_r_stddev = 10;
    D.bilateral_g_stddev = 1;
    D.bilateral_b_stddev = 1;
    D.bilateral_lbp_stddev = 1;
    D.bilateral_weight = 1;
    D.iterations = 20;
    D.Lbpbins = Lbpbins;
    
    D.mean_field;
    toc
    D.save([IniSalRegion, '\', name, crfSuffix], pixelList, h, w)
end

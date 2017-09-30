src = 'E:\wangxiang\Code_Material\meanfield-matlab-master\meanfield-matlab-master\include\probImage';
files = dir(fullfile(src, strcat('*', '.cpp')));
currentDir = pwd;
cd(src)
for k = 1: size(files, 1)
    try
        name = files(k).name;
        mex(name);
    catch ME
        disp(ME.message);
    end
    
end
cd(currentDir); 
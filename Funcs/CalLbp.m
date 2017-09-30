function img1l = CalLbp(img)
SP=[-1 -1; -1 0; -1 1; 0 -1; -0 1; 1 -1; 1 0; 1 1];
mapping=getmapping(8,'u2');
if size(img,3) ~= 1
    img = rgb2gray(img);
end
img1lbp = double(lbp(img, SP, mapping, 'i'));
[rows, cols] = size(img1lbp);
rows = rows + 2;
cols = cols + 2;
img1l = zeros(rows, cols);
img1l(2:end-1, 2:end-1) = img1lbp;
img1l([1 end], 2:end-1) = img1lbp([1 end], :);
img1l(2:end-1 ,[1 end]) = img1lbp(:, [1 end]);
corner = [1, 1;1, cols;rows, 1;rows, cols];
corner1 = [1, 2;1, cols-1;rows, 2;rows, cols-1];
corner2 = [2, 1;2, cols;rows-1, 1;rows-1, cols];
corner3 = [2, 2;2, cols-1;rows-1, 2;rows-1, cols-1];
for i=1:4
    img1l(corner(i,1), corner(i,2)) = (img1l(corner1(i,1), corner1(i,2)) + img1l(corner2(i,1), corner2(i,2)) + img1l(corner3(i,1), corner3(i,2)))/3;
end
end
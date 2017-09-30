function dst = mynormalize(src, bottom, up)
dst =(src-min(min(src)))*(up-bottom)/(max(max(src))-min(min(src)));
dst = dst + bottom;
end
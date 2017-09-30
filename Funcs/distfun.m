function dist =  distfun(f1, f2)
dist = sum(bsxfun(@min,f1, f2), 2);
function [ord, e] = mst_nodeord(d)
%function [ord, e] = mst_nodeord(d)
% Return the order of node according to the MST Prim algorithm
%
% ord -- the order
% e -- the edge weight along this order
% d -- input distance matrix
%
% by Hanchuan Peng
% Feb 11, 2005
                                                                                                                  
[minval, minind] = min(d(:));
[minx, miny] = ind2sub(size(d), minind);
                                                                                                                  
r = mst_prim(d,minx); %use minx as root node
                                                                                                                  
[dtime,ord] = sort(r(:,4));
                                                                                                                  
for i=1:length(r)-1,
    e(i) = d(r(ord(i+1),3), ord(i+1));
end;
                                                                                                                  


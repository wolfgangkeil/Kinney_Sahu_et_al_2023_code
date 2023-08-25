function cArray = bfs_mroot(G,iArray)
%function cArray = bfs_mroot(G,iArray)
%
%find the BFS tree for an array of root nodes
%return a cell array, each component containing 
%a BFS tree for each root node
%
%by Hanchuan Peng
%July, 2002
%updated 070103: change G=~~G to a better version so that the data type
%wouldn't get changed.

cArray = []; %default value
if isempty(iArray) | isempty(G),
  return;
end;

G(find(G~=0))=1; %%change from G=~~G; 070103

maxx_iArray = max(iArray);
minn_iArray = min(iArray);

if (size(G,1)~=size(G,2) | ...
   maxx_iArray > size(G,1) | ...
   minn_iArray < 1),
   fprintf('Non-square Graph or invalid iArray!\n'); 
   return;
end;


for i=1:length(iArray),
  t = bfs_1root(G,iArray(i));
  maxdis = max(t(:,4));
  clear cArrayCell;
  cArrayCell.nlayer = maxdis;
  for j=1:maxdis,
    cArrayCell.layers{j} = find(t(:,4)==j);
  end;
  cArray{i} = cArrayCell;
end;

return;


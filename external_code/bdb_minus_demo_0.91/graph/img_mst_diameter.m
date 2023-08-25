function myord = img_mst_diameter(m)
%function myord = img_mst_diameter(m)
%
% return the diameter of an MST m that is produced from the thinned
% structure of an elongated object (e.g. a worm body)
%
% by Hanchuan Peng
% 2006-11-12
%


sz = size(m);
if sz(1)~=sz(2) | sz(1)<=1 ,
    error('The input is not a MST!');
end;

N = sz(1);

%% As this MST is produced for an image object, the weight must be 1 for
%% adjacent node. Thus I don't judge the tree wieght anymore. In another
%% word, I am not finding the path with the largest sum of weight, instead
%% just the path with the most nodes.

m = m+m';
mytree = bfs_1root(m, 1);
nodeStart = find(mytree(:,4)==max(mytree(:,4)));
if length(nodeStart)>1,
    nodeStart = nodeStart(1);
end;

mytree = bfs_1root(m, nodeStart);
nodeEnd = find(mytree(:,4)==max(mytree(:,4)));
if length(nodeEnd)>1,
    nodeEnd = nodeEnd(1);
end;

myord = zeros(N,1); %myord = zeros(Lmax,1);
myord(1) = nodeEnd;
i=2;
while 1,%for i=2:Lmax,
  myord(i) = mytree(myord(i-1),3);
  if myord(i)==nodeStart,
     break;
  end;
  i=i+1;
end;
Lmax = i;
myord = myord(Lmax:-1:1);

return;

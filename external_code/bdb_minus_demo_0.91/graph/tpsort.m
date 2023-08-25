function left2rightord = tpsort(dag0)
%function tpsort(dag0)
%topological sort
%By hanchuan Peng
%July 2002

r = dfs(dag0);
t = r(:,5);
[endtime, iendtime] = sort(t);
left2rightord = flipud(iendtime(:));


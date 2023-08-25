function r = dcg(G,method)
%use the DFS to find DCG, i.e. disconnected graphs
%
% G is a DAG or any graph
% r contains cells, each of which is a disconnected subgraph
% method -- 1 for DFS and 2 for BFS, default is 1
%
% Example: load g; r=dcg(g);
% 
% By Hanchuan Peng
% June, 2002

if nargin<2,
  method = 1;
end;

if (method~=1 & method~=2),
  method = 1;
end;

g = ~~full(G + G');

if method==1,
  res = dfs(g);
else
  res = bfs(g);
end;

for i=1:max(res(:,2)),
  r{i} = find(res(:,2)==i);
end;




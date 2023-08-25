function r = scc(gp,method)
%function r = scc(gp,method)
%find the Strongly connected components in a directed graph gp
%
% r is a cell array, each unit contains indexes of the SCC in gp
% 
% method: the method in searching the output DF-tree,
%         1 for DFS and 2 for BFS.
%
% an example: load res872;gp = pickinitdag(Gb);
%             rdfs = findbnscc(gp,1);rbfs = findbnscc(gp,2);
%             for i=1:8,find(rbfs{i}-rdfs{i}),end
%
% By Hanchuan Peng
% June, 2002

%set method
if nargin<2,
    method = 1;
end;
if (method~=1 & method~=2),
    method = 1;
end;

%===========
r = [];
s = sccon(gp,method);
k=1;
for i=1:length(s),
    if length(s{i})>1, 
        r{k}=s{i};
        k=k+1;
    end;
end;


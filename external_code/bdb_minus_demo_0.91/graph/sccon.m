function s = sccon(G,method)
% renamed from the following function
%function s = strongcntcompt(G,method)
%find the strongly connected components of a directed graph
%example: load fig23.9; s=strongcntcompt(g);
%
%almost same with the strongcntcompt.m except the method to output  
% the DFtree results
%
% method: the method in search the output DF-tree,
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

%==========================

gp = full(G); %need upgrade later for sparse matrix

res0 = dfs(gp);

t0 = res0(:,5); %the finish time
[tmp, idxt0] = sort(t0); %idxt is ascending order
idxt1 = flipud(idxt0); %get the descending order

gp1 = gp'; %reverse all arrows
gp2 = gp1(idxt1,idxt1); %get the descending finishing time order

res2 = dfs(gp2);

pai2 = res2(:,3); %get the parent list

mytree = dftree(pai2); %generate the DF-tree of the second DFS

%======================= below are different from strongcntcompt.0.1.m =====

s=[];
if ~isempty(mytree),
    newsiz = size(gp);
    newg = zeros(newsiz);
    newg(sub2ind(newsiz,mytree(:,1),mytree(:,2)))=1;

    if method==1, %should be the same for whatever search method
        resnewg = dfs(newg); 
    else
        resnewg = bfs(newg);
    end;
    labelmax = max(resnewg(:,2)); %the max label of all nodes
    
    for i=1:labelmax,
        s{i} = idxt1(find(resnewg(:,2)==i)')';
    end;

else

    labelmax = length(gp);
    for i=1:labelmax,
        s{i} = i;
    end;

end;

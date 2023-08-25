function t = dftree(pai_i)
%generate the DF-tree based on the pai_i data of 
% a DFS result (the third column)
%
% t -- the first column is i, the second is pai_i
%
% By Hanchuan Peng
%June, 2002

pai_i = pai_i(:); %make it a column vector
idx = find(pai_i~=-1); %-1 means NIL
t = [pai_i(idx) , idx];

function u2=drawchrismap(gp, thres, titlestr, nodenamelist);
%function u2=drawchrismap(gp, thres, titlestr, nodenamelist);
% gp -- the partial connected map
% thres -- the threshold to remove the non-important edges
% nodenamelist -- a cell array of name(str) for each node
%                 if not provided, then use node no.
%
% By Hanchuan Peng, June, 2002
% updated on July 2002
%

if nargin<4,
  nodenamelist = [];
end;

if nargin<3,
    titlestr = [];
end;

if nargin<2,
    thres = 0;
end;

g = gp;
g(g<=thres) = 0;

%commented by phc, 020707 ====

%isr = find(sum(g,1)); %index for sum along rows
%isc = find(sum(g,2)); %index for sum along columns
%inz = union(isr,isc);  %index for nonzero rows or cloumns
%
%g = g(inz,inz);
%fprintf('cur thres = %d connected nodes # = %d\n',thres,length(g));

%==============

%[G, Gc, gp, G2, G3]=maindana(no);

%gp = gp(:,setdiff([1:1:length(gp)],[5 11 10]));
%gp = gp(setdiff([1:1:length(gp)],[5 11 10]),:);

c = spones(g);

c2 = c+c' + 0.2*rand(length(c));

c3 = diag(sum(c2,2))-c2;

[u2,s2,v2] = svds(c3,3,0);

fprintf('the three minimum eigenvalues: \n');
disp(s2);

dispbnarccoord(g,u2(:,1:2),titlestr,nodenamelist);
 

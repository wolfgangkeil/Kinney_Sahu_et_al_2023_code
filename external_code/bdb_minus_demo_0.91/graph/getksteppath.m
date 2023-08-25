function cpath = getksteppath(G,curnode,K, intime)
%function cpath = getksteppath(G,curnode,K, intime)
%find all pathes of the next K-step from the curnode
%note that G has to be square
%
%NOTE: this prog's performance might be limited by the MATLAB's
% internal stack. Hence I plan to update it later using my own 
% stack tech
%
% By Hanchuan Peng
%
if curnode<1, %==0
    cpath = [];
end;

if nargin<4,
  intime = cputime;
end;

%cputime-intime

%save debug_getksteppath.mat G curnode K; 
if 0,
if (cputime - intime) > 10,
  fprintf('possible dead loop! retrun an empty path! See debug_getksteppath.mat!\n');
  save debug_getksteppath.mat G curnode K;
  cpath = [];
  return;
end;
end;

if K<1,
    cpath = [];
elseif K==1,
    cpath = find(G(curnode,:));
    cpath = cpath(:);
else
    ilinkout = find(G(curnode,:));
    cpath = [];
    for j=1:length(ilinkout),
        curpath = getksteppath(G,ilinkout(j),K-1, intime);
        curpath2 = zeros(size(curpath,1),size(curpath,2)+1);
        curpath2(:,1) = ilinkout(j);
        curpath2(:,2:size(curpath,2)+1) = curpath;
        if ~isempty(curpath2),
            cpath = cat(1,cpath,curpath2);
        end;
    end;
end;

%disp(cpath);

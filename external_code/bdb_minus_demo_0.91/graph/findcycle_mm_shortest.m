function clist = findcycle_mm_shortest(G,b_disp)
% clist = findcycle_mm_shortest(G,b_disp)
% b_disp==1 (default) to display the result
% 
% find the shortest cycle(s) in a SCC
%
% use the matrix multiplication method to find cycles
% and return the list of cycles
% By Hanchuan Peng
%
% July 2002
%

if nargin<2,
    b_disp=1;
end;

[h w] = size(G);
clist = [];
if h~=w,
  fprintf('the input G is not square!\nreturn [].\n');
  return;
end;

%added by phc on July/6/2002
%==================
G = ~~G; 
%==================

tmp = G;
k=0; bstop=0;
iArray = [2:1:h];
while ~isempty(iArray) & bstop==0,
  i = iArray(1); %for i=2:h,
  tmp = tmp*G;
  if isempty(find(tmp)),
    bstop = 1;
  else
    da = diag(tmp);
    ida = find(da);
    lastG = G;
    while ~isempty(ida),
      curG = lastG(ida,ida);
      m = 1;
      %constructing a breath-first list for i-step distance
      cpath = getksteppath(curG,m,i);
      if isempty(cpath),
        idxpath = [];
      else
        idxpath = find(cpath(:,size(cpath,2))==m);
      end;
    
      for tmpi = length(idxpath):-1:1,
        if length(find(cpath(idxpath(tmpi),:)==m))>1, %then there is a smaller cycle
          idxpath(tmpi) = []; %remove this duplicate one
        end;
      end;

      while ~isempty(idxpath) & ~isempty(ida),
        k = k+1;
        clist{k} = ida(cpath(idxpath(1),:));
        for mm=1:length(clist{k}),
            da(clist{k}(mm)) = da(clist{k}(mm))-1;
        end;
        idxpath(1) = []; %shorten 1
      end;
      ida = find(da>0); %020702 night
    end;
    iArray = setdiff(iArray,i); %for i=2:h

    %added by phc on July/6 to return only the shortest cycles
    if ~isempty(clist),
      bstop = 1; %iArray = [];
    end;
  end;
end;

if b_disp==1,
    fprintf('There are %d shortest cycle(s).\n',k);
    for i=1:k;
        fprintf('cycle %d: ',i);
        fprintf('%d ',clist{i});
        fprintf('\n');
    end;
end;

%remove the redundant cycles

%======================================================
function newlist = removecycle(clist)
%remove the duplicate list
if isempty(clist),
    newlist = [];
    return;
end;

oldlist = clist;
lenlist = length(clist);
for i=1:lenlist,
    clist{i} = getsupportnode(clist{i});;
end;
b_remove = zeros(lenlist,1);
for i=1:lenlist,
    for j=i+1:lenlist,
        if size(clist{i})==size(clist{j}),
            if isempty(find(clist{i}-clist{j})),
                b_remove(j)=1;
            end;
        end;
    end;
end;

oldlist = getnewlist(oldlist,b_remove);
clist = oldlist;
lenlist = length(clist);
for i=1:lenlist,
    clist{i} = getsupportnode(clist{i});;
end;
b_remove = zeros(lenlist,1);
k=1;listij = [];
for i=1:lenlist,
    for j=i+1:lenlist,
        if ~isempty(intersect(clist{i},clist{j})),
            tmp = union(clist{i},clist{j});
            if (equalmatrix(tmp,clist{i})==0 & ... %there is still a bug based on union. phc020702 night
               equalmatrix(tmp,clist{j})==0),
               listij{k} = tmp;
               k = k+1;
            end;
         end;
    end;
end;
for k=1:length(listij),
    listij{k} = getsupportnode(listij{k});
    for i=1:lenlist,
        if equalmatrix(listij{k},clist{i})==1,
            b_remove(i)=1;
        end;
    end;
end;

newlist = getnewlist(oldlist,b_remove);

%=================================================
function newlist = getnewlist(oldlist,b_remove)
k = 1;
for i=1:length(oldlist),
    if b_remove(i)~=1,
        newlist{k} = oldlist{i};%don't use the sorted result
        k = k+1;
    end;
end;

%==================================================
function bequal = equalmatrix(a,b)
bequal = 0;
if size(a)==size(b),
    if (a==b),
        bequal = 1;
    end;
end;

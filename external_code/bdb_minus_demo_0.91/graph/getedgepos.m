function pos = getedgepos(cyclenodeord)
%from a node list of a cyle generate the edge positions
%by hanchuan Peng
%July 2002
%example: getedgepos([2 3 1])
%
i=[1:1:length(cyclenodeord)];
cyclenodeord = [cyclenodeord(:)' cyclenodeord(1)];
pos = [cyclenodeord(i)' cyclenodeord(i+1)'];;

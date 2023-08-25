function demo_graphalgorithm()
%simple demos for the effectiveness of elementary graph algorithms
% By Hanchuan Peng
% June 2002

%demo for strongly connected component detection

clear all;

% g(1,2)=1;g(2,3)=1;g(3,4)=1;g(4,1)=1;g(4,5)=1;
% g(5,6)=1;g(6,7)=1;g(7,4)=1;g(8,9)=1;g(9,9)=0;

load samplegraph_scc.mat;

for i=1:length(g_scc),

    if length(g_scc{i})<50,
       drawchrismap(g_scc{i},0,['strongly connected components ' num2str(i)]);
    end;

    r = sccon(g_scc{i});

    dispres(r,['result of strongly connected components ' num2str(i)]);

end;

%demo for disconnected subgraph detection

clear all;

% g(1,2)=1;g(2,3)=1;g(3,4)=1;g(4,1)=1;g(4,5)=1;
% g(5,6)=1;g(6,7)=1;g(7,4)=1;g(8,9)=1;g(9,9)=0;

load samplegraph_dcg.mat;

for i=1:length(g_dcg),
    
    if length(g_dcg{i})<50,
       drawchrismap(g_dcg{i},0,['disconnected subgraphs ' num2str(i)]);
    end;
    
    r = dcg(g_dcg{i});

    dispres(r,['result of disconnected subgraphs ' num2str(i)]);
    
end;

%============= disp function ===========
function dispres(r,msgstr)
if ~isempty(msgstr),
    fprintf('%s\n',msgstr);
end;
for i=1:length(r),
    fprintf('r{%d}= ',i);
    fprintf('%d ',r{i});
    fprintf('\n');
end;

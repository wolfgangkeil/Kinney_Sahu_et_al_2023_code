%
% 
%
% THIS SCRIPTS PERFORMS PREPROCESSING FOR AN IMAGING EXPERIMENT
% DONE IN A MICROFLUIDIC CHAMBER AS IN KEIL ET AL. DEV CELL (2017)
%
% IT FIRST DETECTS THE WORM OUTLINE, THEN CALCULATES A MIDLINE BASED ON
% SKELETONIZATION, THEN STRAIGHTENS THE WORM, SAVING IT IN A FOLDER CALLED 
% <EXPERIMENT_FOLDER>/worm_1_straigthened
%
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% by Wolfgang Keil, Institut Curie 2023




% Change according to the location of your data folder, do not include the
% "raw_data" subdirectory into the path, this is added automatically
experiment_folder = '/Users/wolfgang/Documents/GitHub/test_data/HML1019/';

% Change according to the location of your Ilastik installation
Path2Ilastik = '/Applications/ilastik-1.4.0rc2post2-OSX.app'; 

% leave this unchanged
trigger_channel = 1;
channels2straighten = 2;
channel_names = {'GFP', 'mCherry'};
worm_positions = {[1,2]};


%%% Adds various subfolders to the Matlab path
Folder = cd;
code_root_folder = fullfile(Folder, '../../');
PATHS_TO_ADD = {'straightening',...
                [code_root_folder '/file_handling/'],...
                [code_root_folder '/external_code/'], ...
                [code_root_folder '/external_code/saveastiff_4.0/'], ...
                [code_root_folder '/external_code/interp3_gpu/'],...
                [code_root_folder '/external_code/Skeleton/'],...
                [code_root_folder '/external_code/bdb_minus_demo_0.91/'] };


% Add paths
pathCell = regexp(path, pathsep, 'split');

for jj = 1:length(PATHS_TO_ADD)
    if ispc  % Windows is not case-sensitive
        onPath = any(strcmpi(PATHS_TO_ADD{jj}, pathCell));
    else
        onPath = any(strcmp(PATHS_TO_ADD{jj}, pathCell));
    end
    if ~onPath
        addpath(PATHS_TO_ADD{jj});
    end
end
    


%%%%%%%%%% THIS LAUNCHES THE STRAIGHTENER, INCLUDING ILASTIK
%%%%%%%%%% CLASSIFICATION, MIDLINE FINDING, AND THE ACTUAL STRAIGHTENING
straighten_imaging_experiment(experiment_folder, trigger_channel, channels2straighten, ...
                   channel_names, worm_positions, Path2Ilastik); 
               

% Remove the added paths
pathCell = regexp(path, pathsep, 'split');

for jj = 1:length(PATHS_TO_ADD)
    if ispc  % Windows is not case-sensitive
        onPath = any(strcmpi(PATHS_TO_ADD{jj}, pathCell));
    else
        onPath = any(strcmp(PATHS_TO_ADD{jj}, pathCell));
    end
    if onPath
        rmpath(PATHS_TO_ADD{jj});
    end
end               

%
%
% This script calcutates MS2 spot intensities for manually tracked spots
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
Path2Fiji = '/Applications/Fiji.app'; 


%%% Adds various subfolders to the Matlab path
Folder = cd;
code_root_folder = fullfile(Folder, '../../');
PATHS_TO_ADD = {[code_root_folder '/file_handling/'],...
                [code_root_folder '/external_code/'], ...
                [code_root_folder '/external_code/saveastiff_4.0/'], ...
                [Path2Fiji '/scripts/']};


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



ise = evalin( 'base', 'exist(''GFP_stack'',''var'') == 1' );
if ise
    evalin('base', 'clear(''GFP_stack'')');
end
ise = evalin( 'base', 'exist(''mCherry_stack'',''var'') == 1' );
if ise
    evalin('base', 'clear(''mCherry_stack'')');
end

ise = evalin( 'base', 'exist(''Ilastik_stack'',''var'') == 1' );
if ise
    evalin('base', 'clear(''Ilastik_stack'')');
end




% load('fate_color_scheme.mat'); % this loads color scheme for VPC fates


% Prepare the figures
figure(1)
clf;

% loop over all positions and chops of this worm
curr_pos = 0;

while exist([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' num2str(curr_pos)], 'dir')

    curr_chop = 0;


    disp('Loading mCherry_stack for position...')

%         posfolder = [experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
%                         num2str(curr_pos) '/mCherry/'];

    while exist([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                    num2str(curr_pos) '/chop_' num2str(curr_chop) '/'], 'dir')


        chop_folder = [experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                    num2str(curr_pos) '/chop_' num2str(curr_chop) '/'];

        if exist([chop_folder 'mCherry_stackreg.tiff'], 'file')
            mCherry_tile = double(loadtiff([chop_folder 'mCherry_stackreg.tiff']));


            % Get all valid track ID's for this chop
            [valid_track_IDs, all_track_stats] = get_valid_track_IDs(experiment_folder,worm_index, curr_pos, curr_chop);    


            for ii = valid_track_IDs

                index = find(valid_track_IDs==ii);

                figure(1);
                clf;
                set(gcf, 'position', [000 600 800 400]);
                clf;
                imagesc(mCherry_tile(:,:,min(all_track_stats(index).frames(:))+1));
                colormap(gray);
                caxis([90 130]);
                hold on;
                scatter(all_track_stats(index).posx,all_track_stats(index).posy,20, all_track_stats(index).frames,'r');
                drawnow;
                pause(0.5);
                title(['chop ' num2str(curr_chop) ' position ' num2str(curr_pos) ', trackID ' num2str(ii) ]);

                % NOTE: This function also saves a file called [chop_folder
                % '/spots_track_' track_string '.mat'] which can be loaded
                % to plot the traces
                [spots, model] = calculate_MS2_traces_from_spot_tracks(IJM,experiment_folder,worm_index, curr_pos, curr_chop, ii);
            end
        end

        curr_chop = curr_chop + 1;
    end

    curr_pos = curr_pos + 1;    
end

   
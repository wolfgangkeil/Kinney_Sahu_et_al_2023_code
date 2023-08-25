function plot_MS2_traces_all_nuclei_single_worm()
%
%
% This function plots all MS2-MCP-GFP traces in a giant figure, just to
% give an overview over what has been analyzed
%
% It loads the "spot" structure for each tracked nucleus and plots the
% MS2 tracks for each of them
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% by Wolfgang Keil, Institut Curie 2023




    % Change according to the location of your data folder, do not include the
    %
    % "raw_data" subdirectory into the path, this is added automatically
    experiment_folder = '/Users/wolfgang/Documents/GitHub/test_data/HML1019/';
    worm_index = 1;


    %%% Adds various subfolders to the Matlab path
    Folder = cd;
    code_root_folder = fullfile(Folder, '../../');
    PATHS_TO_ADD = {[code_root_folder '/file_handling/'],...
                    [code_root_folder '/external_code/'], ...
                    [code_root_folder '/external_code/saveastiff_4.0/']};


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

    if ~strcmpi(experiment_folder(end),filesep)
        experiment_folder = [experiment_folder filesep];
    end
        

    % plot parameters
    filterwidth = 8;% in minutes
    frame_rate = 1/4;% in 1/minutes
    colors = [0.8 0 0; 0 0 0.8; 0 0 0.8; 1 0.5 0; 0 0.5 1; 0 0.5 0.5];
    
    
    close all;    
    disp('Determining number of tracked cells');
    
    no_cells = get_number_of_tracked_cells(experiment_folder, worm_index);
    no_frames = get_timelapse_dimensions_nikon([experiment_folder '/raw_data']);
    
    if no_cells == 0
        disp('No tracked cells found for this experiment. Is the folder correct? Has this been traced?');
        return;
    end
    
    
    figure(6)
    clf;
    set(gcf, 'position', [200 200 1300 900]);  
    no_columns = 4;
    no_rows = ceil(no_cells/no_columns);
    ha = tight_subplot(no_rows,no_columns,[.05 .05],[.05 .05],[.05 .05]); % Creates a figure with subplots with tight axes
    % loop over all positions and chops of this worm
    curr_pos = 0;

    cell_index = 0;
    ha(1) = gca;
    while exist([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' num2str(curr_pos)], 'dir')
        
        curr_chop = 0;
        
        
        disp('Loading mCherry_stack for position...')
       
        while exist([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                        num2str(curr_pos) '/chop_' num2str(curr_chop) '/'], 'dir')
             
                    
            chop_folder = [experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                        num2str(curr_pos) '/chop_' num2str(curr_chop) '/'];
            
            if exist([chop_folder 'mCherry_stackreg.tiff'], 'file')
       
                mCherry_tile = double(loadtiff([chop_folder 'mCherry_stackreg.tiff']));

                % Get all valid track ID's for this chop
                [valid_track_IDs, all_track_stats] = get_valid_track_IDs(experiment_folder,worm_index, curr_pos, curr_chop);    


                 % Get the correct track/chop time
                chop_time = 1/frame_rate * get_chop_timepoints(experiment_folder, worm_index, curr_pos, curr_chop);

                if contains(experiment_folder, '210626_HML1056_L3')
                    % this experiment was interrupted after 46 frames (184
                    % minutes) for 42 min
                    chop_time(chop_time > 184) = chop_time(chop_time > 184) + 42;
                end


                for ii = valid_track_IDs               

                    index = find(valid_track_IDs==ii);


                    track_string = num2str(ii);
                    track_string = [repmat('0', [1 4-length(track_string)]) track_string];

                    matfile = [chop_folder '/spots_track_' track_string '.mat']; 
                    xmlfile = [chop_folder 'pos_' num2str(curr_pos) '_chop_' num2str(curr_chop) '_trackID_' track_string '.xml']; 


                    if exist(matfile, 'file') && exist(xmlfile, 'file')
                        load([chop_folder '/spots_track_' track_string '.mat'], 'spots');

                        if ~isempty(spots)

                            cell_index = cell_index + 1; % Determines the position in the plot

                            figure(2);
                            clf;
                            set(gcf, 'position', [000 600 800 400]);
                            clf;
                            imagesc(mCherry_tile(:,:,min(all_track_stats(index).frames(:))+1));
                            colormap(gray);
                            caxis([90 130]);
                            hold on;
                            scatter(all_track_stats(index).posx,all_track_stats(index).posy,20, all_track_stats(index).frames,'r');

                            drawnow;
                            pause(1);


                            %%% Plot the traces belong to this cell
                            figure(6);
                            hold(ha(cell_index),'on');
                            ha(cell_index) = gca;

                            if isfield(spots, 'tt')
                                for jj = 1:length(spots.tt)
                                    signal = spots.fg{jj}-spots.bg{jj};
                                    ss = filter_signal(signal,frame_rate,'Gaussian','lowpass',filterwidth);
                                    plot(ha(cell_index), chop_time(spots.tt{jj}), ss, 'linewidth', 2,'color',colors(jj,:));
                                    hold(ha(cell_index),'on');
                                    plot(ha(cell_index), chop_time(spots.tt{jj}), signal, 'linewidth', 1,'color',[colors(jj,:) 0.5], 'linestyle', '--');
                                end
                                hold(ha(cell_index),'off');
                                xlim(ha(cell_index), [0,no_frames/frame_rate]);
                                ylim(ha(cell_index), [-200,500]);
                                xticklabels(ha(cell_index), 'auto');
                                yticklabels(ha(cell_index), 'auto');
                            end
                        end
                    end
                end
            end
            curr_chop = curr_chop + 1;
        end
        curr_pos = curr_pos + 1;
    end     
        
end


function no_cells = get_number_of_tracked_cells(experiment_folder, worm_index)
%
%
%
% This function checks how many cell traces there are, in order to
% determine a good number of subplots for the figure
%
%
%%%%%%%%%% by Wolfgang Keil, Institut Curie 2023
    
   
    
    % loop over all positions and chops of this worm
    curr_pos = 0;

    no_cells = 0;
    while exist([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' num2str(curr_pos)], 'dir')
        
        curr_chop = 0;
       
        while exist([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                        num2str(curr_pos) '/chop_' num2str(curr_chop) '/'], 'dir')
             
                    
            chop_folder = [experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                        num2str(curr_pos) '/chop_' num2str(curr_chop) '/'];
                                
            % Get all valid track ID's for this chop
            valid_track_IDs = get_valid_track_IDs(experiment_folder,worm_index, curr_pos, curr_chop);    
            
           for ii = valid_track_IDs               
                                
                track_string = num2str(ii);
                track_string = [repmat('0', [1 4-length(track_string)]) track_string];
                                           
                matfile = [chop_folder '/spots_track_' track_string '.mat']; 
                xmlfile = [chop_folder 'pos_' num2str(curr_pos) '_chop_' num2str(curr_chop) '_trackID_' track_string '.xml']; 
                      
                if exist(matfile, 'file') && exist(xmlfile, 'file')
                    load([chop_folder '/spots_track_' track_string '.mat'], 'spots');
                    if ~isempty(spots)
                        no_cells = no_cells + 1;
                    end
                end
            end
            curr_chop = curr_chop + 1;
        end
        curr_pos = curr_pos + 1;    
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% this function gets the actual time points of a chop, taking into account
% frame_range.txt and frames2delete.txt
% Use this vector then to plot the MS2-MCP GFP time courses
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% code by Wolfgang Keil, Institut Curie 2022
function timeframes = get_chop_timepoints(experiment_folder, worm_index, position, chop)

    if ~strcmpi(experiment_folder(end), '/')
        experiment_folder  = [experiment_folder, '/'];
    end

    if exist([experiment_folder 'frame_range.txt'], 'file')
        disp(['Reading frame range file for chop ' num2str(chop) ' of position ' num2str(position) '..'] );
        fid = fopen([experiment_folder 'frame_range.txt']);
        range = fscanf(fid, '%d');
        fclose(fid);
        timeframes = range(1):range(2);
    else
        timeframes = get_timelapse_dimensions_nikon_raw_data([experiment_folder '/raw_data']);   
        timeframes = 1:(timeframes);
    end
    
    % Now check whether there is a file called "frames2delete.txt" in the
    % chop folder
    
    if exist([experiment_folder 'worm_' num2str(worm_index) '_drift_corrected/Pos' ...
                 num2str(position) '/chop_' num2str(chop) '/frames2delete.txt'], 'file')

        disp('      Reading frame2delete.txt file...');
        fid = fopen([experiment_folder 'worm_' num2str(worm_index) '_drift_corrected/Pos' ...
                 num2str(position) '/chop_' num2str(chop) '/frames2delete.txt']);
        
        frames2delete = fscanf(fid, '%d');
        fclose(fid);
        %% Delete the frames
        for jj = length(frames2delete):-1:1
            timeframes(frames2delete(jj)) = [];    
        end
    end
  



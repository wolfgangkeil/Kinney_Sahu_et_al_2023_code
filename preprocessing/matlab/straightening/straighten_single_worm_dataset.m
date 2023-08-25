function straighten_single_worm_dataset(experiment_folder, worm_index, ...
    trigger_channel, channels2straighten, channel_names,overwrite_midlines, AP_padd_size,positions,Path2Ilastik)
%
%
% This script determine how many frames have been recorded in the
% experiment and launches the straightening for each of them, unless a
% frame_range.txt file is specified in the experiment_folder
%
% overwrite_midlines is a FLAG, if 1 existing midline.mat files are not
% overwritten
%
% AP_padd_size should not be changed
%
%
%
% all code by Wolfgang Keil, Institut Curie, 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    if ~strcmpi(experiment_folder(end), '/')
        experiment_folder = [experiment_folder '/'];
    end
        
    
    % Create folders to store the cropped files 
    if ~exist([experiment_folder 'worm_' num2str(worm_index) '_straightened/'],'dir')
        mkdir([experiment_folder 'worm_' num2str(worm_index) '_straightened/']);
        for ii = 0:(length(positions)-1)
            mkdir([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' num2str(ii)]);
            % make a folder for the trigger channel
            mkdir([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' num2str(ii) '/' channel_names{trigger_channel} '/']);      
            for kk = 1:length(channels2straighten)
                % make a folder for the trigger channel
                mkdir([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' num2str(ii) '/' channel_names{channels2straighten(kk)} '/']);                    
            end
        end
        
    end
     
    
    no_frames = get_timelapse_dimensions_nikon([experiment_folder '/raw_data/']);
    
    if exist([experiment_folder '/frame_range.txt'],'file')
        disp('Reading frame range file...');
        fid = fopen([experiment_folder '/frame_range.txt']);
        range = fscanf(fid, '%d');
        fclose(fid);
        
        range = range(1):range(2);
        disp(['Will process frames ' num2str(range(1)) ' to ' num2str(range(end)) ]);
        
    else
        range = 1:(no_frames);
        disp(['Could not find frame range file ''frame_range.txt'' in folder ' experiment_folder 'worm_' num2str(worm_index) '/']);
        disp(['Will process  frames 1 to ' num2str(no_frames)]);
    end   

    % for-loop over range
    for frame_index = range(1):range(end) %
        disp(['        Straightening frame ' num2str(frame_index) '...']);   
        straighten_single_worm_frame(experiment_folder, worm_index,...
                     frame_index, trigger_channel, channels2straighten,...
                     channel_names,overwrite_midlines,AP_padd_size,positions, Path2Ilastik);
    end    
    disp('All processing done.');
end


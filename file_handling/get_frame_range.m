function  range = get_frame_range(experiment_folder, worm_index)
    range = [];
    % Find out whether there is a frame_range.txt file, otherwise find
    % midlines for the whole time series
    %no_timestamps = get_timelapse_dimensions_nikon(experiment_folder, worm_index);
    [~, no_timestamps] = get_timelapse_dimensions_cropped_data([experiment_folder 'worm_' num2str(worm_index) '/Pos0/']);

    if exist([experiment_folder 'worm_' num2str(worm_index) '/frame_range.txt'], 'file')
        disp('Reading frame range file...');
        fid = fopen([experiment_folder 'worm_' num2str(worm_index) '/frame_range.txt']);
        range = fscanf(fid, '%d');
        fclose(fid);
        
        range = range(1):range(2);
        disp(['Will proess frames ' num2str(range(1)) ' to ' num2str(range(end)) ]);
        
    else
        range = 1:(no_timestamps);
        disp(['Could not find frame range file ''frame_range.txt'' in folder ' experiment_folder 'worm_' num2str(worm_index) '/']);
        disp(['Will process  frames 1 to ' num2str(no_timestamps)]);
    end   
    
    

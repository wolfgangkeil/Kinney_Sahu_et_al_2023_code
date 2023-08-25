function  range = get_frame_range_nikon(experiment_folder, worm_index)
    range = [];
    % Find out whether there is a frame_range.txt file, range will be the
    % whole time series
    no_timestamps = get_timelapse_dimensions_nikon(experiment_folder, worm_index);

    if ~isempty(no_timestamps)
        if exist([experiment_folder 'worm_' num2str(worm_index) '/frame_range.txt'], 'file')
            disp('Reading frame range file...');
            fid = fopen([experiment_folder 'worm_' num2str(worm_index) '/frame_range.txt']);
            range = fscanf(fid, '%d');
            fclose(fid);
            
            if mod(length(range),2) > 0
                disp('Invalid range specification in frame_range.txt ...');
                range = [];
                return;
            else
                tmp = [];
                for ii = 1:2:length(range)-1
                    tmp = [tmp, range(ii):range(ii+1)]; 
                    disp(['Will analyze frames ' num2str(range(ii)) ' to ' num2str(range(ii+1)) ]);
                end
                range = tmp;
            end


        else
            range = 1:(no_timestamps);
            disp(['Could not find frame range file ''frame_range.txt'' in folder ' experiment_folder 'worm_' num2str(worm_index) '/']);
            disp('Frame range will be entire experiment ...');
        end   
    end
end
    

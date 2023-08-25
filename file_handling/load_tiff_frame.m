%
%   out = save_tiff_frame(array,experiment_folder, processing_type,worm_index,...
%           frame_index,channel,bitdepth, options,scaling)
%
%
%
%   INPUT PARAMETERS
%   experiment_folder ... folder where the experiment is saved in (contains
%   all the worm folders)
%   worm_index ... index of the worm (usually between 1 and 10)
%
%   processing_type can be 'aligned', 'cropped', 'straightened' ... 
%   alignment_type can be 'AP_aligned', 'DV_aligned' ... 
%
%   frame_index ... index of the frame, starts at zero!! 
%   channel ... string with the channel's name, e.g. mCherry_decon
%
%
%
%   see also: save_tiff_frame.m, load_h5_frame.m, save_h5_frame.m
%
%
%
%   Wolfgang Keil, The Rockefeller University, 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function array = load_tiff_frame(experiment_folder, processing_type,alignment_type,...
    worm_index, frame_index,channel)


    worm_pos_folder = [experiment_folder 'worm_' num2str(worm_index) ...
        '_' processing_type '/Pos0/' channel '/'];  

    timestamp_string = num2str(frame_index);
    timestamp_string = [repmat('0', [1 9-length(timestamp_string)]) timestamp_string];

    
     % Construct the filename
    if ~isempty(alignment_type)
        filename = ['img_' timestamp_string '_' channel '_' alignment_type '.tif'];
    else
        filename = ['img_' timestamp_string '_' channel  '.tif'];
    end
    
    if exist([worm_pos_folder filename], 'file')
        array = loadtiff([worm_pos_folder filename]);
    else
        array = [];
        disp('Cannot load tiff file! File doesn''t exist!');
    end

%
%   out = save_tiff_frame(array,experiment_folder, processing_type,worm_index,...
%           frame_index,channel,bitdepth, options,scaling)
%
%
%
%   INPUT PARAMETERS
%   array ... data to put into tif file
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
%   see also: load_tiff_frame.m, load_h5_frame.m, save_h5_frame.m
%
%
%   Wolfgang Keil, The Rockefeller University, 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = save_tiff_frame(array,experiment_folder, position, processing_type,alignment_type,...
    worm_index, frame_index,channel,bitdepth, options,scaling)


   worm_pos_folder = [experiment_folder 'worm_' num2str(worm_index) ...
        '_' processing_type '/Pos' num2str(position) '/' channel '/'];  

    timestamp_string = num2str(frame_index);
    timestamp_string = [repmat('0', [1 9-length(timestamp_string)]) timestamp_string];

    
     % Construct the filename
    if ~isempty(alignment_type)
        filename = ['img_' timestamp_string '_' channel '_' alignment_type '.tif'];
    else
        filename = ['img_' timestamp_string '_' channel  '.tif'];
    end
    
    if exist(worm_pos_folder, 'dir')

        if nargin < 10
            scaling = 'scaled';
        end   

        if strcmpi(scaling, 'scaled')
            % Contrast stretch
            array = (array - min(array(:))) * ((2^bitdepth-1)...
                / (max(array(:)) - min(array(:))));
        elseif strcmpi(scaling, 'clipped')
            % Do nothing, this will clip
        else
            error('Invalid scaling option. Choose either ''scaled'' or ''clipped''');
        end

        if bitdepth == 8    
            saveastiff(uint8(array),[worm_pos_folder filename], options);
        elseif bitdepth == 16
            saveastiff(uint16(array), [worm_pos_folder filename], options);
        else
            error('Invalid bitdepth: Choose either 8 or 16.');
        end        

        out = 1;
    else
        out = -1;
        disp('Cannot save tiff-file! Folder to save it in doesn''t exist!');
    end

function [no_timestamps, no_positions, no_slices, no_channels, img_size] = get_timelapse_dimensions_nikon(varargin)                 
%
%
% USE THIS FUNCTION FOR NIS DATA SETS, SAVED AS TIFF and resaved to order
% based on worms
%
%
% this functions finds out how many frames and how many slices were taken based on the
% tiff-files in the original worm directort
%
% INPUT argument is either the worm_folder itself or the experiment folder and
% worm index, expects worm folders to be named worm_1, worm_2 etc.
%
% 
% all code by Wolfgang Keil, Institut Curie, 2021
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

    if length(varargin) == 1
        worm_pos_folder = varargin{1};
    else
        worm_pos_folder = [varargin{1} 'worm_' num2str(varargin{2}) '/'];
    end


    list_of_tiff_files = dir(worm_pos_folder);
    no_timestamps = 0;
    no_positions = 0;
    no_slices = 0;
    no_channels = 0;
    
    img_size = [];
    % Find out how many timeframes the actually are by reading the last tif
    % file
    for ii = length(list_of_tiff_files):-1:1

        if strfind(list_of_tiff_files(ii).name,'.tif')        

            % Determine number of timestamps from filename
            tmp = strfind(list_of_tiff_files(ii).name,'t');
            tmp1 = strfind(list_of_tiff_files(ii).name,'xy');
            tmp = str2num(list_of_tiff_files(ii).name(tmp(1)+1:tmp1(1)-1));
            if tmp > no_timestamps
                no_timestamps = tmp;
            end
            
            % Determine number of timestamps from filename
            tmp = strfind(list_of_tiff_files(ii).name,'xy');
            tmp1 = strfind(list_of_tiff_files(ii).name,'z');
            tmp = str2num(list_of_tiff_files(ii).name(tmp(1)+2:tmp1(1)-1));
            if tmp > no_positions
                no_positions = tmp;
            end
            
            % Determine number of slices from filename
            tmp = strfind(list_of_tiff_files(ii).name,'z');
            tmp1 = strfind(list_of_tiff_files(ii).name,'c');
            tmp = str2num(list_of_tiff_files(ii).name(tmp(end)+1:tmp1(end)-1));
            if tmp > no_slices
                no_slices = tmp;
            end
            
            
            % Determine number of channels from filename
            tmp = strfind(list_of_tiff_files(ii).name,'c');
            tmp1 = strfind(list_of_tiff_files(ii).name,'.tif');
            tmp = str2num(list_of_tiff_files(ii).name(tmp(1)+1:tmp1(1)-1));
            
            if tmp > no_channels
                no_channels = tmp;
            end
            
            if isempty(img_size)
                % Determine image size by opening an image
                img_info = imfinfo([worm_pos_folder '/' list_of_tiff_files(ii).name],'tif');
                img_size = [img_info.Width img_info.Height];
            end
        end
    end
    if no_timestamps == 0
        no_timestamps = [];
        no_channels = [];
        no_slices = [];
        
%         %%% Output for 
%         disp(['    No timestamps: ' num2str(no_timestamps)]);
%         disp(['    No slices: ' num2str(no_slices)]);
%         disp(['    No channels: ' num2str(no_channels)]);
%         disp(['    Image size: ' num2str(img_size)]);
        disp('Could not determine size of imaging data set! Is this the right folder?')
    end
end               
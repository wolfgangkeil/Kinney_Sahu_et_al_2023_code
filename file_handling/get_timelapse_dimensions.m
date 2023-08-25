function [no_timestamps, no_slices] = get_timelapse_dimensions(varargin)                 
%
% USE THIS FUNCTION FOR MICRO-MANAGER DATA SETS
%
%
% this functions finds out how many frames and how many slices were taken based in the
% tiff-files in the original micro-manager directory
%
% INPUT argument is either the worm_pos_folder itself or the experiment folder and
% worm index
% 
% all code by Wolfgang Keil, The Rockefeller University, 2017
%
%
% for datasets acquired with Nikon, and saved as tiff
% see also get_timelapse_dimension_nikon.m 
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if length(varargin) == 1
        worm_pos_folder = varargin{1};
    else
        worm_pos_folder = [varargin{1} 'worm_' num2str(varargin{2}) '/Pos0/'];
    end


    list_of_tiff_files = dir(worm_pos_folder);
    no_timestamps = [];
    no_slices = [];
    % Find out how many timeframes the actually are
    for ii = length(list_of_tiff_files):-1:1

        if strfind(list_of_tiff_files(ii).name,'tif')        

            no_timestamps = str2num(list_of_tiff_files(ii).name(5:13))+1;
            no_slices = str2num(list_of_tiff_files(ii).name(end-6:end-4))+1;
            img_size = size(imread([worm_pos_folder '/' list_of_tiff_files(ii).name]));
            break;            
        end
    end
    if ~isempty(no_timestamps)
        %%% Output for 
        disp(['    No timestamps: ' num2str(no_timestamps)]);
        disp(['    No slices: ' num2str(no_slices)]);
    else
        disp('Could not determine size of imaging data set! Is this the right folder?')
    end
end               
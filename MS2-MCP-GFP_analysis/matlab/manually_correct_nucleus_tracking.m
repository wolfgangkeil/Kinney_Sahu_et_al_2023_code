function model = manually_correct_nucleus_tracking()
%
%
% this function assumes automatic tracking has been performed, but was
% doomed unsuccessful or not of sufficiently quality
% You can use this function to improve tracks
% MAKE SURE TO RUN THE MS2 SPOT TRACKING ONLY WHEN TRACKS ARE FINAL!! 
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% by Wolfgang Keil, Institut Curie 2022



    experiment_folder = '/Users/wolfgang/Documents/GitHub/test_data/HML1019/';
    worm_index = 1;

    % change this according to which chop you want to correct
    position = 0;
    chop = 0;


    Path2Fiji = '/Applications/Fiji.app'; 

    %%% This line may need to be changed depending on the exact version of Fiji
    %%% used
    javaaddpath([Path2Fiji '/jars/ij-1.53t.jar']);

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
    
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    no_slices = 51; % We need to this is here to reshape the 4D arrays when loaded with loadtiff
    xy_scale = 183.3333;% in nm
    z_scale = 500;% in nm, this is needed for proper tracking with the trackmate plugin
        
    % Convert to pixel and set xy pixel size to 1
    z_scale = z_scale / xy_scale;
    xy_scale = 1;

    
    model = {};

    % 
    import fiji.plugin.trackmate.* ; 
    import fiji.plugin.trackmate.io.* ; 
    import java.io.File;
    import fiji.plugin.trackmate.gui.displaysettings.*;   
    import fiji.plugin.trackmate.visualization.hyperstack.*

    chop_folder = [experiment_folder 'worm_' num2str(worm_index) ...
        '_straightened/Pos' num2str(position) '/chop_' num2str(chop) '/'];

    TiffFile = ['mCherry_stack_stackreg_Probabilities_filtered.tiff'];
    TrackMateFile = ['mCherry_stack_stackreg_Probabilities_filtered.xml'];



    % Check if ImageJ IJM exists in workspace, otherwise, start ImageJ
    ise = evalin( 'base', 'exist(''IJM'',''var'') == 1' );
    if ~ise
        ImageJ;
    else
        ij.IJ.run('Close All'); % close all ImageJ windows
    end
    if ~exist('IJM', 'var')
        IJM = evalin('base', 'IJM');            
    end

    
%%%%%%%%%%%%%%%%%%%%%%%l%%%% Means the previous manual tracking results for
    % Load the filtered probability map
    if exist([chop_folder '/' TiffFile], 'file')
        imp = ij.IJ.openImage([chop_folder '/' TiffFile]);
        imp.show();

    else
        disp(['Cannot read filtered probability map ' TiffFile '. Are you sure you launched automated tracking on the chop?']);
        model = {};
        return;

    end


    answer = questdlg(['Launch Trackmate on the image, using the settings that you normally use.\n'...
                    'Correct the tracks if necessary and save the .xml file.\n Once finished, click ''Yes''.\n'...
                    'Click CANCEL if you didn''t track anything.']);
    switch answer
        case 'Yes'
        case 'No'
            return;
        case 'Cancel'

            ij.IJ.selectWindow(chop_folder);
            ij.IJ.run('Close');
            model = {};
            return;
    end
    % Now let the user run the TrackMatePlugin and tell the program when
    % finished 

    if exist ([chop_folder '/' TrackMateFile], 'file')        
        file = File([chop_folder '/' TrackMateFile]);

        reader = TmXmlReader(file);

        if ~(reader.isReadingOk)
            disp('Cannot read the xml-file');
            model = {};
            return;
        else
            model = reader.getModel();      
            display(model.toString());        
        end     
    else
        disp('Cannot load the TrackMate .xml file. Are you sure you launched automated tracking on the chop?');
    end
    
    %%%% Generate all the nuclear tracks (this overwrites all .tif and .mat
    %%%% files for the tracks!!
    if ~isempty(model)
        process_nuclear_tracking(experiment_folder, worm_index, position, chop, model, no_slices, z_scale);
    end
end

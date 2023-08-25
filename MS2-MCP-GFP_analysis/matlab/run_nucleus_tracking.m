%
%
% This script launches the FIJI trackmate plugin with preset parameters in
% order to track hypodermal nuclei labelled with the transgene 
% cshIs136[lin-4::24xMS2] I; mnCI-mCherry/cshIs139[rpl-28pro::MCPGFP::SL2 Histone mCherry]
% on a spinning-disk confocal microscope
%
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% by Wolfgang Keil, Institut Curie 2023

% Change according to the location of your data folder, do not include the
% "raw_data" subdirectory into the path, this is added automatically
experiment_folder = '/Users/wolfgang/Documents/GitHub/test_data/HML1019/';
worm_index = 1;

% Change according to the location of your Ilastik installation
Path2Ilastik = '/Applications/ilastik-1.4.0rc2post2-OSX.app'; 
Path2Fiji = '/Applications/Fiji.app'; 


%%% Adds various subfolders to the Matlab path
Folder = cd;
code_root_folder = fullfile(Folder, '../../');
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
 

import fiji.plugin.trackmate.* ; 


%%%%%%%%% Tracking parameters for Trackmate

min_track_length = 0.5; %% only take nuclei that were present at least half the time during the experiment

% Features of the nuclei to be expected
spot_radius = 12.5; %pixels
initial_quality_threshold = 8;
min_spot_quality = 28;

% track features
linking_max_distance = 20;
gap_closing_distance = 20;
gap_closing_frame_distance = 3;

no_slices = 51; % We need to this is here to reshape the 4D arrays when loaded with loadtiff
xy_scale = 183.3333;% in nm
z_scale = 500;% in nm, this is needed for proper tracking with the trackmate plugin

% Convert to pixel and set xy pixel size to 1
z_scale = z_scale / xy_scale;
xy_scale = 1;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   

if ~strcmpi(experiment_folder(end), '/')
    experiment_folder = [experiment_folder '/'];
end    

disp(['Analyzing experiment ' experiment_folder ' worm ' num2str(worm_index) '...']);


%%%%%%%%%%%%%%% PARAMETERS OF THE STACKS SAVED FOR MS2 SPOT TRACKING

options.overwrite = 1; % this is the saveastiff option        
nucleus_crop_size_xy = 18; % cropped stacks for individual nuclei will be twice this width
nucleus_crop_size_z = round(nucleus_crop_size_xy/z_scale); % cropped stacks for individual nuclei will be twice this width


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

%%%%%%%%%%%%%%% First run the Ilastik classifier
%%% YOu can comment this line, once classification has been done to save
%%% time
run_ilastik_h2b_classifier(experiment_folder, worm_index, Path2Ilastik);



%%%%%%%%% LOOPS OVER EACH POSITION AND CHOP
curr_pos = 0;

while exist([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' num2str(curr_pos) '/'], 'dir')

    curr_chop = 0;

    while exist([experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                    num2str(curr_pos) '/chop_' num2str(curr_chop) '/'], 'dir')


            chop_folder = [experiment_folder 'worm_' num2str(worm_index) '_straightened/Pos' ...
                        num2str(curr_pos) '/chop_' num2str(curr_chop) '/'];


            disp(['Processing chop ' num2str(curr_chop) ' of position ' num2str(curr_pos) ] );

            % Check the the manual registration has actually been done for
            % this chop
            if exist([chop_folder 'chop_' num2str(curr_chop) '_stack_t_1.tif'],'file')      

                %----------------------------------------------------------

                %%%%%%%%%%%%%% 3D tracking %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                ilastik_filename = 'mCherry_stack_stackreg_Probabilities.tiff';
                if exist([chop_folder ilastik_filename], 'file')
                    if exist('I', 'var')
                        clear('I');
                    end
                    % Get the ilastik_probability maps generated from the
                    % classification
                    imp = ij.IJ.openImage([chop_folder ilastik_filename]);
                    imp.show();
                    ij.IJ.run('Rename...','title=Ilastik_stack');

                    imp = ij.WindowManager.getCurrentImage();
                    tmp  = imp.getStackSize();
                    no_frames = tmp(1)/no_slices;
                    mtl = min_track_length*no_frames;

                    % Run a Gaussian Blur on the Image to improve tracking
                    ij.IJ.run('Properties...', ['channels=1 slices=' num2str(no_slices) ' frames=' num2str(no_frames) ' pixel_width=1 pixel_height=1 voxel_depth=' num2str(z_scale) ' frame=[1 frame]']);
                    ij.IJ.run('Gaussian Blur 3D...', 'x=3 y=3 z=1'); % Filter the Probability maps to avoid spurious spots during tracking

                    ij.IJ.saveAs(java.lang.String('tiff'), ...
                        java.lang.String([chop_folder 'mCherry_stack_stackreg_Probabilities_filtered.tiff']));

                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Setting up the
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% trackmate tracker
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    model = fiji.plugin.trackmate.Model();

                    % Send all messages to ImageJ log window.
                    %model.setLogger(fiji.plugin.trackmate.Logger.IJ_LOGGER)

                    %------------------------
                    % Prepare settings object
                    %------------------------
                    imp = ij.WindowManager.getCurrentImage();
                    settings = Settings(imp);  

                    settings.detectorFactory = fiji.plugin.trackmate.detection.LogDetectorFactory();
                    map = java.util.HashMap();
                    map.put('DO_SUBPIXEL_LOCALIZATION', true);
                    map.put('RADIUS', spot_radius);
                    map.put('TARGET_CHANNEL', int32(1));
                    map.put('THRESHOLD', initial_quality_threshold);
                    map.put('DO_MEDIAN_FILTERING', false);
                    settings.detectorSettings = map;


                    % Configure spot filters - Classical filter on quality
                    filter1 = fiji.plugin.trackmate.features.FeatureFilter('QUALITY', min_spot_quality, true);
                    settings.addSpotFilter(filter1);

                    settings.addAllAnalyzers();
%                    settings.addSpotAnalyzerFactory(fiji.plugin.trackmate.features.spot.SpotIntensityAnalyzerFactory())
%                    settings.addSpotAnalyzerFactory(fiji.plugin.trackmate.features.spot.SpotContrastAndSNRAnalyzerFactory())


                    % Configure tracker - We do NOT want to allow splits and fusions
                    settings.trackerFactory  = fiji.plugin.trackmate.tracking.jaqaman.SparseLAPTrackerFactory();
%                    settings.trackerSettings = fiji.plugin.trackmate.tracking.LAPUtils.getDefaultLAPSettingsMap(); % almost good enough
                    settings.trackerSettings = settings.trackerFactory.getDefaultSettings();                  

                    settings.trackerSettings.put('ALLOW_TRACK_SPLITTING', false);
                    settings.trackerSettings.put('ALLOW_TRACK_MERGING', false);

                    settings.trackerSettings.put('MAX_FRAME_GAP', int32(gap_closing_frame_distance));
                    settings.trackerSettings.put('LINKING_MAX_DISTANCE', linking_max_distance);
                    settings.trackerSettings.put('GAP_CLOSING_MAX_DISTANCE', gap_closing_distance);

                    % Configure track analyzers - Later on we want to filter out tracks 
                    % based on their displacement, so we need to state that we want 
                    % track displacement to be calculated. By default, out of the GUI, 
                    % not features are calculated. 

                    % The displacement feature is provided by the TrackDurationAnalyzer.
                    settings.addTrackAnalyzer(fiji.plugin.trackmate.features.track.TrackDurationAnalyzer());
                    % Add an analyzer for some track features, such as the track mean speed.
                    settings.addTrackAnalyzer(fiji.plugin.trackmate.features.track.TrackSpeedStatisticsAnalyzer())    
                    settings.addTrackAnalyzer(fiji.plugin.trackmate.features.track.TrackIndexAnalyzer() )
                    settings.addTrackAnalyzer(fiji.plugin.trackmate.features.track.TrackLocationAnalyzer() )


                    % Configure track filters
                    filter2 = fiji.plugin.trackmate.features.FeatureFilter('TRACK_DURATION', mtl, true);
                    settings.addTrackFilter(filter2)


                    %-------------------
                    % Instantiate plugin
                    %-------------------

                    trackmate = fiji.plugin.trackmate.TrackMate(model, settings);
                    %--------
                    % Process
                    %--------

                    ok = trackmate.checkInput();
                    if ~ok
                        display(trackmate.getErrorMessage())
                    end

                    ok = trackmate.process();
                    if ~ok
                        display(trackmate.getErrorMessage())
                    end

                    %----------------
                    % Display results
                    %----------------


                    %selectionModel = fiji.plugin.trackmate.SelectionModel(model);
                    % Echo results of the tracking, make sure this seems OK! 
                    display(model.toString());

                    ij.IJ.run('Close All');
                    disp('...done');

%                         
%                         file = java.io.File([chop_folder 'mCherry_stack_stackreg_Probabilities_filtered.xml']);
%                         fiji.plugin.trackmate.action.ExportTracksToXML.export(model, settings, file);

                    %%%%% This function now generates the individual
                    %%%%% track tif-files for each nucleus
                    process_nuclear_tracking(experiment_folder, worm_index, curr_pos, curr_chop, model, no_slices, z_scale)
                end
            end            
        curr_chop = curr_chop + 1;
    end
    curr_pos = curr_pos + 1;

end

disp('done.');
ij.IJ.close('*');



%%%%%%%%%%%%%%%%%%%%%%


% Remove the added paths
pathCell = regexp(path, pathsep, 'split');

for jj = 1:length(PATHS_TO_ADD)
    if ispc  % Windows is not case-sensitive
        onPath = any(strcmpi(PATHS_TO_ADD{jj}, pathCell));
    else
        onPath = any(strcmp(PATHS_TO_ADD{jj}, pathCell));
    end
    if onPath
        rmpath(PATHS_TO_ADD{jj});
    end
end               
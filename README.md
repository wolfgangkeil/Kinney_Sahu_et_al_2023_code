# Code accompanying Kinney & Sahu et al. Developmental Cell, 2023

This repository contains MATLAB scripts and ImageJ macros for analyzing MS2-MCP-GFP live movies in developing C. elegans larva, harboring the transgene cshIs136[lin-4::24xMS2] I; mnCI-mCherry/cshIs139[rpl-28pro::MCPGFP::SL2 Histone mCherry].

If you use parts of this code please cite: (paste reference whenever online)

For questions, please contact wolfgang.keil@curie.fr

## Installation

Download by
$ git clone  https://github.com/wolfgangkeil/Kinney_Sahu_et_al_2023_code.git

## Data
Raw data for an imaging experiment that can be processed with the code in this repository is available on the zenodo community page of the Keil lab: https://zenodo.org/communities/qdevbioteam/ .

The raw dataset is ~50GB. Running the analysis will generate additional folders and files of  ~100GB. Make sure you have enough disk space in the location you are running this analysis in.

## Overview of the pre-processing steps to be followed

Straightening => Z drift correction => Manual pre-registration => deletion of "bad" frames
 
### Straightening
1/ Generate a folder <experiment_folder> and past the folder called "raw_data" in it.

2/ Open Matlab, go to folder <PATH_TO_YOUR_GITHUB_CLONE>/Kinney_Sahu_et_al_2023_code/preprocessing

3/ Open File batch_process_experiments.m and execute:
Modify the script such that it executes the following commands:

experiment_folder = '<PATH_TO_YOUR_EXPERIMENT_FOLDER>';
trigger_channel = 1; % means this channel is used for midline finding and straightening
channels2straighten = 2;
channel_names = {'GFP', 'mCherry'};
worm_positions = {[1,2,3,4], [5,6,7]};
IsMultiWormFolder = 0;
 
straighten_imaging_experiment(experiment_folder, trigger_channel, channels2straighten, ...
                    channel_names, worm_positions, IsMultiWormFolder,0);
 
This script takes several hours to run on an average data set 
Output files are stored in a folder called worm_1_straightened and within this folder there are subfolders for each position and each channel

### Z drift correction
1/ Go through the straightened data once and generate a file called z_drift.csv within the <experiment_folder>
An example of such a file can be found in the zenodo repository . 
The convention for z-drift is the following: if your feature is in focus at slice s1 in frame 1, and at slice s2 in frame 2, then the zdrift between the two frames is s2-s1
IMPORTANT: Even if no z-drift should be applied, the z_drift.csv file must be generated and then have all zeros in it!

2/ open FIJI and then open macro '<PATH_TO_YOUR_GITHUB_CLONE>/preprocessing/imageJ/correct_z_drift.ijm'
change the lines about experiment_folder, worm_index, channels and z_drift file in the script according to your needs
run the macro
this will open all the straightened files, apply the z-drift and resave the files in worm_1_drift_corrected, can take time, approx 1h for a 100frames dataset

### Manual pre-registration and z-projection
The pre-registration requires a lot of manual clicking for large data sets. In order to reduce this a bit, it's best to create a file called "frame_range.txt" in the experiment_folder. This file should contain only two numbers, the first and the last frame that should be considered during the MCP-GFP spot tracking analysis. 

NOTE: The range of frames should cover the ENTIRE period of transcriptional activity throughout the worm. To be safe, add 10 frames before the first MS2 dots appear in the worm, and 10 frames after the last dot disappears.

Now you are ready for some clicking

open FIJI and then open macro "/home/keil-workstation/Desktop/Wolfgang/fiji/manual_pre_registration.ijm"
change the lines about experiment_folder, worm_index and channels in the script according to your needs
run the macro
this macro will ask you several times for your input, doing the following:
1/, it loads all data for a given position into a combined hyperstack 
2/ it asks you whether anterior-posterior alignment or dorsal-ventral alignment needs to be inverted (the straightening algorithm doesn't know where head and tail or dorsal and ventral is
if you are unsure about whether AP and DV orientation is correct in the straightened stack, go back to the original data for this position and try to figure it out based on gonadal morphology, vulval cell location etc.
3/ once AP and DV orientation is corrected, it asks you to do see at which x-coordinate the data starts and at which it ends, scroll through z and t to get the maximum extent of the worm data
4/ it will process the data in chops, asking you to specify the range of z slices that should be maximum-z-projected for further spot analysis
5/ it will ask you to click on a landmark in the first frame and then on the same landmark in all subsequent frames

6/ it will save a registered z-stack in a folder named chop_xx in the position folder

7/ repeat steps 3/-6/ for each position and each chop

### Deletion of bad frames
open FIJI and then for each chop_0.tif in each position pos0
scroll through the frames and evaluate them for movement
open a text file with textedit, and write the indices of the frames that should be deleted before tracking can begin
be generous here, because nothing is worse than messed up tracking, delete frames with too much movement of the cells or frames that are blurry
save the text file under frames2delete.txt in the chop0 folder
if you think that all frames can be used, do not save any file for this chop
repeat for each chop of each position
open macro "/home/keil-workstation/Desktop/Wolfgang/fiji/delete_invalid_frames.ijm"
change the lines about experiment_folder, worm_index and channels in the script according to your needs
run the macro

This macro generates two files GFP_stackreg.tiff and mCherry_stackreg.tiff in each chop folder 
It's a good idea to open these files and check that the right frames have been deleted and cells are really stable for tracking



## License
Copyright (c) [2023] [Wolfgang Keil]

This repositry contains free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

All code is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details at <https://www.gnu.org/licenses/>.

=======

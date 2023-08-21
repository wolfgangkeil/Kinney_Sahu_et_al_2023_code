<<<<<<< HEAD
# Code accompanying Stec et al. Current Biology, 2020

This repository contains whole-animal fluorescence traces obtained from long-term live imaging with Microfluidics (Keil et al. Dev Cell 2017) as well as MATLAB® scripts to replicate the analyses of pulsatile gene expression, performed in Stec et al. Current Biology (2020), Figure 5.

If you use parts of this code please cite:
Stec Natalia, Doerfel Katja, Hills-Muckey Kelly , Ettorre Victoria, Ercan Sevinc, Keil Wolfgang, Hammell Christopher
An Epigenetic Priming Mechanism Mediated by Nutrient Sensing Regulates Transcriptional Output during C. elegans Development
Current Biology (2020), https://doi.org/10.1016/j.cub.2020.11.060

For questions, please contact wolfgang.keil@curie.fr

## Data
All data is contained in the subfolder 'data/'. Subfolders within 'data/' are named according to the C. elegans strain names (e.g. GR1395, HML474, see Key Resources Table in STAR Methods of Stec et al  Curr Biol 2020).  The 'data/' folder also contains .txt files (e.g. 'HML474_list.txt', 'all_WT_list.txt') which specify lists of individual animals that can be analyzed or plotted together.


Within the strain folders, for each animal, information about experimental conditions and the molting times as scored manually from the imaging data, is contained in .txt files, e.g. 'data/HML474/HML474_02-Feb-2018_2_2.txt'. These files are parsed by the function 'read_single_worm_molting_data' (see below). The .mat files with the same filenames contain the fluorescence time traces as well as information about background and parameter values of the Gaussian peaks fitted to the background-subtracted fluorescence time traces.  

## Plotting individual fluorescence time courses for pulsatile gene expression together with Gaussian fits
Start by executing  'plot_worm_overview('data/', 'HML474','HML474_list.txt', 'GFP', 15,'constant_bg')' as an example. You will see a plot showing all the fluorescence time traces overlaid with the corresponding Gaussian fits.  By changing the strain and and list name, you can plot different genetic backgrounds or fluorescent reporter genes.
Inside this script, there are two flags (lines 32 and 33) that can be set to '1' in order to go through the peak fitting and background subtraction procedure: 
%    %%%%%% set these  these flags to '1' forces re-doing of the individual steps
%    compute_background = 0; 
%    redo_fitting = 0;

Setting compute_background to one, will open a plot showing the fluorescence time trace and asking you to input a few values on the graph that you would consider background, i.e. in between gene expression peaks. The function will compute the resulting background (either a constant value (as in Stec et al., 2020)) or a polynomial or a cubic spline. 

Setting redo_fitting to one will fit the peaks to the individual traces, will open a plot showing the fluorescence time trace and asking you to input the interval within each larval stage that you would use to fit a peak of the same larval stage. Note that because peaks often times extend into the next larval stage, this interval is not necessarily between to molts. 

## Analysis of dynamic features (onset, peak phase, duration etc.) in each larval stage
Start by executing  'plot_peak_statistics_comparison({'data/', 'data/'}, {'GR1395', 'HML274'},{'GR1395_list.txt','HML274_list.txt'},{'WT','blmp-1(0)'}, 'mlt-10');' as an example. This will replicate figure 5J of Stec et al. 2020. By changing the strain and and list names, you can compare different genetic backgrounds for the same reporter gene to each other.

## Installation

Download by

$ git clone  https://github.com/wolfgangkeil/Stec_et_al_2020_code.git


## License
Copyright (c) [2020] [Wolfgang Keil]

This repositry contains free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

All code is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details at <https://www.gnu.org/licenses/>.
=======
# Kinney_Sahu_et_al_2023_code
Code for MS2-MCP-GFP data analysis
>>>>>>> 8893d3d3ed0f0a4efd5017b4ef379a6df97d35dc

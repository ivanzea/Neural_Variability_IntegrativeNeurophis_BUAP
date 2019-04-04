%% Neuronal Variability - Analysis Pipeline (neuvarap)
%% Fresh start
clear; clc; close all;
%% Define Prprocessing Parameters
% Subject names (folder names) to process | if empty {} -> all subjects/folders will be used
subject_list = {};

% Overwrite files
s1ovrwrt = 0;
s2ovrwrt = 0;

% =========================================================================
% Step 2 parameters:
trial_thr = 25;
block_thr = 7;
stim_dict = {'Visual' 'Auditory' 'Somatosensory'};

%% Detect running path 
main_path = mfilename('fullpath');
if ~isempty(main_path)
    temp = matlab.desktop.editor.getActive; % what path is being used to run this program?
    main_path = regexprep(temp.Filename, '(.+)\\.+\\.+\\.+\.m', '$1');
end

% %% Initialize parallel processing
% % Initialize parallel pool
% if isempty(gcp('nocreate'))
%     parpool();
% end

%% Add code base from src and ext folders
% Add path
addpath(genpath([main_path '\src'])); % source code
addpath([main_path '\ext']); % extensions code

% %Check for existing eeglab libraries
% if isempty(which('eeglab'))
%     addpath([main_path '\ext\eeglab14_1_2b']); % extensions
% else
%     rmpath(which('eeglab')); % remove existing path and use the one provided
%     addpath([main_path '\ext\eeglab14_1_2b']); % extensions
% end
% 
% % Add location file becuase it is inside eeglab library... comment out if
% % a file is external
% electrode_location_full = [main_path electrode_location];
% 
% % Initialize eeglab
% eeglab();
% clear ALLCOM ALLEEG CURRENTSET CURRENTSTUDY EEG LASTCOM PLUGINLIST STUDY eeglabUpdater;
close all;
clc;

%% 1) Merge the preprocessing pipeline files into one unified data structure
neurvarap_datamerge(main_path, s1ovrwrt);

%% 2) Analyze amplitude data
neurvarap_amplitude(main_path, subject_list, trial_thr, block_thr, stim_dict, s2ovrwrt)
%% Neuronal Variability - Preprocessing Pipeline (neuvarpp)
%% Fresh start
clear; clc; close all;
%% Define Prprocessing Parameters
% Subject names (folder names) to process | if empty {} -> all subjects/folders will be used
subject_list = {'Abraham'};

% Overwrite files
s1ovrwrt = 0;
s2ovrwrt = 0;
s3ovrwrt = 0;
s4ovrwrt = 1;
s5ovrwrt = 1;
s6ovrwrt = 1;

% =========================================================================
% Step 2 parameters:
% Trigger timming correction
correction_table = {
                        'Abraham' {'180911' '180922' '181003' '181016' '181030'} [0.05 0.05 0.05 0.05 0.05];
                        'Amalia' {'181008'} [0.05];
                        'Dalia' {'190305'} [0.05];
                        'Diana' {'181002' '181003' '181016' '190219' '190228'} [0.05 0.05 0.05 0.05 0.05];
                        'Felipe' {'180928'} [0.05];
                        'Gustavo' {'181008'} [0.05];
                        'Hector' {'180816' '180821' '180920' '180927' '181001'} [-0.02 -0.02 0.05 0.05 0.05];
                        'Ivan' {'181016' '181019' '181023' '181030' '190128'} [0.05 0.05 0.05 0.05 0.05];
                        'Ivette' {'181011'} [0.05];
                        'Jessica' {'190219' '190225' '190228'} [0.05 0.05 0.05];
                        'Jesus' {'180820' '180821' '180911' '180927' '181003'} [-0.2 -0.2 0.05 0.05 0.05];
                        'Jorge' {'180919' '180927' '181003' '181016' '181018'} [0.05 0.05 0.05 0.05 0.05];
                        'Leo' {'181010'} [0.05];
                        'Natalie' {'181010'} [0.05];
                        'Otto' {'180917' '180926' '180928' '181018' '181019'} [0.05 0.05 0.05 0.05 0.05];
                        'Paola' {'181010'} [0.05];
                        'Paty' {'181005'} [0.05];
                        'Pedro'  {'180820' '180821' '180904' '180911' '181030'}  [-0.02 -0.02 0.05 0.05 0.05];
                        'Roberto' {'180821'} [0.05];
                        'Rodrigo' {'181011'} [0.05];
                        'Vicky' {'181011'} [0.05];
                        'Victoria' {'181008'} [0.05]
                   };

% Spontaneous event threshold
spontaneous_thr = 0.1; % 100ms

% End event threshold
end_thr = 3.00; % 3sec

% Maximum delay accepted between event before being flaged for correction
max_delay = 0.01; % 10ms

% =========================================================================
% Step 3 parameters:
% Downsamplint rate
ds_rate = 128; % Hz
high_pass = 1; % Hz
low_pass = 40; % Hz

% =========================================================================
% Step 4 parameters:
% Electrode location template file
electrode_location = '\ext\location_files\Standard-10-5-Cap385_witheog.elp'; % this one is inside eeglabs path

% Known EEG channels without ERP signal
ignore_ch = {'CB1' 'CB2' 'HEO' 'VEO' 'EKG' 'EMG' 'HL1' 'M1' 'M2'};

% ASR params
corr_asr = 0.8; % percent correlation with neighboring channels to retain it
std_asr = 10; % number of standard deviations from calibration data variance to flag for ASR
windowthr_asr = 0.5; % percent of channels in a specific 1s window that are flagged as bad after ASR to reject window

% =========================================================================
% Step 6 parameters:
% Epoching parameters
epoch_len = [-0.2, 0.5]; % epoch boundaries in seconds
bl_len = [-200, 0]; % baseline boundaries in ms

%% Detect running path 
main_path = mfilename('fullpath');
if ~isempty(main_path)
    temp = matlab.desktop.editor.getActive; % what path is being used to run this program?
    main_path = regexprep(temp.Filename, '(.+)\\.+\\.+\\.+\.m', '$1');
end

%% Initialize parallel processing
% Initialize parallel pool
if isempty(gcp('nocreate'))
    parpool();
end

%% Add code base from src and ext folders
% Add path
addpath(genpath([main_path '\src'])); % source code
addpath([main_path '\ext']); % extensions code

%Check for existing eeglab libraries
if isempty(which('eeglab'))
    addpath([main_path '\ext\eeglab14_1_2b']); % extensions
else
    rmpath(which('eeglab')); % remove existing path and use the one provided
    addpath([main_path '\ext\eeglab14_1_2b']); % extensions
end

% Add location file becuase it is inside eeglab library... comment out if
% a file is external
electrode_location_full = [main_path electrode_location];

% Initialize eeglab
eeglab();
clear ALLCOM ALLEEG CURRENTSET CURRENTSTUDY EEG LASTCOM PLUGINLIST STUDY eeglabUpdater;
close all;
clc;

%% 1) Convert CNT to SET files (EEGLAB standards)
neurvarpp_cnt2set(main_path, subject_list, s1ovrwrt);

%% 2) Crosscheck and transfer event information
neuvarpp_eventcor(main_path, subject_list, correction_table, spontaneous_thr, end_thr, max_delay, s2ovrwrt);

%% 3) Downsample data - high&low pass filter
neuvarpp_filtering(main_path, subject_list, ds_rate, high_pass, low_pass, s3ovrwrt);

%% 4) Add location data and perform non-stanionary filtering 
neuvarpp_nonstationaryclean(main_path, subject_list, electrode_location_full, ignore_ch, corr_asr, std_asr, windowthr_asr, s4ovrwrt);

%% 5) Remove artifacts using MARA with SOBI
neuvarpp_stationaryclean(main_path, subject_list, s5ovrwrt);

%% 6) Epoch data convert to matlab structure
neuvarpp_epochs(main_path, subject_list, epoch_len, bl_len, s6ovrwrt);

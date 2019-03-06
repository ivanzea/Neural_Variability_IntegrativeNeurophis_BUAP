function neuvarpp_nonstationaryclean(main_path, subject_list, electrode_location, ignore_ch, corr_asr, std_asr, windowthr_asr, overwrite)
%{
neuvarpp_nonstationaryclean(main_path, subject_list, electrode_location, ignore_ch, corr_asr, std_asr, windowthr_asr, overwrite=0)

Start cleaning the signals by applying non-stationary filtering methods
specifically Artifact Subspace Reconstruction (ASR) and PREP's robust
averaging

Input:
    main_path           String containing the full path to the Main folder.  

    subject_list        Cell array of strings that contain the name of the
                        folders under the RawData folder. The list and the
                        folder names are assumed to be the subject names/tags
                        with which they will be identified throughout the
                        preprocessing pipeline. 
                        Ex - {'SubjectI' 'SubjectII'}

    electrode_location  String containing the full path to the electrode
                        location file
    
    ignore_ch           Cell array with the code names of the channels to
                        to be ignored because they lack ERP information

    corr_asr            Percentual proportion of porrly correlated channel
                        threshold for ASR
    
    std_asr             Number of standard deviations from normal signal
                        variance to use as threshold for high varience
                        subspace reconstruction (actual ASR step)

    windowthr_asr       Percentual proportion of flagged bad channels in 1s
                        windows to use as threshold for rejection that
                        windowed segment of data in all channels

    overwrite           Boolean value where:
                            0 -> skip files already converted.
                            1 -> convert all files provided. 
                        Default = 0

Output:
    *_nonstationaryclean.set      Output files with specific postfix for 
                                  this pipeline step. Files are unde the 
                                  folder: Main\PipelineData\Subject\

%}
%% Check input arguments
% How many arguments?
minArgs = 7;
maxArgs = 8;
narginchk(minArgs,maxArgs);

% Set default values
switch nargin
    case 5
        overwrite = 0;
end

% Where is the data?
ppdata_path = [main_path '\PipelineData'];

% If subject varible is empty, use all subjects as targets
if isempty(subject_list)
    temp = dir(ppdata_path);
    subject_list = {temp(3:end).name};
end

%% Take steps to standarize the eeg signals
% Loop through each subject's data
for subjectindex = 1:length(subject_list)
   % Initialize subject specific variables
   input_path = [ppdata_path '\' subject_list{subjectindex}]; % where are the prepped .set files
   input_naming = '_filtered.set'; % how to identify prepped set files
   output_path = [ppdata_path '\' subject_list{subjectindex}]; % where are the standard .set files going to be saved
   output_naming = '_nonstationaryclean.set'; % how to identify standarized files
   
   % Are we going to overwrite files?
   if overwrite
       temp = dir([input_path '\*' input_naming]);
       input_file_list = {temp.name};
       output_file_list = regexprep(input_file_list, input_naming, output_naming);
   else
       % Check which files have already been analyzed
       [input_file_list, output_file_list] = newfiles_check(input_path, output_path, input_naming, output_naming);
   end
   
   % Is there any new file
   if ~isempty(input_file_list)
       
       % Loop through each file
       for fileindex = 1:length(input_file_list)
           % Load the input raw set file
           set_file = pop_loadset(input_file_list{fileindex}, input_path);

% =========================================================================
           % Step 1: Add location data to the file
           set_file = pop_chanedit(set_file, 'lookup', electrode_location, 'load', []);
           
           % Remove channels without location
           exclude_ch = find(ismember({set_file.chanlocs.labels}, ignore_ch));
           set_file = pop_select(set_file, 'nochannel', exclude_ch);

% =========================================================================           
           % Step 2: Identify bad channels and interpolate
           new_set_file = clean_rawdata(set_file, -1, -1, corr_asr, -1, std_asr, windowthr_asr);
           set_file = pop_interp(new_set_file, set_file.chanlocs, 'spherical');
           
% =========================================================================           
           % Step 3: Re-reference to robust average
           [set_file, ~] = performReference(set_file);
           
           % Save the .set file in 'SetData' folder
           pop_saveset(set_file, ...
                       'filename', output_file_list{fileindex}, ...
                       'filepath', output_path);
       end
   end
end
disp('Step 4 DONE');

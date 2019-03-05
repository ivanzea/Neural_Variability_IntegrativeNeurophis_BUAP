function neuvarpp_filtering(main_path, subject_list, ds_rate, high_pass, low_pass, overwrite)
%{
neuvarpp_filtering(main_path, subject_list, ds_rate, high_pass, low_pass, overwrite=0)

Change signal frequency properties using downsampling, high & low pass
filtering

Input:
    main_path           String containing the full path to the Main folder.  

    subject_list        Cell array of strings that contain the name of the
                        folders under the RawData folder. The list and the
                        folder names are assumed to be the subject names/tags
                        with which they will be identified throughout the
                        preprocessing pipeline. 
                        Ex - {'SubjectI' 'SubjectII'}

    ds_rate             Dounsampling rate in Hz
    
    high_pass           High pass filter in Hz

    low_pass            Low pass filter in Hz

    overwrite           Boolean value where:
                            0 -> skip files already converted.
                            1 -> convert all files provided. 
                        Default = 0

Output:
    *_filtered.set      Output files with specific postfix for this pipeline
                        step. Files are unde the folder:
                            Main\PipelineData\Subject\

%}
%% Check input arguments
% How many arguments?
minArgs = 5;
maxArgs = 6;
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
% Where is the location file
% Use the BESA standard location information to add it to the set
eeglabpath = regexprep(which('eeglab'), '(.*)\\eeglab.m', '$1');
electrode_location = [eeglabpath '\functions\resources\Standard-10-5-Cap385_witheog.elp']; % BESA standard location template

% Loop through each subject's data
for subjectindex = 1:length(subject_list)
   % Initialize subject specific variables
   input_path = [ppdata_path '\' subject_list{subjectindex}]; % where are the prepped .set files
   input_naming = '_eventcor.set'; % how to identify prepped set files
   output_path = [ppdata_path '\' subject_list{subjectindex}]; % where are the standard .set files going to be saved
   output_naming = '_filtered.set'; % how to identify standarized files
   
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
           % Step 1: Change sampling rate
           set_file = pop_resample(set_file, ds_rate);
           
% =========================================================================
           % Step 2: Band pass filter
           set_file = pop_eegfiltnew(set_file, high_pass, low_pass, [], 0, [], 0);  
           
           % Save the .set file in 'SetData' folder
           pop_saveset(set_file, ...
                       'filename', output_file_list{fileindex}, ...
                       'filepath', output_path);
       end
   end
end
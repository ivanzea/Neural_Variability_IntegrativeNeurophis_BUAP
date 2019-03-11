function neuvarpp_epochs(main_path, subject_list, epoch_len, bl_len, overwrite)
%{
neuvarpp_epochs(main_path, subject_list, epoch_len, bl_len overwrite=0)

Epoch the data for each unique event type and apply baseline correction.

Input:
    main_path           String containing the full path to the Main folder.  

    subject_list        Cell array of strings that contain the name of the
                        folders under the RawData folder. The list and the
                        folder names are assumed to be the subject names/tags
                        with which they will be identified throughout the
                        preprocessing pipeline. 
                        Ex - {'SubjectI' 'SubjectII'}

    epoch_len           Array with 2 values denoting the start and end time
                        boundaries around each event which will be epoched

    bl_len              Array with 2 values denoting the start and ent time
                        boundaries where baseline correction will be
                        applyed for each epoch

    overwrite           Boolean value where:
                            0 -> skip files already converted.
                            1 -> convert all files provided. 
                        Default = 0

Output:
    *_epochs.set        Output files with specific postfix for this 
                        pipeline step. Files are unde the folder:
                        Main\PipelineData\Subject\

%}
%% Check input arguments
% How many arguments?
minArgs = 4;
maxArgs = 5;
narginchk(minArgs,maxArgs);

% Set default values
switch nargin
    case 4
        overwrite = 0;
end

% Where is the raw set data
setdata_path = [main_path '\PipelineData'];

% If subject varible is empty, use all subjects as targets
if isempty(subject_list)
    temp = dir(setdata_path);
    subject_list = {temp(3:end).name};
end

%%
% Loop through each subject's data
for subjectindex = 1:length(subject_list)
   % Initialize subject specific variables
   input_path = [setdata_path '\' subject_list{subjectindex}]; % where are the files
   input_naming = '_stationaryclean.set'; % how to identify files
   output_path = [setdata_path '\' subject_list{subjectindex}]; % where are the files going to be saved
   output_naming = '_epochs.mat'; % how to identify files
   
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

           % Find events
           unique_events = unique([set_file.urevent.type]);

           % Initialize set_info variable
           set_info = [];
           
           for stimtypeindex = 1:length(unique_events)
               % Generate epoch data with baseline correction
               epoch_set_file = pop_epoch(set_file, {num2str(unique_events(stimtypeindex))}, epoch_len);
               epoch_set_file = pop_rmbase(epoch_set_file, bl_len);
               
               % Get all info from the set file
               set_info(stimtypeindex).filename = regexprep(epoch_set_file.filename, '(.+)_.+', '$1');
               set_info(stimtypeindex).stimtype = stimtypeindex;
               set_info(stimtypeindex).chnames = {epoch_set_file.chanlocs.labels};
               set_info(stimtypeindex).srate = epoch_set_file.srate;
               set_info(stimtypeindex).times = epoch_set_file.times;
               set_info(stimtypeindex).epochs = epoch_set_file.data;
           end

           % Save the .set file in 'SetData' folder
           save([output_path '\' output_file_list{fileindex}], 'set_info');
       end
   end
end
function neurvarpp_cnt2set(main_path, subject_list, overwrite)
%{
neuvarpp_cnt2set(main_path, subject_list, overwrite=0)

Convert *.cnt to *_raw.set files

Input:
    main_path       String containing the full path to the Main folder.  
                    Ex - 'C:\Users\Lab\Desktop\ExperimentX'

    subject_list    Cell array of strings that contain the name of the
                    folders under the RawData folder. The list and the
                    folder names are assumed to be the subject names/tags
                    with which they will be identified throughout the
                    preprocessing pipeline. 
                    Ex - {'SubjectI' 'SubjectII'}

    overwrite       Boolean value where:
                       0 -> skip files already converted.
                       1 -> convert all files provided. 
                    Default = 0

Output:
    *_raw.set       Output files with specific postfix for this pipeline
                    step. Files are unde the folder:
                        Main\PipelineData\Subject\

%}

%% Check input arguments
% How many arguments?
minArgs = 2;
maxArgs = 3;
narginchk(minArgs,maxArgs);

% Set default values
switch nargin
    case 2
        overwrite = 0;
end

% Where is the cnt data? -> RawData path
input_folder = [main_path '\RawData'];

% Where is the set data going to be saved?
output_folder = [main_path '\PipelineData'];

% If subject varible is empty, use all subjects as targets
if isempty(subject_list)
    temp = dir(input_folder);
    subject_list = {temp(3:end).name};
end

%% Convert CNT to SET files
% Loop through each subject's data
for subjectindex = 1:length(subject_list)
   % Initialize subject specific variables
   input_path = [input_folder '\' subject_list{subjectindex}]; % where are the raw .cnt files
   input_naming = '.cnt'; % how to identify raw files
   output_path = [output_folder '\' subject_list{subjectindex}]; % where are the converted .set files going to be saved
   output_naming = '_raw.set'; % how to identify converted files
   
   % Are we going to overwrite files?
   if overwrite
       temp = dir([input_path '\*' input_naming]);
       input_file_list = {temp.name};
       output_file_list = regexprep(input_file_list, input_naming, output_naming);
   else
       % Check which files have already been analyzed
       [input_file_list, output_file_list] = newfiles_check(input_path, output_path, input_naming, output_naming);
   end
   
   % Is there any file to be converted?
   if ~isempty(input_file_list)
       % Check that the output folder exists, if it doesn't... create it
       if ~exist(output_path, 'dir')
          mkdir(output_path);
       end
       
       % Loop through each file to be converted
       parfor fileindex = 1:length(input_file_list)
            if isempty(regexp(input_file_list{fileindex}, '(close|open|alpha)', 'once')) % avoid files used as references
               
               % Import cnt files by converting to set files
               try
               converted_set = pop_loadcnt([input_path '\' input_file_list{fileindex}], 'keystroke', 'on');

               % Save output files
               pop_saveset(converted_set, ...
                           'filename', output_file_list{fileindex}, ...
                           'filepath', output_path);
               catch
                   disp(['File Load Error: ' input_path '\' input_file_list{fileindex}]);
               end
            end
       end
   end
end
disp('Step 1 DONE');

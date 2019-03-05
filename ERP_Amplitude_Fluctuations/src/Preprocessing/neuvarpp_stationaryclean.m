function neuvarpp_stationaryclean(main_path, subject_list, overwrite)
%{
neuvarpp_stationaryclean(main_path, subject_list, overwrite=0)

Cleaning the signals using stationary filtering methods. In this case we
use Automatic Indecpendent Component Analysis artifact rejection (MARA) and
ICA is calculated using the SOBI method.

Input:
    main_path           String containing the full path to the Main folder.  

    subject_list        Cell array of strings that contain the name of the
                        folders under the RawData folder. The list and the
                        folder names are assumed to be the subject names/tags
                        with which they will be identified throughout the
                        preprocessing pipeline. 
                        Ex - {'SubjectI' 'SubjectII'}

    overwrite           Boolean value where:
                            0 -> skip files already converted.
                            1 -> convert all files provided. 
                        Default = 0

Output:
    *_stationaryclean.set      Output files with specific postfix for this 
                               pipeline step. Files are unde the folder:
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

% Where is the prepped data -> SetData path
setdata_path = [main_path '\PipelineData'];

% If subject varible is empty, use all subjects as targets
if isempty(subject_list)
    temp = dir(setdata_path);
    subject_list = {temp(3:end).name};
end

%% Take steps to detect and correct artifacts
% Loop through each subject's data
for subjectindex = 1:length(subject_list)
   % Initialize subject specific variables
   input_path = [setdata_path '\' subject_list{subjectindex}]; % where are the standarized .set files
   input_naming = '_nonstationaryclean.set'; % how to identify standarized set files
   output_path = [setdata_path '\' subject_list{subjectindex}]; % where are the artifact corrected .set files going to be saved
   output_naming = '_stationaryclean.set'; % how to identify artifact corrected files
   
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
           % Step 1: Calculate ICA components using SOBI method
           % Make data fullrank
           dataRank = rank(set_file.data');
           channelSubset = loc_subsets(set_file.chanlocs, dataRank);
           set_file = pop_select(set_file, 'channel', channelSubset{1});
           set_file = pop_chanedit(set_file, 'eval', 'chans = pop_chancenter(chans, [], []);');
           
           % Apply SOBI           
           [winv, act] = sobi(set_file.data);
           set_file.icaact = act;
           set_file.icachansind = 1:size(winv,1);
           set_file.icawinv = winv;
           set_file.icaweights = pinv(winv); 
           set_file.icasphere = eye(size(winv,1));
                              
% =========================================================================           
           % Step 2: Remove IC using MARA
           artifact_components = MARA(set_file);
                      
           % Remove Artifacts using MARA results
           set_file = pop_subcomp(set_file, artifact_components, 0, 0);

           % Save the .set file in 'SetData' folder
           pop_saveset(set_file, ...
                       'filename', output_file_list{fileindex}, ...
                       'filepath', output_path);
       end
   end
end
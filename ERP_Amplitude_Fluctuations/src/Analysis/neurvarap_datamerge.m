function neurvarap_datamerge(main_path, overwrite)
%{
neurvarap_datamerge(main_path, overwrite=0)

Merge all the final output data from the Preprocessing Pipeline into a 
single matlab structure

Input:
    main_path           String containing the full path to the Main folder.

    overwrite           Boolean value where:
                            0 -> skip files already converted.
                            1 -> convert all files provided. 
                        Default = 0

Output:
    erp_data.mat        Matlab structure containing all ERP data and 
                        usefull information to continue analysis

%}
%% Check input arguments
% How many arguments?
minArgs = 1;
maxArgs = 2;
narginchk(minArgs,maxArgs);

% Set default values
switch nargin
    case 1
        overwrite = 0;
end

% Where is the data?
ppdata_path = [main_path '\PipelineData'];

% Use all subject folders as target folders
temp = dir(ppdata_path);
subject_list = {temp(4:end).name};

output_full = [main_path '\FinalData\erp_data.mat'];

%%
% Load merged data, if it exists
if exist(output_full, 'file') && ~overwrite% check if file exists
    load(output_full, 'erp_data'); % load existing file
    entry_index = length(erp_data);
else
    erp_data = [];
    erp_data.filename = '';
    entry_index = 0;
end

% Get files to be merged
file_list = dir([ppdata_path '\*\*_epochs.mat']);
file_list = {file_list.name};

% Get list of processed files
existing_files = {erp_data.filename};

% Loop through each file
for fileindex = 1:length(file_list)
   % Check if the file has an entry already
   file_flag = sum(ismember(existing_files, file_list{fileindex}));
   cfile = file_list{fileindex};
   
   if file_flag == 0
       % Get info from the file
       subject_name = regexprep(file_list{fileindex}, '(.+)_.+_\d{6}\d{3}_.+', '$1');
       sess_id = regexprep(file_list{fileindex}, '.+_.+_(\d{6})\d{3}_.+', '$1');
       block = regexprep(file_list{fileindex}, '.+_.+_\d{6}(\d{3})_.+', '$1');
       
       % Load the current file
       cfull = [ppdata_path '\' subject_name '\' cfile];
       load(cfull, 'set_info');
       
       % Get data into structure
       for set_stim = 1:length(set_info)
           entry_index = entry_index + 1; % change the index
           
           erp_data(entry_index).filename = set_info(set_stim).filename;
           erp_data(entry_index).subject = subject_name;
           erp_data(entry_index).sess_id = sess_id;
           erp_data(entry_index).block = block;
           erp_data(entry_index).stimtype = set_info(set_stim).stimtype;
           erp_data(entry_index).chnames = set_info(set_stim).chnames;
           erp_data(entry_index).srate = set_info(set_stim).srate;
           erp_data(entry_index).times = set_info(set_stim).times;
           erp_data(entry_index).epochs = set_info(set_stim).epochs;
       end  
   end
end

% Save the file
save(output_full, 'erp_data');

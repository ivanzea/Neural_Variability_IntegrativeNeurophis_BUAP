function neurvarap_datamerge(main_path)
%{
neurvarap_datamerge(main_path, overwrite=0)

Merge all the final output data from the Preprocessing Pipeline into a
single matlab structure

Input:
    main_path             String containing the full path to the Main folder.

Output:
    erp_data.mat          Matlab structure containing all ERP data and
                          usefull information to continue analysis
%}
%% Check input arguments
% How many arguments?
minArgs = 1;
maxArgs = 1;
narginchk(minArgs,maxArgs);

% Where is the data?
ppdata_path = [main_path '\PipelineData'];

output_full = [main_path '\FinalData\erp_data.mat'];

%%
% =========================================================================
% Step 1: Load and merged data
erp_data = [];
erp_data.filename = '';
entry_index = 0;

% Get files to be merged
file_list = dir([ppdata_path '\*\*_epochs.mat']);
file_list = {file_list.name};

% Get list of processed files
existing_files = {erp_data.filename};

% Keep track of progress
clc;
textprogressbar('Merging files : ');

% Loop through each file
for fileindex = 1:length(file_list)
    % Check if the file has an entry already
    cfile = file_list{fileindex};
    
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
        
        erp_data(entry_index).filename = file_list{fileindex};
        erp_data(entry_index).subject = subject_name;
        erp_data(entry_index).sess_id = sess_id;
        erp_data(entry_index).block = block;
        erp_data(entry_index).stimtype = set_stim;
        erp_data(entry_index).chnames = set_info(set_stim).chnames;
        erp_data(entry_index).srate = set_info(set_stim).srate;
        erp_data(entry_index).times = set_info(set_stim).times;
        erp_data(entry_index).epochs = set_info(set_stim).epochs;
    end
    
    % Update progress
    textprogressbar(fileindex/length(file_list)*100);
end
textprogressbar('DONE');

% =========================================================================
% Step 2: Re-structure data grouping by channel and block
% Loop through each subject
% Make subject lists
subject_list = {erp_data.subject};
unique_subject = unique(subject_list);

% Initialize variables
erp_data_reduced = [];
entry_index = 0;

unique_entries = [{erp_data.subject}' {erp_data.sess_id}' cellfun(@num2str, {erp_data.stimtype}, 'UniformOutput', false)'];
structure_size = length(unique(cellfun(@(x) [unique_entries{x,:}], num2cell(1:size(unique_entries,1)), 'UniformOutput', false)));

% Keep track of progress
textprogressbar('Reducing  : ');

for subjectindex = 1:length(unique_subject)
    % Make subject filter
    subject_filter = ismember(subject_list, unique_subject{subjectindex});
    
    % Select subject data
    subject_data = erp_data(subject_filter);
    
    % Make session id lists
    sess_list = {subject_data.sess_id};
    unique_sess = unique(sess_list);
    
    %Loop through each session
    for sessindex = 1:length(unique_sess)
        % Make sess filter
        sess_filter = ismember(sess_list , unique_sess{sessindex});
        
        % Select sess data
        sess_data = subject_data(sess_filter);
        
        % Make stim type lists
        stim_list = [sess_data.stimtype];
        unique_stim = unique(stim_list);
        
        % Loop through each stim
        for stimindex = 1:length(unique_stim)
            % Make stim filter
            stim_filter = stim_list == unique_stim(stimindex);
            
            % Select stim data
            stim_data = sess_data(stim_filter);
            
            % Get block data arranged by channel
            block_ch = {stim_data.chnames};
            all_ch = unique([block_ch{:}]);
            
            channel_data = cellfun(@(x) cellfun(@(a, b) squeeze(a(ismember(b,x),:,:)), ...
                {stim_data.epochs}, block_ch, 'UniformOutput', false),...
                all_ch, 'UniformOutput', false);
            
            % Change entry index
            entry_index = entry_index + 1;
            
            % Make new variable with the reduced block data by channel
            erp_data_reduced(entry_index).filename = {stim_data.filename};
            erp_data_reduced(entry_index).subject = unique_subject{subjectindex};
            erp_data_reduced(entry_index).sess_id = unique_sess{sessindex};
            erp_data_reduced(entry_index).stimtype = unique_stim(stimindex);
            erp_data_reduced(entry_index).chnames = all_ch;
            erp_data_reduced(entry_index).srate = [stim_data.srate];
            erp_data_reduced(entry_index).times = {stim_data.times};
            erp_data_reduced(entry_index).epochs = channel_data;
            
            % Update progress
            textprogressbar(entry_index/structure_size*100);
        end
    end
end
textprogressbar('DONE');

% Save the file
erp_data = erp_data_reduced;
fprintf('Saving...');
save(output_full, 'erp_data');
fprintf(' DONE\n');

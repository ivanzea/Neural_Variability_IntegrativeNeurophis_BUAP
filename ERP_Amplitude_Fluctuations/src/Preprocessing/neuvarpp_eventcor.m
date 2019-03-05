function neuvarpp_eventcor(main_path, subject_list, correction_table, spontaneous_thr, end_thr, max_delay, overwrite)
%{
neuvarpp_eventcor(main_path, subject_list, correction_table, spontaneous_thr, end_thr, max_delay, overwrite=0)

Clean event/trigger timestamps, checking for consistency with MATLAB file
pair data.

Input:
    main_path           String containing the full path to the Main folder.  

    subject_list        Cell array of strings that contain the name of the
                        folders under the RawData folder. The list and the
                        folder names are assumed to be the subject names/tags
                        with which they will be identified throughout the
                        preprocessing pipeline. 
                        Ex - {'SubjectI' 'SubjectII'}

    correction_table    Cell structure containing the SubjectsName, session
                        dates, and values in seconds that will be
                        corrected.
                        Ex - {'Lidia' {'180911' '181016'} [0.05 0.05]};

    spontaneous_thr     Number in milliseconds that determines the cutoff
                        for minimum timestamp distance

    end_thr             Number in seconds that detemines the cutoff for
                        maximum timestamp distance

    max_delay           Number in milliseconds that determines the maximum
                        tolerance between experimental and reference
                        timestamps

    overwrite           Boolean value where:
                            0 -> skip files already converted.
                            1 -> convert all files provided. 
                        Default = 0

Output:
    *_eventcor.set      Output files with specific postfix for this pipeline
                        step. Files are unde the folder:
                            Main\PipelineData\Subject\

%}
%% Check input arguments
% How many arguments?
minArgs = 6;
maxArgs = 7;
narginchk(minArgs,maxArgs);

% Set default values
switch nargin
    case 6
        overwrite = 0;
end

% Where is the data?
ppdata_path = [main_path '\PipelineData'];

% If subject varible is empty, use all subjects as targets
if isempty(subject_list)
    temp = dir(ppdata_path);
    subject_list = {temp(3:end).name};
end

%%
% Loop through each subject's data
for subjectindex = 1:length(subject_list)
   % Initialize subject specific variables
   input_path = [ppdata_path '\' subject_list{subjectindex}]; % where are the raw .set files
   input_naming = '_raw.set'; % how to identify raw set files
   output_path = [ppdata_path '\' subject_list{subjectindex}]; % where are the event checked .set files going to be saved
   output_naming = '_eventcor.set'; % how to identify checked files
   
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
           % Load .mat file containing data from the Experimental Control 
           % machine. Variable is called 'experiment_params'
           load([main_path '\RawData\' subject_list{subjectindex} '\' regexprep(input_file_list{fileindex}, '_raw\.set' ,'\.mat')], 'experiment_params');

           % Load the input file
           set_file = pop_loadset(input_file_list{fileindex}, input_path);

% =========================================================================
           % Step 1: Check for event consistency
           % Get timing data
           mat_t = experiment_params.timing_data;
           neuro_t = [set_file.event.latency]./set_file.srate;

           % Get isi data
           mat_isi = experiment_params.event_time(1:end-1);
           neuro_isi = diff(neuro_t);

           % Small checkups and removals
           neuro_isi(neuro_isi < spontaneous_thr) = []; % spontaneous duplicates

           % Long end event
           if neuro_isi(end) > end_thr
               neuro_isi(end) = [];
           end

           % Cross validate timing using Dynamic Time Warping
           [~, neuro_idx, mat_idx] = dtw(neuro_isi, mat_isi);
           extra_events = splitapply(@(x) {x}, neuro_idx, mat_idx); % find extra events

           % Eliminate extra events
           mat_idx_n = [];
           neuro_idx_n = [];
           for mateventindex = 1:length(extra_events)
               if length(extra_events{mateventindex}) == 1                     
                   mat_idx_n = [mat_idx_n; mateventindex];
                   neuro_idx_n = [neuro_idx_n; extra_events{mateventindex}];
               else
                   % Keep correct events
                   keep_idx = extra_events{mateventindex}(abs(diff([neuro_isi(extra_events{mateventindex}); repmat(mat_isi(mateventindex),1,length(extra_events{mateventindex}))])) <= max_delay);
                   if ~isempty(keep_idx)
                       mat_idx_n = [mat_idx_n; repmat(mateventindex,length(keep_idx),1)];
                       neuro_idx_n = [neuro_idx_n; keep_idx];
                   end
              end
           end

           % Add missing events
           missing_events = ~(abs(diff([mat_isi(mat_idx_n); neuro_isi(neuro_idx_n)])) <= max_delay);
           [labeledRegions, numRegions] = bwlabel(missing_events);

           for region_index = 1:numRegions
               if sum(labeledRegions == region_index) == 1
                   neuro_idx_n(labeledRegions == region_index) = nan;
                   mat_idx_n(labeledRegions == region_index) = nan;
               else
                   neuro_isi(neuro_idx_n(labeledRegions == region_index)) = mat_isi(mat_idx_n(labeledRegions == region_index));
               end
           end

           mat_idx_n = mat_idx_n(~isnan(mat_idx_n));
           neuro_idx_n = neuro_idx_n(~isnan(neuro_idx_n));

           % Change ISI values to latencies
           corrected_latencies = cumsum([neuro_t(neuro_idx_n(1)) neuro_isi(neuro_idx_n)]) .* set_file.srate;
           neuro_stimtype = experiment_params.event_type([mat_idx_n; mat_idx_n(end)+1]);

% =========================================================================
           % Step 2: Transfer labels to time stamps
           % Clear existing event variables
           set_file.event = [];
           set_file.urevent = [];

           % Move event types to the structure
           for eventindex = 1:length(corrected_latencies)
              set_file.event(eventindex).type = neuro_stimtype(eventindex);
              set_file.event(eventindex).latency = corrected_latencies(eventindex);
              set_file.event(eventindex).urevent = eventindex;

              set_file.urevent(eventindex).type = neuro_stimtype(eventindex);
              set_file.urevent(eventindex).latency = corrected_latencies(eventindex);
           end

% ========================================================================           
           % Setp 3: Correct known timming issues
           % Where is the subject in the correction table?
           tableindex = find(strcmp(subject_list{subjectindex}, correction_table(:,1)));

           if isempty(tableindex)
               correction_value = [];
           else
               % What session date are we looking at
               current_session = regexprep(input_file_list{fileindex}, '.+_(\d{6})\d{3}_.+', '$1');
               sessionindex = find(strcmp(current_session, correction_table{tableindex,2}));

               % What event correction is needed for that session?
               correction_value = correction_table{tableindex,3}(sessionindex) * set_file.srate;
           end

           % Make correction if needed
           if ~isempty(correction_value)
               for eventindex = 1:length([set_file.event.latency])
                  set_file.event(eventindex).latency = set_file.event(eventindex).latency + correction_value;
               end
           end

% =========================================================================
           % Save output files
           pop_saveset(set_file, ...
                       'filename', output_file_list{fileindex}, ...
                       'filepath', output_path);
       end
   end
end
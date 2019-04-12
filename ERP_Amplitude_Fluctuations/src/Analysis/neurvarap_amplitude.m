function neurvarap_amplitude(main_path, subject_list, trial_thr, block_thr, stim_dict, overwrite)
%{
neurvarap_amplitude(main_path, subject_list, trial_thr, block_thr, stim_dict, overwrite=0)

Merge all the final output data from the Preprocessing Pipeline into a
single matlab structure

Input:
    main_path             String containing the full path to the Main folder.
    
    subject_list          Cell array of strings that contain the name of the
                          folders under the RawData folder. The list and the
                          folder names are assumed to be the subject names/tags
                          with which they will be identified throughout the
                          preprocessing pipeline. 
                          Ex - {'SubjectI' 'SubjectII'}

    trial_thr             Threshold value for the minimum number of trials
                          required to have for each block for it not to be
                          discarded

    block_thr             Threshold value for the minimum number of blocks
                          required. If the threshold is not passed the
                          entire session is eliminated

    stim_dict             Cell with names of stimulus types located in each
                          position(index) representing the stimulus ID

    overwrite             Boolean value where:
                              0 -> skip files already converted.
                              1 -> convert all files provided.
                          Default = 0

Output:
    amplitude_data.mat    Matlab structure containing all ERP data and
                          analyzed results <- amplitudes, metrics, pvalues
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

% If subject varible is empty, use all subjects as targets
if isempty(subject_list)
    subject_list = unique({erp_data.subject});
end

%% Analyze Data :D
% Load erp_data.mat file
fprintf('Loading...');
load([main_path '\FinalData\erp_data.mat'], 'erp_data');
fprintf(' DONE\n');

% Check if the data structure already exists and manage if the data should
% be reanylized or skipped
output_full = [main_path '\FinalData\amplitude_data.mat'];
if exist(output_full, 'file') % check if file exists
    load(output_full, 'amplitude_data'); % load existing file
    output_entry_index = length(amplitude_data);
elseif overwrite
    amplitude_data = [];
    amplitude_data.subject = '';
    amplitude_data.ch = '';
    output_entry_index = 0;
end

% Select channels and bounds to use to detect amplitudes
% Loop through each subject
for subjectindex = 1:length(subject_list)
    % Make subject filter
    subject_filter = ismember({erp_data.subject}, subject_list{subjectindex});
    
    % If overwrite, delete the keys that exists already
    if overwrite
        output_entry_index = output_entry_index - sum(ismember({amplitude_data.subject}, subject_list{subjectindex}));
        amplitude_data(ismember({amplitude_data.subject}, subject_list{subjectindex})) = [];
    elseif sum(ismember({amplitude_data.subject}, subject_list{subjectindex})) % skip subject if there is an entry already
       continue; 
    end
    
    % Select subject data
    subject_data = erp_data(subject_filter);
    
    % Make session id lists
    sess_list = {subject_data.sess_id};
    unique_sess = unique(sess_list);
    
    % Make stim type lists
    stim_list = [subject_data.stimtype];
    unique_stim = unique(stim_list);
    
    % =========================================================================
    % Step 1: Filter data by number of blocks and single trials
    plot_data_temp = [];
    for dataindex = 1:length(subject_data)
        % Isolate selection
        cdata = subject_data(dataindex);
        
        entry_index = 0;
        for chindex = 1:length(cdata.chnames)
            % Isolate selection
            chdata = cdata.epochs{chindex};
            
            % Find empty blocks
            empty_blocks = cellfun(@(x) size(x,1) == 0, chdata);
            
            % Apply trial filter
            trial_filter = cellfun(@(x) size(x,2) >= trial_thr, chdata);
            trial_filter = ~(empty_blocks & trial_filter);
            
            block_filter = sum(trial_filter) >= block_thr;
            
            % Add data to data structure if it passes de thresholds
            if block_filter
                entry_index = entry_index + 1; % next index
                
                plot_data_temp.epochs{find(unique_stim == cdata.stimtype), find(ismember(unique_sess, cdata.sess_id))}{entry_index} = chdata(trial_filter);
                plot_data_temp.chinfo{find(unique_stim == cdata.stimtype), find(ismember(unique_sess, cdata.sess_id))}{entry_index} = cdata.chnames{chindex};
                plot_data_temp.times = cdata.times{1};
            end
        end
    end
    
    % =========================================================================
    % Step 2: Consolidate data by electrode location
    % Get unique channels by stim type
    unique_chGrpstim = cellfun(@(x) unique([plot_data_temp.chinfo{x,:}]), num2cell(unique_stim), 'UniformOutput', false);
    plot_data = [];
    
    for stimindex = 1:length(unique_stim)
        cepoch = [plot_data_temp.epochs{unique_stim(stimindex),:}];
        cch = [plot_data_temp.chinfo{unique_stim(stimindex),:}];
        
        entry_index = 0;
        
        for chindex = 1:length(unique_chGrpstim{unique_stim(stimindex)})
            chfilter = ismember(cch, unique_chGrpstim{unique_stim(stimindex)}{chindex});
            
            % Filter to check that the electrode has signal in all sessions
            if sum(chfilter) == size(plot_data_temp.epochs, 2)
                entry_index = entry_index + 1; % next index
                
                plot_data.epochs{stimindex}(entry_index,:) = cepoch(chfilter);
                plot_data.chinfo{stimindex}{entry_index} = unique_chGrpstim{unique_stim(stimindex)}{chindex};
            end
        end
    end
    plot_data.times = plot_data_temp.times;
    
    % =========================================================================
    % Step 3: Plot data and select electrodes of interest
    for stimindex = 1:length(plot_data.epochs)
        % Calculate epoch data mean by trial
        full_data = plot_data.epochs{stimindex};
        full_data = cellfun(@(x) cellfun(@(y) mean(y,2), x, 'UniformOutput', false), full_data, 'UniformOutput', false);
        
        % Calculate epoch data mean by session
        mean_data = cellfun(@(x) mean(horzcat(x{:}),2), full_data, 'UniformOutput', false);
        
        % Get some variables
        t = plot_data.times; % time in the x axis
        ch_data = plot_data.chinfo{stimindex};
        nplots = numSubplots(length(ch_data)); % subplot dimensions
        
        figure('units','normalized','outerposition',[0 0 1 1]);
        for chindex = 1:length(ch_data)
            y = horzcat(mean_data{chindex,:});
            
            subplot(nplots(1), nplots(2), chindex);
            hold on;
            plot(t,y, 'k');
            plot([min(t) max(t)], [0 0], 'k--');
            plot([0 0], [min(min(y)) max(max(y))], 'k--');
            hold off;
            
            title(ch_data{chindex});
            set(gca,'tag',num2str(chindex)); % add tag for selection followup
            axis tight;
        end
        suptitle([subject_list{subjectindex} ' : ' stim_dict{unique_stim(stimindex)}]);
        
        % Make channel selection
        selected_ch = [];
        while isempty(selected_ch)
            selected_ch = clicksubplot();
        end
        close all;
        
        % =========================================================================
        % Step 4: Boundary selection
        bound_ch = ch_data(cellfun(@str2num, selected_ch));
        bound_epochs = full_data(cellfun(@str2num, selected_ch),:);
        color_scheme = num2cell(brewermap(size(bound_epochs,2),'Set1'),2)';
        
        % Loop through each selected electrode
        for selectindex = 1:length(bound_ch)
            % Prepare data for plotting
            select_epochs = cellfun(@(x) horzcat(x{:}), bound_epochs(selectindex,:), 'UniformOutput', false);
            y = horzcat(select_epochs{:});
            
            gotonext = 0;
            xclick = [];
            while gotonext == 0
                % Plot electrode data
                figure('units', 'normalized', 'outerposition', [0 0 1 1]);
                
                subplot(2,6,[1 2 3 4 7 8 9 10]);
                hold on;
                cellfun(@(x,y) plot(t, x, 'Color', y, 'LineWidth', 1.5), select_epochs, color_scheme);
                plot([0 0], [min(y(:)), max(y(:))], '--k', 'LineWidth', 1.5);
                plot([min(t) max(t)], [0 0], '--k', 'LineWidth', 1.5);
                
                if ~isempty(xclick)
                    lbh = plot([xclick(1) xclick(1)], [min(y(:)), max(y(:))], 'r--', 'LineWidth', 1.5);
                    rbh = plot([xclick(2) xclick(2)], [min(y(:)), max(y(:))], 'r--', 'LineWidth', 1.5);
                end
                                
                title(bound_ch{selectindex});
                xlabel('Time [ms]');
                ylabel('Voltage [uV]');
                axis tight;
                
                % Make selection               
                [xclick(1), ~] = ginput(1);
                if exist('lbh', 'var')
                    lbh.delete;
                end
                plot([xclick(1) xclick(1)], [min(min(y)) max(max(y))], 'r--', 'LineWidth', 1.5);
                
                [xclick(2), ~] = ginput(1);
                if exist('rbh', 'var')
                    rbh.delete;
                end
                plot([xclick(2) xclick(2)], [min(min(y)) max(max(y))], 'r--', 'LineWidth', 1.5);
                
                segmentidx = find(t >= xclick(1) & t <= xclick(2));
                y_segment = cellfun(@(x) x(segmentidx,:), select_epochs, 'UniformOutput', false);
                
                if exist('lbh', 'var')
                    lbh.delete;
                    rbh.delete;
                end
                
                plot([xclick(2) xclick(2)], [min(min(y)) max(max(y))], 'r--', 'LineWidth', 1.5);
                
                % =========================================================================
                % Step 5: Calculate amplitudes and apply variability metric
                % Find max and min values withing boundaries
                [ampval, ampidx] = cellfun(@max, y_segment, 'UniformOutput', false);
                maxpoints = [[ampval{:}] ; t(segmentidx([ampidx{:}]))];
                
                [ampval, ampidx] = cellfun(@min, y_segment, 'UniformOutput', false);
                minpoints = [[ampval{:}] ; t(segmentidx([ampidx{:}]))];
                
                % Make grouping variable for session coloring and processing
                grps = arrayfun(@(x,y) repmat(y,1,x), cellfun(@(x) size(x,2), y_segment), 1:size(y_segment,2), 'UniformOutput', false);
                grps = [grps{:}];
                
                % Make jitter variable for scatter plots
                jitterX = splitapply(@(x) {x+linspace(-0.3,0.3,length(x))}, grps, grps);
                jitterX = [jitterX{:}];
                
                % Show max and min points in graph
                scatter(maxpoints(2,:), maxpoints(1,:), 100, 'g', 'filled');
                scatter(minpoints(2,:), minpoints(1,:), 100, 'r', 'filled');
                hold off;
                
                % Calculate raw amplitudes
                raw_amp = abs(maxpoints(1,:) - minpoints(1,:));
                
                % Plot raw amplitudes
                subplot(2,6,[5 6]);
                hold on;
                scatter(jitterX, raw_amp, [], vertcat(color_scheme{grps}), 'filled');
                boxplot(raw_amp, grps);
                hold off;
                rawpval = kruskalwallis(raw_amp, grps, 'off');
                title(['RAW AMPLITUDES pval=' num2str(rawpval)]);

                ampmetric = cellfun(@(y) y-mean(y), splitapply(@(x) {x},raw_amp, grps), 'UniformOutput', false);
                ampmetric = [ampmetric{:}];
                
                % Plot metric
                subplot(2,6,[11 12]);
                hold on;
                scatter(jitterX, ampmetric, [], vertcat(color_scheme{grps}), 'filled');
                boxplot(ampmetric, grps);
                hold off;
                pval = kruskalwallis(ampmetric, grps, 'off');
                title(['VARIABILITY METRIC pval=' num2str(pval)]);
                
                % Check if we should repeat or not
                while 1
                    w = waitforbuttonpress;
                    
                    if w == 1
                       key = get(gcf, 'currentcharacter');
                       if key == 27 % Esc key
                           break
                       elseif key == 83 || key == 115
                           independent_output = independent_session_selection(select_epochs, t, bound_ch{selectindex}, color_scheme);
                           
                           % Complete the output structure
                           independent_output.subject = subject_list{subjectindex};
                           independent_output.ch = bound_ch{selectindex};
                           independent_output.stimtype = stim_dict{unique_stim(stimindex)};
                           independent_output.fulldata = full_data(str2num(selected_ch{selectindex}),:);
                           independent_output.meandata = mean_data(str2num(selected_ch{selectindex}),:);
                           
                           % Save selcted data
                           gotonext = 1;
                           output_entry_index = output_entry_index + 1;
                           amplitude_data(output_entry_index) = independent_output;
                           save(output_full, 'amplitude_data');
                           
                           % Clear all figures
                           close all;
                           break
                       else
                           gotonext = 1;
                           output_entry_index = output_entry_index + 1;
                           
                           % Save selection data
                           amplitude_data(output_entry_index).subject = subject_list{subjectindex};
                           amplitude_data(output_entry_index).ch = bound_ch{selectindex};
                           amplitude_data(output_entry_index).stimtype = stim_dict{unique_stim(stimindex)};
                           amplitude_data(output_entry_index).fulldata = full_data(str2num(selected_ch{selectindex}),:);
                           amplitude_data(output_entry_index).meandata = mean_data(str2num(selected_ch{selectindex}),:);
                           amplitude_data(output_entry_index).time = t;
                           amplitude_data(output_entry_index).maxpt = maxpoints;
                           amplitude_data(output_entry_index).minpt = minpoints;
                           amplitude_data(output_entry_index).rawamp = raw_amp;
                           amplitude_data(output_entry_index).metric = ampmetric;
                           amplitude_data(output_entry_index).grps = grps;
                           amplitude_data(output_entry_index).jitter = jitterX;
                           amplitude_data(output_entry_index).rawpval = rawpval;
                           amplitude_data(output_entry_index).pval = pval;
                           
                           save(output_full, 'amplitude_data');
                           
                           % Clear figures
                           close all;
                           break
                       end
                    end
                end
            end
        end
    end 
end
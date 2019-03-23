%%
% Load erp_data.mat file
fprintf('Loading...');
load([main_path '\FinalData\erp_data.mat'], 'erp_data');
fprintf(' DONE\n');

% Select channels and bounds to use to detect amplitudes
% Make subject lists
subject_list = {erp_data.subject};
unique_subject = unique(subject_list);

output_full = [main_path '\FinalData\amplitude_data.mat'];
if exist(output_full, 'file') && ~overwrite% check if file exists
    load(output_full, 'amplitude_data'); % load existing file
    output_entry_index = length(amplitude_data);
else
    amplitude_data = [];
    amplitude_data.subject = '';
    output_entry_index = 0;
end

% Loop through each subject
for subjectindex = 2:length(unique_subject)
    % Make subject filter
    subject_filter = ismember(subject_list, unique_subject{subjectindex});
    
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
    trial_thr = 25; % <--------------------------------------------------------------------------- VAR
    block_thr = 7;  % <--------------------------------------------------------------------------- VAR
    
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
        stim_dict = {'Visual' 'Auditory' 'Somatosensory'}; % <--------------------------------------------------------------------------- VAR
        suptitle([unique_subject{subjectindex} ' : ' stim_dict{unique_stim(stimindex)}]);
        
        % Make channel selection
        selected_ch ={};
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
                maxpoints = [[ampval{:}] ; [ampidx{:}]];
                
                [ampval, ampidx] = cellfun(@min, y_segment, 'UniformOutput', false);
                minpoints = [[ampval{:}] ; [ampidx{:}]];
                
                % Make grouping variable for session coloring and processing
                grps = arrayfun(@(x,y) repmat(y,1,x), cellfun(@(x) size(x,2), y_segment), 1:size(y_segment,2), 'UniformOutput', false);
                grps = [grps{:}];
                
                % Make jitter variable for scatter plots
                jitterX = splitapply(@(x) {x+linspace(-0.3,0.3,length(x))}, grps, grps);
                jitterX = [jitterX{:}];
                
                % Show max and min points in graph
                scatter(t(segmentidx(maxpoints(2,:))), maxpoints(1,:), 100, 'k', 'filled');
                scatter(t(segmentidx(minpoints(2,:))), minpoints(1,:), 100, 'k', 'filled');
                hold off;
                
                % Calculate raw amplitudes
                raw_amp = abs(maxpoints(1,:) - minpoints(1,:));
                
                % Plot raw amplitudes
                subplot(2,6,[5 6]);
                hold on;
                scatter(jitterX, raw_amp, [], vertcat(color_scheme{grps}), 'filled');
                boxplot(raw_amp, grps);
                hold off;
                pval = kruskalwallis(raw_amp, grps, 'off');
                title(['RAW AMPLITUDES pval=' num2str(pval)]);
                
                % Calculate variance distribution approach
                vardist = cellfun(@(y) std(abs(bsxfun(@minus, y, y'))).^2, splitapply(@(x) {x},raw_amp, grps), 'UniformOutput', false);
                meandist = cellfun(@(y) mean(abs(bsxfun(@minus, y, y'))), splitapply(@(x) {x},raw_amp, grps), 'UniformOutput', false);
                ampmetric = [vardist{:}]./[meandist{:}];
                
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
                       else
                           gotonext = 1;
                           output_entry_index = output_entry_index + 1;
                           
                           % Save selection data
                           amplitude_data(output_entry_index).subject = unique_subject{subjectindex};
                           amplitude_data(output_entry_index).ch = bound_ch{selectindex};
                           amplitude_data(output_entry_index).stimtype = stim_dict{unique_stim(stimindex)};
                           amplitude_data(output_entry_index).fulldata = full_data;
                           amplitude_data(output_entry_index).meandata = mean_data;
                           amplitude_data(output_entry_index).time = t;
                           amplitude_data(output_entry_index).rawamp = raw_amp;
                           amplitude_data(output_entry_index).metric = ampmetric;
                           amplitude_data(output_entry_index).grps = grps;
                           amplitude_data(output_entry_index).jitter = jitterX;
                           amplitude_data(output_entry_index).pval = pval;
                           
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

% Save results
fprintf('Saving...');
save(output_full, 'amplitude_data');
fprintf(' DONE\n');
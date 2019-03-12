function visualize_epoch(epoch_len, bl_len)
%{
visualize_epoch()

Visualize data in epoch in order to comprehend how certain modifications to
the signal in the processing pipeline affect the aspect of epochs.

    epoch_len           Array with 2 values denoting the start and end time
                        boundaries around each event which will be epoched

    bl_len              Array with 2 values denoting the start and ent time
                        boundaries where baseline correction will be
                        applyed for each epoch
%}

%% Check input arguments
% How many arguments?
minArgs = 2;
maxArgs = 2;
narginchk(minArgs,maxArgs);

%% Select file to visualize
[file_name, file_path] = uigetfile('*.set', 'Choose a file');

% Load selected set file
set_file = pop_loadset(file_name, file_path);

%% Get epochs and create matlab structure
unique_events = unique([set_file.urevent.type]);
all_labels = {set_file.chanlocs.labels};

% Initialize variables
set_info = [];

% Get general info
set_info.general.srate = set_file.srate;
set_info.general.chnames = all_labels;

for stimtypeindex = 1:length(unique_events)
   % Generate epoch data with baseline correction
   epoch_set_file = pop_epoch(set_file, {num2str(unique_events(stimtypeindex))}, epoch_len);
   epoch_set_file = pop_rmbase(epoch_set_file, bl_len);

   % Get all info from the set file
   [~,loc_pair] = ismember(all_labels, {epoch_set_file.chanlocs.labels});
   loc_pair(loc_pair == 0) = NaN;
   
   for locindex = 1:length(all_labels)
      set_info.data(locindex).epoch{stimtypeindex} = mean(squeeze(epoch_set_file.data(loc_pair(locindex),:,:)),2);
   end
   
   set_info.general.time = epoch_set_file.times;
end

%% Plot results
subplot_dim = numSubplots(length(all_labels));
figure('units','normalized','outerposition',[0 0 1 1]);

for locindex = 1:length(all_labels)
    plot_data = set_info.data(locindex).epoch;
    subplot(subplot_dim(1), subplot_dim(2), locindex);
    hold on;
    cellfun(@(x) plot(set_info.general.time, x), plot_data);
    plot([0, 0], [min(cellfun(@min, plot_data)), max(cellfun(@max, plot_data))], 'k--');
    plot([min(set_info.general.time), max(set_info.general.time)], [0, 0], 'k--')
    hold off;
    title(all_labels{locindex});
    
    axis tight;
end

sth = suptitle(file_name);
set(sth, 'interpreter', 'none');




















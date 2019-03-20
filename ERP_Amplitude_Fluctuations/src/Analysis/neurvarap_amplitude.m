%%
% Load erp_data.mat file
load([main_path '\FinalData\erp_data.mat'], 'erp_data');

% Select channels and bounds to use to detect amplitudes
% Make subject lists
subject_list = {erp_data.subject};
unique_subject = unique(subject_list);

% Loop through each subject
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
         nplots = numSubplots(length(stim_data.chnames));
         
         % Get block data averaged
         block_data = cellfun(@(x) mean(x,3), {stim_data.epochs}, 'UniformOutput', false);
         
         % Get block data arranged by channel
         block_ch = {stim_data.chnames};
         all_ch = unique([block_ch{:}]);
         
         channel_data = cellfun(@(x) cellfun(@(a, b) a(ismember(b,x),:), ...
                                               block_data, block_ch, 'UniformOutput', false),...
                                  all_ch, 'UniformOutput', false);
         channel_data = cellfun(@(x) vertcat(x{:})', channel_data, 'UniformOutput', false);
         
         % Create some variables
         nplots = numSubplots(length(channel_data)); % subplot dimensions
         t = unique(vertcat(stim_data.times)); % time in x axis
         
         % Plot data and make selection of channels, define provoked
         % potential bounds for all blocks
         selection_notready = 1;
         while selection_notready
              figure('units','normalized','outerposition',[0 0 1 1]);
              
              % Plot data
              for chindex = 1:length(channel_data)
                  subplot(nplots(1), nplots(2), chindex);
                  hold on;
                  plot(t,channel_data{chindex}, 'k');
                  plot([min(t) max(t)], [0 0], 'k--');
                  plot([0 0], [min(min(channel_data{chindex})) max(max(channel_data{chindex}))], 'k--');
                  hold off;
                  
                  if size(channel_data{chindex},2) < 8
                      title(all_ch{chindex}, 'Color', 'r');
                  else
                      title(all_ch{chindex});
                  end
                  axis tight;
              end
              
              suptitle([unique_subject{subjectindex} ' ' unique_sess{sessindex} ' Stim:' num2str(unique_stim(stimindex))]);
              
         end
      end
   end
end

















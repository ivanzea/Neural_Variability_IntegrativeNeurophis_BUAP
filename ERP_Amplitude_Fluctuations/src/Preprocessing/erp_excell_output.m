%% Load erp_data.mat file
[file_name, dir_path] = uigetfile();
load([dir_path file_name]);

%% Select subject
subjexist = 0;
while ~subjexist
    subject_list = unique({amplitude_data.subject});
    disp('Subject List:');
    disp(subject_list');
    subject = input('Select Subject: ', 's');

    if ismember(subject, subject_list)
        subjexist = 1;
    else
        disp('No matching subject');
        disp(' ');
        disp(' ');
    end
end

%% Isolate data and generate excell files
subjdata = amplitude_data(ismember({amplitude_data.subject}, subject));

% Get stim list
stim_list = {subjdata.stimtype};
unique_stim = unique(stim_list);
selpath = uigetdir();

for stimindex = 1:length(unique_stim)
   stimfilter = ismember(stim_list, unique_stim{stimindex});
   stimdata = subjdata(stimfilter);
   
   for dataindex = 1:length(stimdata)
      cdata = stimdata(dataindex);
      blank_col = repmat({' '}, length(cdata.time),1);
      output_cell = [num2cell(cdata.time') blank_col];
      
      for sessionindex = 1:length(cdata.fulldata)
          output_array = horzcat(cdata.fulldata{sessionindex}{:});
          
          filler_col = 10-size(output_array,2);
          output_cell = [output_cell num2cell(output_array) repmat(blank_col,1,filler_col) blank_col];
      end
      
      labeling = {cdata.subject; cdata.stimtype; cdata.ch; 'time [ms]'; 'voltage [uv]'};
      output_cell = [output_cell [labeling; repmat({' '}, length(cdata.time)-length(labeling),1)]];
      
      file = [cdata.subject '_' cdata.stimtype '_' cdata.ch];
      xlswrite([selpath '\' file], output_cell);
   end
end

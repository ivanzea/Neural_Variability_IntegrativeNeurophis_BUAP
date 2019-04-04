plotting = 0;
clc;

[file_name, dir_path] = uigetfile();
load([dir_path file_name]);

%% Raw Data
%% Xi - X max avg amplitude
rdata = {amplitude_data.rawamp};
gdata = {amplitude_data.grps};
jdata = {amplitude_data.jitter};

Subject = {};
Stimulus = {};
Electrode = {};
Pval = {};

subjectlist = {amplitude_data.subject};
uniquesubject = unique(subjectlist);

stimlist = {amplitude_data.stimtype};
uniquestim = unique(stimlist);

sizesub = [length(uniquesubject), length(uniquestim)];
if plotting
    figure('units','normalized','outerposition',[0 0 1 1]);
end

for subjectindex = 1:length(uniquesubject)
    subjectfilter = ismember(subjectlist, uniquesubject{subjectindex});
    
    for stimindex = 1:length(uniquestim)
        stimfilter = ismember(stimlist, uniquestim{stimindex});
        cdata = amplitude_data(stimfilter & subjectfilter);
        
        [~, maxidx] = max(cellfun(@mean, {cdata.rawamp}));
        pdata = cdata(maxidx);
        
        pos = (subjectindex-1)*sizesub(2)+stimindex;
        
        if plotting
            subplot(sizesub(1), sizesub(2),pos);
            hold on;
            scatter(pdata.jitter, pdata.rawamp, 'filled');
            boxplot(pdata.rawamp, pdata.grps);
            hold off;
            
            if pval <= 0.05
                title({[pdata.subject '_' pdata.stimtype '_' pdata.ch], ['pval=' num2str(pdata.pval)]}, ...
                    'interpreter', 'none', 'Color', 'r');
            else
                title({[pdata.subject '_' pdata.stimtype '_' pdata.ch], ['pval=' num2str(pdata.pval)]}, ...
                    'interpreter', 'none');
            end
        end
        
        Subject{pos} = pdata.subject;
        Stimulus{pos} = pdata.stimtype;
        Electrode{pos} = pdata.ch;
        Pval{pos} = pdata.rawpval; 
    end
end

results = table(Subject', Stimulus', Electrode', Pval', 'VariableNames', {'Subject', 'Stimulus', 'Electrode', 'Pval'});
disp('=====================================================================');
disp('WITHIN SESSION VARIATION');
disp('RAW AMPLITUDES');
disp(' ');
disp(results);

%% Xi - X max avg amplitude
rdata = {amplitude_data.rawamp};
gdata = {amplitude_data.grps};
jdata = {amplitude_data.jitter};

Subject = {};
Stimulus = {};
Electrode = {};
Pval = {};

subjectlist = {amplitude_data.subject};
uniquesubject = unique(subjectlist);

stimlist = {amplitude_data.stimtype};
uniquestim = unique(stimlist);

sizesub = [length(uniquesubject), length(uniquestim)];
if plotting
    figure('units','normalized','outerposition',[0 0 1 1]);
end

for subjectindex = 1:length(uniquesubject)
    subjectfilter = ismember(subjectlist, uniquesubject{subjectindex});
    
    for stimindex = 1:length(uniquestim)
        stimfilter = ismember(stimlist, uniquestim{stimindex});
        cdata = amplitude_data(stimfilter & subjectfilter);
        
        [~, maxidx] = max(cellfun(@mean, {cdata.rawamp}));
        pdata = cdata(maxidx);
        
        pos = (subjectindex-1)*sizesub(2)+stimindex;
        
        if plotting
            subplot(sizesub(1), sizesub(2),pos);
            hold on;
            scatter(pdata.jitter, pdata.metric, 'filled');
            boxplot(pdata.metric, pdata.grps);
            hold off;
            
            if pval <= 0.05
                title({[pdata.subject '_' pdata.stimtype '_' pdata.ch], ['pval=' num2str(pdata.pval)]}, ...
                    'interpreter', 'none', 'Color', 'r');
            else
                title({[pdata.subject '_' pdata.stimtype '_' pdata.ch], ['pval=' num2str(pdata.pval)]}, ...
                    'interpreter', 'none');
            end
        end
        
        Subject{pos} = pdata.subject;
        Stimulus{pos} = pdata.stimtype;
        Electrode{pos} = pdata.ch;
        Pval{pos} = pdata.pval; 
    end
end

results = table(Subject', Stimulus', Electrode', Pval', 'VariableNames', {'Subject', 'Stimulus', 'Electrode', 'Pval'});
disp('=====================================================================');
disp('WITHIN SESSION VARIATION');
disp('AMPLITUDE FLUCTUATIONS [Xi - Xu]');
disp(' ');
disp(results);










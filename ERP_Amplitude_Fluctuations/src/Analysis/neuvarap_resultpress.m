function neuvarap_resultpress(plotting)
% How many arguments?
minArgs = 0;
maxArgs = 1;
narginchk(minArgs,maxArgs);

% Set default values
switch nargin
    case 0
        plotting = 0;
end

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
            
            if pdata.pval <= 0.05
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
            
            if pdata.pval <= 0.05
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

%% Amplitude Fluctuations between subjects and stimulus
rdata = {amplitude_data.rawamp};
gdata = {amplitude_data.grps};

subjectlist = {amplitude_data.subject};
uniquesubject = unique(subjectlist);

stimlist = {amplitude_data.stimtype};
uniquestim = unique(stimlist);

data = {};
grp1 = {};
grp2 = {};

for subjectindex = 1:length(uniquesubject)
    subjectfilter = ismember(subjectlist, uniquesubject{subjectindex});
    
    for stimindex = 1:length(uniquestim)
        stimfilter = ismember(stimlist, uniquestim{stimindex});
        cdata = amplitude_data(stimfilter & subjectfilter);
        
        [~, maxidx] = max(cellfun(@mean, {cdata.rawamp}));
        pdata = cdata(maxidx);
        
        pos = (subjectindex-1)*length(uniquestim)+stimindex;
        
        data{pos} = pdata.rawamp;
        grp1{pos} = repmat({pdata.subject},1,length(pdata.rawamp));
        grp2{pos} = repmat({pdata.stimtype},1,length(pdata.rawamp));
    end
end

data = [data{:}];
grp1 = [grp1{:}];
grp2 = [grp2{:}];

[p,~,stats] = anovan(data,{grp1 grp2},'model','interaction','varnames',{'Subject','Stimulus'}, 'display', 'off');

% Between Subjects
compmat = multcompare(stats,'Dimension',1,'display','off');

if plotting
    multcompval = [];
    for i = 1:size(compmat,1)
        multcompval(compmat(i,1), compmat(i,2)) = compmat(i,6);
        multcompval(compmat(i,2), compmat(i,1)) = compmat(i,6);
    end
    
    multcompval(logical(tril(ones(size(multcompval))))) = NaN;
    h = heatmap(stats.grpnames{1},stats.grpnames{1},multcompval);
    
    h.Title = 'BETWEEN SUBJECT TUKEY TEST';
end

tukeyp = table({stats.grpnames{1}{compmat(:,1)}}', ...
    {stats.grpnames{1}{compmat(:,2)}}', ...
    abs(compmat(:,6)));
tukeyp.Properties.VariableNames = {'SubjectA','SubjectB','TukeyPval'};

disp('=====================================================================');
disp('BETWEEN SUBJECTS INTERACTIONS');
disp('AMPLITUDE FLUCTUATIONS [Xi - Xu]');
disp(' ');
disp(tukeyp);

% Between Stimulus
compmat = multcompare(stats,'Dimension',2,'display','off');

if plotting
    multcompval = [];
    for i = 1:size(compmat,1)
        multcompval(compmat(i,1), compmat(i,2)) = compmat(i,6);
        multcompval(compmat(i,2), compmat(i,1)) = compmat(i,6);
    end
    
    multcompval(logical(tril(ones(size(multcompval))))) = NaN;
    h = heatmap(stats.grpnames{1},stats.grpnames{1},multcompval);
    
    h.Title = 'BETWEEN STIMULUS TUKEY TEST';
end

tukeyp = table({stats.grpnames{2}{compmat(:,1)}}', ...
    {stats.grpnames{2}{compmat(:,2)}}', ...
    abs(compmat(:,6)));
tukeyp.Properties.VariableNames = {'StimulusA','StimulusB','TukeyPval'};

disp('=====================================================================');
disp('BETWEEN STIMULUS INTERACTIONS');
disp('AMPLITUDE FLUCTUATIONS [Xi - Xu]');
disp(' ');
disp(tukeyp);













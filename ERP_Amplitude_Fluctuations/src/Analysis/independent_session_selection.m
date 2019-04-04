function independent_output = independent_session_selection(select_epochs, t, ch_name, color_scheme)

% Initialize variables    
allgrps = {};
alljitterX = {};
allraw_amp = {};

% Loop through each session
for sessionindex = 1:length(select_epochs)
    gotonext = 0;
    xclick = [];
    
    y = select_epochs{sessionindex};
    
    while gotonext == 0
        % Plot electrode data
        figure('units', 'normalized', 'outerposition', [0 0 1 1]);
        
        hold on;
        plot(t, y, 'Color', color_scheme{sessionindex}, 'LineWidth', 1.5);
        plot([0 0], [min(y(:)), max(y(:))], '--k', 'LineWidth', 1.5);
        plot([min(t) max(t)], [0 0], '--k', 'LineWidth', 1.5);
        
        if ~isempty(xclick)
            lbh = plot([xclick(1) xclick(1)], [min(y(:)), max(y(:))], 'r--', 'LineWidth', 1.5);
            rbh = plot([xclick(2) xclick(2)], [min(y(:)), max(y(:))], 'r--', 'LineWidth', 1.5);
        end
        
        title([ch_name '- Session ' num2str(sessionindex)]);
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
        y_segment = y(segmentidx,:);
        
        if exist('lbh', 'var')
            lbh.delete;
            rbh.delete;
        end
        
        plot([xclick(2) xclick(2)], [min(min(y)) max(max(y))], 'r--', 'LineWidth', 1.5);
        
        % =========================================================================
        % Step 5: Calculate amplitudes and apply variability metric
        % Find max and min values withing boundaries
        [ampval, ampidx] = max(y_segment);
        maxpoints = [ampval ; ampidx];
        
        [ampval, ampidx] = min(y_segment);
        minpoints = [ampval ; ampidx];
        
        % Make grouping variable for session coloring and processing
        grps = repmat(sessionindex,1,size(y_segment,2));
        allgrps{sessionindex} = grps;
        
        % Make jitter variable for scatter plots
        jitterX = grps+linspace(-0.3,0.3,length(grps));
        alljitterX{sessionindex} = jitterX;
        
        % Show max and min points in graph
        scatter(t(segmentidx(maxpoints(2,:))), maxpoints(1,:), 100, 'g', 'filled');
        scatter(t(segmentidx(minpoints(2,:))), minpoints(1,:), 100, 'r', 'filled');
        hold off;
        
        % Calculate raw amplitudes
        raw_amp = abs(maxpoints(1,:) - minpoints(1,:));
        allraw_amp{sessionindex} = raw_amp;
        
        % Check if we should repeat or not
        while 1
            w = waitforbuttonpress;
            
            if w == 1
                key = get(gcf, 'currentcharacter');
                if key == 27 % Esc key
                    break
                else
                    gotonext = 1;

                    % Clear figures
                    close all;
                    break
                end
            end
        end
    end
end
% Do some calculations
ampmetric = cellfun(@(x) x-mean(x), allraw_amp, 'UniformOutput', false);

% Put all the adequate variables in the output structure
independent_output.time = t;
independent_output.rawamp = [allraw_amp{:}];
independent_output.metric = [ampmetric{:}];
independent_output.grps = [allgrps{:}];
independent_output.jitter = [alljitterX{:}];
independent_output.rawpval = kruskalwallis([allraw_amp{:}], [allgrps{:}], 'off');
independent_output.pval = kruskalwallis([ampmetric{:}], [allgrps{:}], 'off');

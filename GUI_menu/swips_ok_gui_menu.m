classdef swips_ok_gui_menu < handle
    %SWIPS_OK_GUI_MENU Helper class for SWIPS FPGA control GUI menu functionality
    
    properties (Access = private)
        parentInst    % Handle to the parent GUI object
        parentMenu    % Handle to the parent menu object
    end
    
    methods
        function obj = swips_ok_gui_menu(parentInst, parentMenu)
            %SWIPS_OK_GUI_MENU Construct an instance of this class
            obj.parentInst = parentInst;
            obj.parentMenu = parentMenu;

            obj.createMenu();
        end
        
        function hMenu = createMenu(obj)
            % Create SWIPS FPGA Control submenu
            hMenu = uimenu(obj.parentMenu, 'Text', 'SWIPS FPGA Control');

            % Add connection options
            uimenu(hMenu, 'Text', 'Connect FPGA',...
                'MenuSelectedFcn', @(~,~) obj.connectFPGACallback(),...
                'Separator', 'on');

            uimenu(hMenu, 'Text', 'Disconnect FPGA',...
                'MenuSelectedFcn', @(~,~) obj.disconnectFPGACallback());
                
            % Add acquisition settings
            uimenu(hMenu, 'Text', 'Set Acquisition Time',...
                'MenuSelectedFcn', @(~,~) obj.setAcqTimeCallback(),...
                'Separator', 'on');
            uimenu(hMenu, 'Text', 'Set DAQ Thresholds',...
                'MenuSelectedFcn', @(~,~) obj.setDaqThresholdsCallback());
            
            % Add pulser control
            uimenu(hMenu, 'Text', 'Pulser Control',...
                'MenuSelectedFcn', @(~,~) obj.pulserControlCallback(),...
                'Separator', 'on');
            
                % collect pulse height distribition
            uimenu(hMenu, 'Text', 'Collect Pulse Height Distribution',...
                'MenuSelectedFcn', @(~,~) obj.callPHD());

            uimenu(hMenu, 'Text', 'Connect Pulse Height',...
                'MenuSelectedFcn', @(~,~) obj.connectPHCallback());

            end
        
        function connectFPGACallback(obj)
            % Connect to SWIPS FPGA
            try
                obj.parentInst.connectDevice();
                if obj.parentInst.Connected
                    msgbox('Successfully connected to SWIPS FPGA', 'Success');
                else
                    errordlg('Failed to connect to SWIPS FPGA', 'Error');
                end
            catch ME
                errordlg(['Error connecting to SWIPS FPGA: ' ME.message], 'Error');
            end
        end
        
        function disconnectFPGACallback(obj)
            % Confirm disconnect
            choice = questdlg('Are you sure you want to disconnect the SWIPS FPGA?', ...
                'Disconnect FPGA', ...
                'Yes', 'No', 'No');
            
            if strcmp(choice, 'Yes')
                try
                    obj.parentInst.close();
                    msgbox('FPGA successfully disconnected', 'Success');
                catch ME
                    errordlg(['Error disconnecting FPGA: ' ME.message], 'Error');
                end
            end
        end

        function callPHD(obj)
            % Create figure for pulse height distribution collection inputs
            fig = figure('Name', 'Pulse Height Distribution', ...
                'NumberTitle', 'off', ...
                'Position', [300 300 420 230], ...
                'MenuBar', 'none', ...
                'ToolBar', 'none');
            
            % Create UI elements
            uicontrol('Style', 'text', ...
                'Position', [10 270 270 30], ...
                'String', 'Collect a Pulse Height Distribution', ...
                'FontSize', 12);
            
            % Create array to store edit boxes
            edit_boxes = zeros(1, 6);

            % --- Row 1: acquisition settings ---
            uicontrol('Style', 'text', ...
                'Position', [5 170 130 40], ...
                'String', 'Number of Samples', 'FontSize', 11);
            edit_boxes(1) = uicontrol('Style', 'edit', ...
                'Position', [35 148 70 25], ...
                'String', num2str(1000), 'FontSize', 10);

            uicontrol('Style', 'text', ...
                'Position', [145 170 120 40], ...
                'String', 'Dwell time (ms)', 'FontSize', 11);
            edit_boxes(2) = uicontrol('Style', 'edit', ...
                'Position', [170 148 70 25], ...
                'String', num2str(1), 'FontSize', 10);

            uicontrol('Style', 'text', ...
                'Position', [285 175 130 30], ...
                'String', 'PH Threshold', 'FontSize', 11);
            edit_boxes(3) = uicontrol('Style', 'edit', ...
                'Position', [305 148 70 25], ...
                'String', num2str(200), 'FontSize', 10);

            % --- Row 2: histogram settings ---
            uicontrol('Style', 'text', ...
                'Position', [5 105 130 40], ...
                'String', 'Hist Min', 'FontSize', 11);
            edit_boxes(4) = uicontrol('Style', 'edit', ...
                'Position', [35 83 70 25], ...
                'String', num2str(200), 'FontSize', 10);

            uicontrol('Style', 'text', ...
                'Position', [145 105 120 40], ...
                'String', 'Hist Max', 'FontSize', 11);
            edit_boxes(5) = uicontrol('Style', 'edit', ...
                'Position', [170 83 70 25], ...
                'String', num2str(15000), 'FontSize', 10);

            uicontrol('Style', 'text', ...
                'Position', [285 105 130 40], ...
                'String', 'Bin Width', 'FontSize', 11);
            edit_boxes(6) = uicontrol('Style', 'edit', ...
                'Position', [305 83 70 25], ...
                'String', num2str(20), 'FontSize', 10);

            % Create buttons
            uicontrol('Style', 'pushbutton', ...
                'Position', [60 15 130 35], ...
                'String', 'Collect', ...
                'Callback', @applyCallback);
            
            uicontrol('Style', 'pushbutton', ...
                'Position', [230 15 130 35], ...
                'String', 'Cancel', ...
                'Callback', @(~,~) delete(fig));
            function setfield_abort(Nsamples)
                obj.parentInst.PHInd = Nsamples;
            end
            function applyCallback(~, ~)
                try
                    

                    % Get values from edit boxes
                    valSample = str2double(get(edit_boxes(1), 'String'));
                    
                    % Validate input
                    if isnan(valSample) || valSample < 0 || valSample > 10000001 || mod(valSample, 1) ~= 0
                        errordlg('Invalid number of samples for pulse height distribution %d. Must be an integer between zero and ten million.', 'Error');
                        return;
                    end
                    Nsamples = valSample;

                    % Get values from edit boxes
                    valDwell = str2double(get(edit_boxes(2), 'String'));
                    
                    % Validate input
                    if isnan(valDwell) || valDwell < 0 || valDwell > 100 || mod(valDwell, 1) ~= 0
                        errordlg('Invalid dwell time %d. Must be an integer between 0-100.', 'Error');
                        return;
                    end
                    dwell = valDwell;

                    % Get PH Threshold
                    valThreshold = str2double(get(edit_boxes(3), 'String'));
                    if isnan(valThreshold) || valThreshold < 0 || valThreshold > 65535 || mod(valThreshold, 1) ~= 0
                        errordlg('Invalid PH Threshold. Must be an integer between 0 and 65535.', 'Error');
                        return;
                    end
                    PHThreshold = valThreshold;

                    % Get histogram settings
                    valMin = str2double(get(edit_boxes(4), 'String'));
                    if isnan(valMin) || valMin < 0
                        errordlg('Invalid Hist Min. Must be a non-negative number.', 'Error');
                        return;
                    end
                    histMin = valMin;

                    valMax = str2double(get(edit_boxes(5), 'String'));
                    if isnan(valMax) || valMax <= histMin
                        errordlg('Invalid Hist Max. Must be greater than Hist Min.', 'Error');
                        return;
                    end
                    histMax = valMax;

                    valStep = str2double(get(edit_boxes(6), 'String'));
                    if isnan(valStep) || valStep <= 0
                        errordlg('Invalid Bin Width. Must be a positive number.', 'Error');
                        return;
                    end
                    histStep = valStep;

                    % Close dialog
                    delete(fig);
                    % Show status while collecting
                    statusFig = figure('Name', 'Please Wait', ...
                        'NumberTitle', 'off', ...
                        'Position', [400 400 380 160], ...
                        'MenuBar', 'none', ...
                        'ToolBar', 'none', ...
                        'Resize', 'off');
                    uicontrol('Parent', statusFig, 'Style', 'text', ...
                        'Units', 'normalized', ...
                        'Position', [0.05 0.72 0.9 0.22], ...
                        'String', 'Collecting Pulse Height Distribution...', ...
                        'FontSize', 10);
                    progAx = axes('Parent', statusFig, ...
                        'Units', 'normalized', ...
                        'Position', [0.05 0.42 0.9 0.22], ...
                        'XLim', [0 1], 'YLim', [0 1], ...
                        'XTick', [], 'YTick', [], 'Box', 'on');
                    progPatch = patch(progAx, [0 0 0 0], [0 1 1 0], [0.2 0.6 1.0]);
                    countText = uicontrol('Parent', statusFig, 'Style', 'text', ...
                        'Units', 'normalized', ...
                        'Position', [0.3 0.22 0.4 0.16], ...
                        'String', sprintf('0 / %d', Nsamples), ...
                        'FontSize', 10);
                    uicontrol('Parent', statusFig, 'Style', 'pushbutton', ...
                        'Units', 'normalized', ...
                        'Position', [0.2 0.04 0.6 0.15], ...
                        'String', 'Abort Collection', ...
                        'ForegroundColor', [0.8 0 0], ...
                        'FontSize', 10, ...
                        'Callback', @(~,~) setfield_abort(Nsamples));
                    drawnow;

                    % Listener on PHInd to update progress bar on every set
                    progListener = addlistener(obj.parentInst, 'PHInd', 'PostSet', ...
                        @(~,~) obj.updatePHDProgress(progPatch, countText, Nsamples));

                    % Collect a PHD with Nsamples
                    obj.parentInst.getPHD(Nsamples, dwell, PHThreshold, histMin, histMax, histStep);

                    % Remove listener and clear status
                    delete(progListener);
                    delete(statusFig);
                    successFig = figure('Name', 'Success', ...
                        'NumberTitle', 'off', ...
                        'Position', [400 400 360 100], ...
                        'MenuBar', 'none', ...
                        'ToolBar', 'none', ...
                        'Resize', 'off');
                    uicontrol('Parent', successFig, 'Style', 'text', ...
                        'Units', 'normalized', ...
                        'Position', [0.05 0.5 0.9 0.4], ...
                        'String', 'Pulse height distribution collected successfully.', ...
                        'FontSize', 10);
                    uicontrol('Parent', successFig, 'Style', 'pushbutton', ...
                        'Units', 'normalized', ...
                        'Position', [0.05 0.08 0.42 0.35], ...
                        'String', 'Save Data to File...', ...
                        'Callback', @(~,~) obj.savePHDToFile());
                    uicontrol('Parent', successFig, 'Style', 'pushbutton', ...
                        'Units', 'normalized', ...
                        'Position', [0.53 0.08 0.42 0.35], ...
                        'String', 'OK', ...
                        'Callback', @(~,~) delete(successFig));

                    % Plot Pulse Height Distribution in a new window
                    f = figure('Name','Pulse Height Distribution',...
                            'NumberTitle','off',...
                            'Color','w');

                    tg = uitabgroup('Parent', f);
                    for i = 1:16
                        tab = uitab('Parent', tg, 'Title', sprintf('Anode %d', i-1));
                        ax = axes('Parent', tab);
                        histogram(ax, 'BinEdges', obj.parentInst.pulseHeightEdges, ...
                            'BinCounts', obj.parentInst.pulseHeightData(:, i+1));
                        xlabel(ax, 'Pulse Amplitude [arb.]');
                        ylabel(ax, 'Counts');
                        title(ax, sprintf('Anode %d', i-1));
                    end

                    obj.parentInst.PHInd = 0;

                catch ME
                    errordlg(['Error collecting pulse height distribution: ' ME.message], 'Error');
                end
            end
        end

        function connectPHCallback(obj)
            % Single-window PH collection: controls on the left, live histogram tabs on the right.

            hFig = figure('Name', 'Connect Pulse Height', ...
                'NumberTitle', 'off', ...
                'Position', [100 100 1100 600], ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'Color', 'w', ...
                'CloseRequestFcn', @onClose);

            %% ---- Left panel: inputs & controls ----
            leftW = 0.22;

            lpanel = uipanel('Parent', hFig, 'Title', 'Settings', ...
                'Units', 'normalized', 'Position', [0 0 leftW 1], ...
                'FontSize', 11);

            ypos = 0.92; dy = 0.065; lblH = 0.04; edH = 0.045;

            uicontrol('Parent', lpanel, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.05 ypos 0.9 lblH], 'String', 'Dwell time (ms)', ...
                'FontSize', 10, 'HorizontalAlignment', 'left');
            ypos = ypos - edH;
            eb_dwell = uicontrol('Parent', lpanel, 'Style', 'edit', 'Units', 'normalized', ...
                'Position', [0.05 ypos 0.9 edH], 'String', num2str(obj.parentInst.PH_dwellTime), 'FontSize', 10);

            ypos = ypos - dy;
            uicontrol('Parent', lpanel, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.05 ypos 0.9 lblH], 'String', 'PH Threshold', ...
                'FontSize', 10, 'HorizontalAlignment', 'left');
            ypos = ypos - edH;
            eb_thr = uicontrol('Parent', lpanel, 'Style', 'edit', 'Units', 'normalized', ...
                'Position', [0.05 ypos 0.9 edH], 'String', num2str(obj.parentInst.PH_threshold), 'FontSize', 10);

            ypos = ypos - dy;
            uicontrol('Parent', lpanel, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.05 ypos 0.9 lblH], 'String', 'N Samples', ...
                'FontSize', 10, 'HorizontalAlignment', 'left');
            ypos = ypos - edH;
            eb_nsamp = uicontrol('Parent', lpanel, 'Style', 'edit', 'Units', 'normalized', ...
                'Position', [0.05 ypos 0.9 edH], 'String', num2str(obj.parentInst.PH_Nsamples), 'FontSize', 10);

            ypos = ypos - dy;
            uicontrol('Parent', lpanel, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.05 ypos 0.9 lblH], 'String', 'Hist Min', ...
                'FontSize', 10, 'HorizontalAlignment', 'left');
            ypos = ypos - edH;
            eb_min = uicontrol('Parent', lpanel, 'Style', 'edit', 'Units', 'normalized', ...
                'Position', [0.05 ypos 0.9 edH], 'String', '200', 'FontSize', 10);

            ypos = ypos - dy;
            uicontrol('Parent', lpanel, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.05 ypos 0.9 lblH], 'String', 'Hist Max', ...
                'FontSize', 10, 'HorizontalAlignment', 'left');
            ypos = ypos - edH;
            eb_max = uicontrol('Parent', lpanel, 'Style', 'edit', 'Units', 'normalized', ...
                'Position', [0.05 ypos 0.9 edH], 'String', '15000', 'FontSize', 10);

            ypos = ypos - dy;
            uicontrol('Parent', lpanel, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.05 ypos 0.9 lblH], 'String', 'Bin Width', ...
                'FontSize', 10, 'HorizontalAlignment', 'left');
            ypos = ypos - edH;
            eb_step = uicontrol('Parent', lpanel, 'Style', 'edit', 'Units', 'normalized', ...
                'Position', [0.05 ypos 0.9 edH], 'String', '20', 'FontSize', 10);

            btnH = 0.055; btnGap = 0.015;
            ypos = ypos - dy;
            hConnectBtn = uicontrol('Parent', lpanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
                'Position', [0.05 ypos 0.9 btnH], 'String', 'Connect', ...
                'FontSize', 10, 'BackgroundColor', [0.3 0.75 0.3], ...
                'Callback', @connectCB);

            ypos = ypos - btnH - btnGap;
            uicontrol('Parent', lpanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
                'Position', [0.05 ypos 0.9 btnH], 'String', 'Disconnect', ...
                'FontSize', 10, 'ForegroundColor', [0.8 0 0], ...
                'Callback', @disconnectCB);

            ypos = ypos - btnH - btnGap;
            uicontrol('Parent', lpanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
                'Position', [0.05 ypos 0.9 btnH], 'String', 'Clear Data', ...
                'FontSize', 10, ...
                'Callback', @(~,~) clearAccum());

            %% ---- Right panel: histogram tabs ----
            histMin  = 200;
            histMax  = 15000;
            histStep = 20;
            edges    = histMin : histStep : histMax;
            nBins    = numel(edges) - 1;
            centers  = edges(1:nBins) + histStep/2;
            accumData = zeros(nBins, 16);

            tg = uitabgroup('Parent', hFig, 'Units', 'normalized', ...
                'Position', [leftW 0 1-leftW 1]);
            ax    = gobjects(1, 16);
            bar_h = gobjects(1, 16);
            buildTabs();

            phListener = [];
            drawnow;

            %% ---- Nested helpers ----
            function buildTabs()
                delete(tg.Children);
                ax    = gobjects(1, 16);
                bar_h = gobjects(1, 16);
                for i = 1:16
                    tab      = uitab('Parent', tg, 'Title', sprintf('Anode %d', i-1));
                    ax(i)    = axes('Parent', tab); %#ok<LAXES>
                    bar_h(i) = bar(ax(i), centers, zeros(1, nBins), 1, 'FaceColor', [0.2 0.5 0.9]);
                    xlabel(ax(i), 'Pulse Amplitude [arb.]');
                    ylabel(ax(i), 'Counts (accumulated)');
                    title(ax(i),  sprintf('Anode %d', i-1));
                end
            end

            function connectCB(~,~)
                dwell   = str2double(get(eb_dwell,  'String'));
                thr     = str2double(get(eb_thr,    'String'));
                nsamp   = str2double(get(eb_nsamp,  'String'));
                hMin    = str2double(get(eb_min,    'String'));
                hMax    = str2double(get(eb_max,    'String'));
                step    = str2double(get(eb_step,   'String'));

                if isnan(dwell) || dwell < 0 || dwell > 100 || mod(dwell,1)~=0
                    errordlg('Dwell time must be an integer 0-100 ms.', 'Error'); return;
                end
                if isnan(thr) || thr < 0 || thr > 65535 || mod(thr,1)~=0
                    errordlg('PH Threshold must be an integer 0-65535.', 'Error'); return;
                end
                if isnan(nsamp) || nsamp < 1 || mod(nsamp,1)~=0
                    errordlg('N Samples must be a positive integer.', 'Error'); return;
                end
                if isnan(hMin) || hMin < 0
                    errordlg('Hist Min must be a non-negative number.', 'Error'); return;
                end
                if isnan(hMax) || hMax <= hMin
                    errordlg('Hist Max must be greater than Hist Min.', 'Error'); return;
                end
                if isnan(step) || step <= 0
                    errordlg('Bin Width must be a positive number.', 'Error'); return;
                end

                obj.parentInst.PH_dwellTime = dwell;
                obj.parentInst.PH_threshold = thr;
                obj.parentInst.PH_Nsamples  = nsamp;

                % Rebuild histogram if parameters changed
                histMin  = hMin;
                histMax  = hMax;
                histStep = step;
                edges    = histMin : histStep : histMax;
                nBins    = numel(edges) - 1;
                centers  = edges(1:nBins) + histStep/2;
                accumData = zeros(nBins, 16);
                buildTabs();

                set(hConnectBtn, 'Enable', 'off');

                delete(phListener);
                phListener = addlistener(obj.parentInst, 'PH_reading', 'PostSet', ...
                    @(~,~) onBatchComplete());

                obj.parentInst.connectPH();

                if isvalid(hConnectBtn)
                    set(hConnectBtn, 'Enable', 'on');
                end
            end

            function disconnectCB(~,~)
                obj.parentInst.disconnectPH();
                delete(phListener);
                phListener = [];
                if isvalid(hConnectBtn)
                    set(hConnectBtn, 'Enable', 'on');
                end
            end

            function onBatchComplete()
                if obj.parentInst.PH_reading || ~isvalid(hFig)
                    return;
                end
                [newData, ~] = obj.parentInst.binPHD(histMin, histMax, histStep);
                if isempty(newData); return; end
                accumData = accumData + newData(:, 2:end);
                for k = 1:16
                    if isvalid(bar_h(k))
                        set(bar_h(k), 'YData', accumData(:, k)');
                    end
                end
                drawnow limitrate;
            end

            function clearAccum()
                accumData = zeros(nBins, 16);
                for k = 1:16
                    if isvalid(bar_h(k))
                        set(bar_h(k), 'YData', zeros(1, nBins));
                    end
                end
                drawnow;
            end

            function onClose(~,~)
                obj.parentInst.disconnectPH();
                delete(phListener);
                delete(hFig);
            end
        end

        function updatePHDProgress(obj, progPatch, countText, Nsamples)
            % Update progress bar patch and counter label from current PHInd
            if isvalid(progPatch)
                frac = min(obj.parentInst.PHInd / Nsamples, 1);
                set(progPatch, 'XData', [0 frac frac 0]);
                set(countText, 'String', sprintf('%d / %d', obj.parentInst.PHInd, Nsamples));
            end
        end

        function savePHDToFile(obj)
            % Prompt user for save path and write pulse height data to CSV
            [fname, fpath] = uiputfile({'*.csv','CSV Files (*.csv)'; '*.*','All Files'}, ...
                'Save Pulse Height Distribution', 'pulseHeightData.csv');
            if isequal(fname, 0)
                return;  % User cancelled
            end

            try
                header = {'Bin Center', 'Anode 0', 'Anode 1', 'Anode 2', 'Anode 3', ...
                          'Anode 4', 'Anode 5', 'Anode 6', 'Anode 7', 'Anode 8', ...
                          'Anode 9', 'Anode 10', 'Anode 11', 'Anode 12', 'Anode 13', ...
                          'Anode 14', 'Anode 15'};
                t = array2table(obj.parentInst.pulseHeightData, 'VariableNames', header);
                writetable(t, fullfile(fpath, fname), 'WriteMode', 'overwrite');
                msgbox(sprintf('Data saved to %s', fullfile(fpath, fname)), 'Saved');
            catch ME
                errordlg(['Error saving data: ' ME.message], 'Error');
            end
        end

        function setAcqTimeCallback(obj)
            % Create dialog for acquisition time selection
            choice = questdlg('Select Acquisition Time:', ...
                'Set Acquisition Time', ...
                '1 second','10 seconds','1 second');
            
            % Handle response
            if ~isempty(choice)
                try
                    if strcmp(choice, '1 second')
                        obj.parentInst.acq_time = 0;
                    else  % 10 seconds
                        obj.parentInst.acq_time = 1;
                    end
                    obj.parentInst.configurePPA_ok(); % Apply the new setting
                catch ME
                    errordlg(['Error setting acquisition time: ' ME.message], 'Error');
                end
            end
        end
        
        function setDaqThresholdsCallback(obj)
            % Create figure for threshold inputs
            fig = figure('Name', 'Set DAQ Thresholds', ...
                'NumberTitle', 'off', ...
                'Position', [300 300 400 500], ...
                'MenuBar', 'none', ...
                'ToolBar', 'none');
            
            % Get current thresholds or use defaults
            if ~isempty(obj.parentInst.dac_table)
                current_thresholds = obj.parentInst.dac_table;
            else
                current_thresholds = zeros(1, 16);
            end
            
            % Create UI elements
            uicontrol('Style', 'text', ...
                'Position', [10 460 380 30], ...
                'String', 'Enter DAQ Thresholds (0-255):', ...
                'FontSize', 12);
            
            % Create array to store edit boxes
            edit_boxes = zeros(1, 16);
            
            % Create edit boxes in a 4x4 grid
            for i = 1:16
                row = floor((i-1)/4);
                col = mod(i-1, 4);
                
                % Create label
                uicontrol('Style', 'text', ...
                    'Position', [20+col*95 400-row*80 80 20], ...
                    'String', sprintf('DAQ %d:', i));
                
                % Create edit box
                edit_boxes(i) = uicontrol('Style', 'edit', ...
                    'Position', [20+col*95 370-row*80 80 30], ...
                    'String', num2str(current_thresholds(i)), ...
                    'FontSize', 10);
            end
            
            % Create buttons
            uicontrol('Style', 'pushbutton', ...
                'Position', [80 50 100 40], ...
                'String', 'Apply', ...
                'Callback', @applyCallback);
            
            uicontrol('Style', 'pushbutton', ...
                'Position', [220 50 100 40], ...
                'String', 'Cancel', ...
                'Callback', @(~,~) delete(fig));
            
            function applyCallback(~, ~)
                try
                    % Get values from edit boxes
                    new_thresholds = zeros(1, 16);
                    for j = 1:16
                        val = str2double(get(edit_boxes(j), 'String'));
                        
                        % Validate input
                        if isnan(val) || val < 0 || val > 255 || mod(val, 1) ~= 0
                            errordlg(sprintf('Invalid value for DAQ %d. Must be integer between 0-255.', j), 'Error');
                            return;
                        end
                        new_thresholds(j) = val;
                    end
                    
                    % Update DAQ table and configure
                    obj.parentInst.dac_table = new_thresholds;
                    obj.parentInst.configurePPA_ok();
                    
                    % Close dialog
                    delete(fig);
                    msgbox('DAQ thresholds updated successfully', 'Success');
                catch ME
                    errordlg(['Error setting DAQ thresholds: ' ME.message], 'Error');
                end
            end
        end
        
        function pulserControlCallback(obj)
            % Create figure for pulser control
            fig = figure('Name', 'Pulser Control', ...
                'NumberTitle', 'off', ...
                'Position', [300 300 400 400], ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'Resize', 'off');
            
            % Title
            uicontrol('Style', 'text', ...
                'Position', [10 360 380 30], ...
                'String', 'SWIPS Pulser Control', ...
                'FontSize', 14, ...
                'FontWeight', 'bold');
            
            % Even Pulser Enable
            uicontrol('Style', 'text', ...
                'Position', [30 310 150 25], ...
                'String', 'Even Pulser Enable:', ...
                'HorizontalAlignment', 'left', ...
                'FontSize', 10);
            evenPulserRadio = uicontrol('Style', 'radiobutton', ...
                'Position', [200 310 150 25], ...
                'String', 'Enable', ...
                'Value', 0);
            
            % Odd Pulser Enable
            uicontrol('Style', 'text', ...
                'Position', [30 270 150 25], ...
                'String', 'Odd Pulser Enable:', ...
                'HorizontalAlignment', 'left', ...
                'FontSize', 10);
            oddPulserRadio = uicontrol('Style', 'radiobutton', ...
                'Position', [200 270 150 25], ...
                'String', 'Enable', ...
                'Value', 0);
            
            % External Pulser Enable
            uicontrol('Style', 'text', ...
                'Position', [30 230 150 25], ...
                'String', 'External Pulser Enable:', ...
                'HorizontalAlignment', 'left', ...
                'FontSize', 10);
            extPulserPopup = uicontrol('Style', 'popupmenu', ...
                'Position', [200 230 150 25], ...
                'String', {'Disabled (0)', 'Enabled (1)'}, ...
                'Value', 1);
            
            % Pulser Output Selection
            uicontrol('Style', 'text', ...
                'Position', [30 190 150 25], ...
                'String', 'Output Selection:', ...
                'HorizontalAlignment', 'left', ...
                'FontSize', 10);
            outputPopup = uicontrol('Style', 'popupmenu', ...
                'Position', [200 190 150 25], ...
                'String', {'0: SSD 0/1', '1: SSD 2/3', '2: SSD 4/5', '3: SSD 6/7', ...
                           '4: SSD 8/9', '5: SSD 10/11', '6: SSD 12/13', '7: SSD 14/15'}, ...
                'Value', 1);
            
            % Pulser Frequency
            uicontrol('Style', 'text', ...
                'Position', [30 150 150 25], ...
                'String', 'Frequency:', ...
                'HorizontalAlignment', 'left', ...
                'FontSize', 10);
            freqPopup = uicontrol('Style', 'popupmenu', ...
                'Position', [200 150 150 25], ...
                'String', {'0: 10 Hz', '1: 100 Hz', '2: 1 kHz', '3: 10 kHz', '4: 100 kHz'}, ...
                'Value', 1);
            
            % Separator line
            uicontrol('Style', 'text', ...
                'Position', [10 110 380 2], ...
                'BackgroundColor', [0.5 0.5 0.5]);
            
            % Apply All button
            uicontrol('Style', 'pushbutton', ...
                'Position', [50 50 120 40], ...
                'String', 'Apply All', ...
                'FontSize', 11, ...
                'Callback', @applyAllCallback);
            
            % Close button
            uicontrol('Style', 'pushbutton', ...
                'Position', [230 50 120 40], ...
                'String', 'Close', ...
                'FontSize', 11, ...
                'Callback', @(~,~) delete(fig));
            
            function applyAllCallback(~, ~)
                try
                    if ~obj.parentInst.Connected
                        errordlg('FPGA not connected. Please connect before configuring pulser.', 'Error');
                        return;
                    end
                    
                    % Get values (radio buttons are 0 or 1, popup value - 1 gives 0 or 1)
                    evenEnable = get(evenPulserRadio, 'Value');
                    oddEnable = get(oddPulserRadio, 'Value');
                    extEnable = get(extPulserPopup, 'Value') - 1;
                    outputSel = get(outputPopup, 'Value') - 1;
                    freqSel = get(freqPopup, 'Value') - 1;
                    
                    % Apply settings
                    obj.parentInst.evenPulserEnable(evenEnable);
                    obj.parentInst.oddPulserEnable(oddEnable);
                    obj.parentInst.externalPulserEnable(extEnable);
                    obj.parentInst.pulserOutputSelection(outputSel);
                    obj.parentInst.pulserFrequency(freqSel);
                    
                    msgbox('Pulser settings applied successfully', 'Success');
                catch ME
                    errordlg(['Error applying pulser settings: ' ME.message], 'Error');
                end
            end
        end
    end
end
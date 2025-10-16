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
    end
end
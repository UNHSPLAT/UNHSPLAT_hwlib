classdef newport_gui_menu < handle
    %NEWPORT_GUI_MENU Helper class for Newport Stage control GUI menu functionality
    
    properties (Access = private)
        parentInst    % Handle to the parent GUI object
        parentMenu    % Handle to the parent menu object
        groups = []   % Array of stage group names
    end
    
    methods
        function obj = newport_gui_menu(parentInst, parentMenu, groups,~,~)
            %NEWPORT_GUI_MENU Construct an instance of this class
            obj.parentInst = parentInst;
            obj.parentMenu = parentMenu;
            
            % Set default groups if not provided
            if nargin < 3 || isempty(groups)
                obj.groups = ["Group1", "Group2", "Group3"];
            else
                obj.groups = groups;
            end

            obj.createMenu();
        end
        
        function hMenu = createMenu(obj)
            % Create Newport Stage Control submenu
            hMenu = uimenu(obj.parentMenu, 'Text', 'Newport Stage Control');

            % Add initialization and home options
            uimenu(hMenu, 'Text', 'Connect Stage',...
                'MenuSelectedFcn', @(~,~) obj.connectStageCallback(),...
                'Separator', 'on');
            uimenu(hMenu, 'Text', 'Disconnect Stage',...
                'MenuSelectedFcn', @(~,~) obj.disconnectStageCallback());
            uimenu(hMenu, 'Text', 'Initialize Stage',...
                'MenuSelectedFcn', @(~,~) obj.initStageCallback());
            uimenu(hMenu, 'Text', 'Configure Stage',...
                'MenuSelectedFcn', @(~,~) obj.parentInst.funcConfig(obj.parentInst));
            uimenu(hMenu, 'Text', 'Home Stage',...
                'MenuSelectedFcn', @(~,~) obj.homeStageCallback());
            
            % Add group-specific controls
            for i = 1:length(obj.groups)
                groupName = obj.groups(i);
                % Add separator before first group
                if i == 1
                    submenu = uimenu(hMenu, 'Text', sprintf('Group: %s', groupName),...
                        'Separator', 'on');
                else
                    submenu = uimenu(hMenu, 'Text', sprintf('Group: %s', groupName));
                end
                
                % Add zero position option for each group
                uimenu(submenu, 'Text', 'Zero Position',...
                    'MenuSelectedFcn', @(~,~) obj.zeroGroupCallback(groupName));
            end
        end
        
        function connectStageCallback(obj)
            % Connect to Newport stage
            try
                obj.parentInst.connectDevice();
                if obj.parentInst.Connected
                    msgbox('Successfully connected to Newport Stage', 'Success');
                else
                    errordlg('Failed to connect to Newport Stage', 'Error');
                end
            catch ME
                errordlg(['Error connecting to Newport Stage: ' ME.message], 'Error');
            end
        end
        
        function disconnectStageCallback(obj)
            % Confirm disconnect
            choice = questdlg('Are you sure you want to disconnect the Newport Stage?', ...
                'Disconnect Stage', ...
                'Yes', 'No', 'No');
            
            if strcmp(choice, 'Yes')
                try
                    obj.parentInst.shutdown();
                    msgbox('Stage successfully disconnected', 'Success');
                catch ME
                    errordlg(['Error disconnecting stage: ' ME.message], 'Error');
                end
            end
        end
        
        function initStageCallback(obj)
            % Get Newport hardware
            newport = obj.parentInst;
            
            if ~newport.Connected
                errordlg('Newport Stage not connected. Please connect first.', 'Error');
                return;
            end
            
            try
                newport.initDevice();
                if all(newport.group_status)
                    msgbox('Successfully initialized all stage groups', 'Success');
                else
                    warndlg('Some groups failed to initialize. Check group status.', 'Warning');
                end
            catch ME
                errordlg(['Error initializing Newport Stage: ' ME.message], 'Error');
            end
        end
        
        function homeStageCallback(obj)
            % Get Newport hardware
            newport = obj.parentInst;
            
            if ~newport.Connected
                errordlg('Newport Stage not connected. Please connect first.', 'Error');
                return;
            end
            
            % Confirm homing operation with user
            choice = questdlg('Are you sure you want to home all stage groups?', ...
                'Home Stage', ...
                'Yes', 'No', 'No');
            
            if strcmp(choice, 'Yes')
                try
                    newport.home();
                    msgbox('Home operation completed', 'Success');
                catch ME
                    errordlg(['Error homing Newport Stage: ' ME.message], 'Error');
                end
            end
        end
        
        function zeroGroupCallback(obj, groupName)
            % Get Newport hardware
            newport = obj.parentInst;
            
            if ~newport.Connected
                errordlg('Newport Stage not connected. Please connect first.', 'Error');
                return;
            end
            
            % Find group index
            groupIdx = find(newport.groups == groupName, 1);
            if isempty(groupIdx)
                errordlg(['Group ' char(groupName) ' not found'], 'Error');
                return;
            end
            
            % Check if group is initialized
            if ~newport.group_status(groupIdx)
                errordlg(['Group ' char(groupName) ' not initialized'], 'Error');
                return;
            end
            
            % Confirm zero operation with user
            choice = questdlg(['Are you sure you want to zero position for ' char(groupName) '?'], ...
                'Zero Position', ...
                'Yes', 'No', 'No');
            
            if strcmp(choice, 'Yes')
                try
                    newport.setPosition(groupName, 0);
                    msgbox(['Zero position set for ' char(groupName)], 'Success');
                catch ME
                    errordlg(['Error setting zero position: ' ME.message], 'Error');
                end
            end
        end
    end
end
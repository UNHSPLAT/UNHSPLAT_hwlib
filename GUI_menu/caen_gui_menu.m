classdef caen_gui_menu < handle
    %CAEN_GUI_MENU Helper class for CAEN HV control GUI menu functionality
    
    properties (Access = private)
        parentInst    % Handle to the parent GUI object
        parentMenu    % Handle to the parent menu object
        channelLabels = [] % Map of channel names to user-friendly labels
        useChannels = []    % Array of channels to be used
    end
    
    methods
        function obj = caen_gui_menu(parentInst, parentMenu, useChannels,channelLabels,~,~)
            %CAEN_GUI_MENU Construct an instance of this class
            obj.parentInst = parentInst;
            obj.parentMenu = parentMenu;
            % Set default channel labels if not provided
            if nargin < 3 || isempty(useChannels)
                obj.useChannels = [0, 1, 2, 3];
            else
                obj.useChannels = useChannels;
            end
            % Set default channel labels if not provided
            if nargin < 4 || isempty(channelLabels)
                obj.channelLabels = ["voltCh0", "voltCh1", "voltCh2", "voltCh3"];
            else
                obj.channelLabels = channelLabels;
            end

            obj.createMenu();
        end
        
        function hMenu = createMenu(obj)
            % Create CAEN HV Control submenu
            hMenu = uimenu(obj.parentMenu, 'Text', 'CAEN HV Control');

            % Add Enable/Disable All options
            uimenu(hMenu, 'Text', 'Enable All',...
                'MenuSelectedFcn', @(~,~) obj.HVenableAllCallback(true),...
                'Separator', 'on');
            uimenu(hMenu, 'Text', 'Disable All',...
                'MenuSelectedFcn', @(~,~) obj.HVenableAllCallback(false));

            % Add menu items for each enabled HV channel
            firstChannel = true;
            for i = 1:length(obj.useChannels)
                chan = obj.useChannels(i);
                channelLabel = obj.channelLabels(i);
                
                % Add separator before first channel
                if firstChannel
                    uimenu(hMenu, 'Text', sprintf('Ch%d:%s', chan, channelLabel),...
                        'MenuSelectedFcn', @(~,~) obj.HVenableCallback(channelLabel, chan),...
                        'Separator', 'on');
                    firstChannel = false;
                else
                    uimenu(hMenu, 'Text', sprintf('Ch%d:%s', chan, channelLabel),...
                        'MenuSelectedFcn', @(~,~) obj.HVenableCallback(channelLabel, chan));
                end
            end
        end
        
        function HVenableCallback(obj, channelLabel, chan)

            caen = obj.parentInst;
            
            % Check hardware connection
            if ~caen.Connected
                try
                    caen.connectDevice();
                catch ME
                    errordlg(['Could not connect to CAEN hardware: ' ME.message], 'Error');
                    return;
                end
            end
            
            % Create confirmation dialog with channel-specific message
            choice = questdlg([sprintf('%s: ',channelLabel) 'Channel ' num2str(chan)], ...
                'Enable/Disable HV', ...
                'Enable','Disable','Disable');
            
            % Handle response
            if strcmp(choice, 'Enable')
                fprintf('Enabling %s (Channel %d)\n', channelLabel, chan);
                try
                    caen.setVset(chan, 0); % Set to 0V when enabling
                    caen.setON(chan);
                catch ME
                    errordlg(['Error enabling ' channelLabel ': ' ME.message], 'Error');
                end
            elseif strcmp(choice, 'Disable')
                fprintf('Disabling %s (Channel %d)\n', channelLabel, chan);
                try
                    caen.setOFF(chan);
                catch ME
                    errordlg(['Error disabling ' channelLabel ': ' ME.message], 'Error');
                end
            end
        end
        
        function HVenableAllCallback(obj, enable)
            
            % Confirm action with user
            if enable
                action = 'Enable';
            else
                action = 'Disable';
            end
            choice = questdlg(['Are you sure you want to ' action ' all HV channels?'], ...
                [action ' All Channels'], ...
                'Yes', 'No', 'No');
            
            caen = obj.parentInst;

            if strcmp(choice, 'Yes')
                    fprintf('Enabling all Channels\n');
                try
                    caen.setVset(4, 0); % Set to 0V when enabling
                    caen.setON(4);
                catch ME
                    errordlg(['Error enabling all Channels: ' ME.message], 'Error');
                end
            else
                fprintf('Disabling all Channels\n');
                try
                    caen.setOFF(4);
                catch ME
                    errordlg(['Error disabling all Channels: ' ME.message], 'Error');
                end
            end
        end
    end
end

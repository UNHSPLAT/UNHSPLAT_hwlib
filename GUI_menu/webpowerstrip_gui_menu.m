classdef webpowerstrip_gui_menu < handle
    %WEBPOWERSTRIP_GUI_MENU Helper class for Web Power Strip GUI menu functionality

    properties (Access = private)
        parentInst      % Handle to the webpowerstrip object
        parentMenu      % Handle to the parent menu object
        outletLabels    % String array of user-friendly outlet names (1–8)
    end

    methods
        function obj = webpowerstrip_gui_menu(parentInst, parentMenu, outletLabels, ~, ~)
            %WEBPOWERSTRIP_GUI_MENU Construct an instance of this class
            obj.parentInst   = parentInst;
            obj.parentMenu   = parentMenu;

            % Default outlet labels
            if nargin < 3 || isempty(outletLabels)
                obj.outletLabels = "Outlet " + (1:8);
            else
                obj.outletLabels = outletLabels;
            end

            obj.createMenu();
        end

        function hMenu = createMenu(obj)
            % Create Web Power Strip submenu
            hMenu = uimenu(obj.parentMenu, 'Text', 'Web Power Strip');

            uimenu(hMenu, 'Text', 'Log On...', ...
                'MenuSelectedFcn', @(~,~) obj.parentInst.logon(), ...
                'Separator', 'off');
           
        end
    end
end

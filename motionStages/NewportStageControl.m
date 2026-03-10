classdef NewportStageControl < hwDevice

    properties (Constant)
        Type string = "Motion Stage"
        ModelNum string = "Newport XPS"
    end

    properties
        textLabel string = ""% 
        unit string = ""%
        Address string = ""%
        asmInfo %
        groups = ["Group1","Group2","Group3"] % Define the group names for the stage
        group_status = [0,0,0]
    end

    properties (SetObservable) 
        myxps
    end

    methods
        function obj = NewportStageControl(Address,groups,funcConfig)
            % Initialize control
            arguments
                Address string
                groups = ["Group1","Group2","Group3"]
                funcConfig = @(x) x
            end
            
            % Call parent constructor
            obj@hwDevice(funcConfig);
            
            obj.Connected = false;
            obj.Tag = '3axisNewportStage';
            
            obj.Address = Address;
            obj.groups = groups;
            obj.lastRead = zeros(1,length(obj.groups))*nan;
            
            % Set up read function for hwDevice
            function reading = readf(x);
                reading = obj.getAllPositions;
            end
            obj.readFunc = @readf;
            
            % Set refresh rate to 1 second and reinitialize timer
            obj.Timer.period = 4;
                
            try
                obj.asmInfo = NET.addAssembly('Newport.XPS.CommandInterface');
                obj.myxps = CommandInterfaceXPS.XPS();
            catch 
                warning('Newport Stage not integrated');
                obj.Connected = false;
            end
            
        end

        function disconnectDevice(obj)
            % Disconnect from the Newport XPS stage
            if ~isempty(obj.myxps)
                try
                    obj.myxps.CloseInstrument;
                catch
                    % Ignore errors during shutdown
                end
            end
            obj.stopTimer();
            obj.Connected = false;
            obj.lastRead = nan;
        end

        function connectDevice(obj)
            if ~ obj.Connected
                if ~isempty(obj.myxps)
                    open_code=obj.myxps.OpenInstrument(obj.Address,5001,1000);
                    if open_code == 0
                        obj.Connected = true;
                    else
                        warning('Failed to connect to Newport XPS stage');
                    end               
                    obj.funcConfig(obj);
                end
            end
        end

        function run(obj)
            obj.connectDevice();
            obj.initDevice();
            obj.home();
            start(obj.Timer)
        end

        function initDevice(obj)
            if obj.Connected
                init_codes = NaN(1,length(obj.groups));
                for i = 1:length(obj.groups)
                    gp = obj.groups(i);
                    code=obj.myxps.GroupInitialize(gp);
                    init_codes(i) = code;
                    if code ~= 0
                        fprintf('Failed to initialize group %s\n', gp);
                    end
                end
                display(init_codes);

                obj.group_status = ~init_codes;
                if ~all(init_codes)
                    obj.Connected = true;
                end
            end
        end

        function restart(obj,~,~)
            obj.disconnectDevice();
            obj.connectDevice();
            obj.initDevice();
            obj.home();
        end

        function home(obj)
            if obj.Connected
                for i = 1:length(obj.groups)
                    if obj.group_status(i)
                        [code,err] = obj.myxps.GroupHomeSearch(char(obj.groups(i)));
                        
                        if code ~= 0
                            warning('Failed to home stage: %s', string(err));
                        end
                    end
                end
            else
                warning('Device not connected');
            end
        end

        function zero(obj)
            if obj.Connected
                for i = 1:length(obj.groups)
                    obj.setPosition(obj.groups(i),0)
                end
            else
                warning('Device not connected');
            end
        end 

        % Set and get position methods
        function setPosition(obj,group,position)
            if obj.Connected
                code = obj.myxps.GroupMoveAbsolute(group,position,1);
                if code ~= 0
                    warning('Failed to set position: %s', code);
                end
            else
                warning('Device not connected');
            end
        end
        
        function val = getPosition(obj,group)
            if obj.Connected
                trynum = 0;
                while trynum <3
                    try
                        % For some reason calling the group position on just the group followed by the pos
                        % prevents error state
                        [err,vals,errnum] = obj.myxps.GroupPositionCurrentGet(char(group),1);
%                         [err,vals,errnum] = obj.myxps.GroupPositionCurrentGet([char(group),'.pos'],1);
                        val = vals.double; 
                        code = err;
                        if code ~= 0
                            fprintf('Failed to get position: Err = %s, Trynum = %d\n',string(errnum),trynum);
                            trynum = trynum+1;
                        else
                            return
                        end
                    catch
                        fprintf('StageComm Failed, Trynum = %d\n',trynum);
                        trynum = trynum +1;
                        val = nan;
                    end
                end
                obj.Connected = false;
            else
                val = nan;
            end
        end

        function positions = getAllPositions(obj)
            if obj.Connected
                % positions = obj.myxps.getCurrentPosition();
                positions = zeros(1, length(obj.groups))*nan;
                for i = 1:length(obj.groups)
                    pause(.05);
                    positions(i) = obj.getPosition(obj.groups(i));
                end    
            else
                positions = zeros(1, length(obj.groups))*nan;
            end
        end

    end
end



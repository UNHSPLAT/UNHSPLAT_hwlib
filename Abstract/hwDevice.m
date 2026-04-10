classdef hwDevice < handle & matlab.mixin.Heterogeneous
    %HWDEVICE Generic abstract class for hardware devices
    %   Base class providing common functionality for all hardware devices

    properties (Abstract, Constant)
        Type string % Device type (i.e. Power Supply, Temperature Controller, etc.)
        ModelNum string % Device model number
    end

    properties 
        Tag string = "" % User-configurable label for device
        funcConfig = @(x) x % Configuration function
    end

    properties (SetObservable) 
        Connected = false % Connection status of hwDevice
        readFunc = @(x) nan % Function to read from device
        lastRead % Last read value
        lastReadTime % Timestamp of last read
        refreshRate = 4 % Timer refresh rate in seconds
        Timer = timer % Timer object for periodic reads
        read_delay = nan % Time taken for last read operation
    end

    properties (Hidden)
        % Callback profiling event log (ring buffer)
        %   Each row: [start_datenum, duration_sec, status]
        %   status: 1 = success, 0 = disconnected, -1 = error
        profLog double = zeros(0,3)
        profLogMax = 600         % Max events to retain
        profEnabled logical = true  % Toggle profiling on/off
    end

    methods (Abstract)
        connectDevice(obj) % Abstract method to connect to device
        disconnectDevice(obj) % Abstract method to disconnect from device
    end

    methods
        function obj = hwDevice(varargin)
            %HWDEVICE Construct an instance of this class
            %   Accepts name-value pairs to set any hwDevice property

            %assign all properties provided
            if nargin > 0
                for i = 1:2:numel(varargin)
                    obj.(varargin{i}) = varargin{i+1};
                end
            end

            obj.initTimer();
        end

        function read(obj,~,~) 
            t_start = now(); %#ok<TNOW1>
            if obj.Connected
                tic;
                status = 1;
                try
                    % execute read function, assign output to lastRead if output exists
                    if nargout(obj.readFunc)>0
                        obj.lastRead = obj.readFunc(obj);
                    else
                        obj.readFunc(obj);
                    end
                    drawnow;
                catch ME
                    status = -1;
                    warning('hwDevice:ReadError','%s read error: %s', obj.Timer.Name, ME.message);
                end
                obj.read_delay = toc;
                obj.lastReadTime = datetime('now');
                obj.profLogAppend(t_start, obj.read_delay, status);
            else
                % Handle struct or numeric lastRead
                if isstruct(obj.lastRead)
                    fields = fieldnames(obj.lastRead);
                    for i = 1:length(fields)
                        obj.lastRead.(fields{i}) = obj.lastRead.(fields{i})*nan;
                    end
                else
                    obj.lastRead = obj.lastRead*nan;
                end
                obj.read_delay = nan;
                obj.profLogAppend(t_start, 0, 0);
            end
        end

        function delete(obj,~)
            obj.stopTimer();
            delete(obj.Timer);
        end
        
        function initTimer(obj)
            % Create timer name from hardware info
            if isempty(obj.Tag)
                timerName = [char(obj.Type) '_' char(obj.ModelNum) '_Timer'];
            else
                timerName = [char(obj.Type) '_' char(obj.ModelNum) '_' char(obj.Tag) '_Timer'];
            end
            
            obj.Timer = timer('Name', timerName,...
                                      'Period',obj.refreshRate,... %period
                                      'ExecutionMode','fixedSpacing',... %{singleShot,fixedRate,fixedSpacing,fixedDelay}
                                      'BusyMode','drop',... %{drop, error, queue}       
                                      'StartDelay',0,...
                                      'TimerFcn',@obj.read...
                                      );
        end

        function restartTimer(obj)
            %RESTARTTIMER Restarts timer if error

            % Stop timer if still running
            obj.stopTimer();

            % Restart timer
            if obj.Connected
                start(obj.Timer);
            end
        end

        function stopTimer(obj)
            % Stop timer if still running
            if strcmp(obj.Timer.Running,'on')
                stop(obj.Timer);
            end
        end

        function profLogAppend(obj, t_start, duration, status)
            % Append an event to the profiling ring buffer
            if ~obj.profEnabled, return; end
            obj.profLog(end+1,:) = [t_start, duration, status];
            n = size(obj.profLog,1);
            if n > obj.profLogMax
                obj.profLog = obj.profLog(n - obj.profLogMax + 1 : end, :);
            end
        end

        function clearProfLog(obj)
            % Clear profiling log
            obj.profLog = zeros(0,3);
        end
        
    end
end


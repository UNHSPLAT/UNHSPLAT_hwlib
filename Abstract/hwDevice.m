classdef hwDevice < handle & matlab.mixin.Heterogeneous
    %HWDEVICE Generic abstract class for hardware devices
    %   Base class providing common functionality for all hardware devices

    properties (Abstract, Constant)
        Type string % Device type (i.e. Power Supply, Temperature Controller, etc.)
        ModelNum string % Device model number
    end

    properties 
        Tag string = "" % User-configurable label for device
        funcConfig % Configuration function
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

    methods (Abstract)
        connectDevice(obj) % Abstract method to connect to device
        disconnectDevice(obj) % Abstract method to disconnect from device
    end

    methods
        function obj = hwDevice(funcConfig)
            %HWDEVICE Construct an instance of this class
            arguments
                funcConfig = @(x) x;
            end
            obj.funcConfig = funcConfig;
            obj.initTimer();
        end

        function read(obj,~,~) 
            if obj.Connected
                tic;
                % execute read function, assign output to lastRead if output exists
                if nargout(obj.readFunc)>0
                    obj.lastRead = obj.readFunc(obj);
                else
                    obj.readFunc(obj);
                end
                drawnow;
                obj.read_delay = toc;
                obj.lastReadTime = datetime('now');
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
            if strcmp(obj.Timer.Running,'on')
                stop(obj.Timer);
            end

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
        
    end
end


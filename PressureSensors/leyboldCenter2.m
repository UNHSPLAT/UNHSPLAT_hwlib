classdef leyboldCenter2 < hVisaHw
    %LEYBOLDCENTER2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        Type string = "Pressure Sensor"
        ModelNum string = "Center 2"
    end
    
    properties
        readListen1
        readListen2
    end


    methods
        function obj = leyboldCenter2(address,funcConfig)
            %LEYBOLDCENTER2 Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                address string='';%
                funcConfig = @(x) x;
            end
            obj@hVisaHw(address,funcConfig);

            obj.hVisa.BaudRate = 9600;
            obj.hVisa.Terminator = 'CR';
            obj.lastRead = [nan,nan];
        end
        
        function dataOut = leyboldRW(obj,inStr)
            retMsg = obj.devRW(inStr);

            if retMsg(1) == 6
                dataOut = obj.devRW(char(5));
            else
                error("leyboldCenter2:notAcknowledged","Communication error! Message not acknowledged by controller...");
            end
        end

        function pressure = readPressure(obj,sensorNum)

            if ~exist('sensorNum','var')
                sensorNum = 1:2;
            end

            pressure = zeros(1,length(sensorNum));
            for iS = 1:length(sensorNum)
                dataOut = obj.leyboldRW(['PR',num2str(sensorNum(iS))]);
                tokes = regexp(strtrim(dataOut),char(32),'split');
                if str2double(tokes{1}) > 2
                    pressure(iS) = NaN;
                    %warning("leyboldCenter2:sensorUnconnected","No pressure sensor connected on output %i...",sensorNum(iS));
                else
                    pressure(iS) = str2double(tokes{2});
                end
            end

        end
        
        function readPressure_async(obj, sensorNum)
            inStr = ['PR',num2str(sensorNum)];
            % Add listener for first response
            delete(obj.readListen1);
            obj.readListen1 = addlistener(obj, 'dataOut', 'PostSet', ...
                @(src,evt) handleFirstResponse(obj, src, evt));
            
            % Start first async read
            obj.devRW_async(inStr);
            
            function handleFirstResponse(obj, ~, evt)
                % Remove the first listener
                delete(obj.readListen1);
                
                % Check response
                if obj.dataOut(1) == 6
                    % Add listener for second response
                    delete(obj.readListen2);
                    obj.readListen2 = addlistener(obj, 'dataOut', 'PostSet', ...
                        @(src,evt) handleSecondResponse(obj, src, evt));
                    
                    % Send ENQ for data
                    obj.devRW_async(char(5));
                else
                    error("leyboldCenter2:notAcknowledged","Communication error! Message not acknowledged by controller...");
                end
            end
            
            function handleSecondResponse(obj, ~, evt)
                % Remove the second listener
                delete(obj.readListen2);
                tokes = regexp(strtrim(obj.dataOut),char(32),'split');
                if str2double(tokes{1}) > 2
                    obj.lastRead(sensorNum) = NaN;
                    %warning("leyboldCenter2:sensorUnconnected","No pressure sensor connected on output %i...",sensorNum(iS));
                else
                    obj.lastRead(sensorNum) = str2double(tokes{2});
                end
                % Data is now in obj.dataOut
            end
        end
    end
end


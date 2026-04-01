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
        currentSensorIndex
        sensorList
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
            % Initialize or validate sensor numbers
            arguments
                obj = nan;
                sensorNum = [1,2];
            end
            
            % Store sensor list and current index in object for async use
            if length(sensorNum) > 1
                obj.sensorList = sensorNum;
                obj.currentSensorIndex = sensorNum(1);
            else
                obj.currentSensorIndex = sensorNum;
            end

            function handlePressureResponse(obj, ~, ~)
                obj.devR_async();
                % Process current sensor's data
                try
                    tokes = regexp(strtrim(obj.dataOut), char(32), 'split');
                    if str2double(tokes{1}) > 2
                        obj.lastRead(obj.currentSensorIndex) = nan;
                    else
                        obj.lastRead(obj.currentSensorIndex) = str2double(tokes{2});
                    end
                catch
                    obj.lastRead(obj.currentSensorIndex) = nan;
                end
                
                % continue if there are more sensors to read
                if ismember(obj.currentSensorIndex+1, obj.sensorList)
                    obj.readPressure_async(obj.currentSensorIndex + 1);
                else
                    obj.currentSensorIndex = [];
                    obj.sensorList = [];
                end
            end

            function handlePressureAsk(obj,~,~)
                obj.devR_async();
                retMsg = obj.dataOut;
                if retMsg(1) == 6
                    obj.devRW_async(char(5), @(~,~) handlePressureResponse(obj));
                else
                    error("leyboldCenter2:notAcknowledged","Communication error! Message not acknowledged by controller...");
                end
            end    
            
            % Start first sensor read
            sendStr = ['PR', num2str(obj.currentSensorIndex)];
            obj.devRW_async(sendStr,@(~,~) handlePressureAsk(obj));
            
        end
    end
end


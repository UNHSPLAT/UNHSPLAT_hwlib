classdef leyboldGraphix3 < hwDevice
    %LEYBOLDGRAPHIX3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        Type string = "Pressure Sensor"
        ModelNum string = "Graphix 3"
    end
    
    properties (Access = private)
        pressureListener
        currentSensorIndex
        sensorList
    end
    
    methods
        function obj = leyboldGraphix3(address,funcConfig)
            %LEYBOLDGRAPHIX3 Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                address string='';%
                funcConfig = @(x) x;
            end
            obj@hwDevice(address,funcConfig);

            obj.hVisa.BaudRate = 38400;
            obj.hVisa.Terminator = 4;
            obj.lastRead = [nan,nan,nan];
        end
        
        function dataOut = leyboldRead(obj,paramGrp,paramNum)

            sendStr = [char(15),num2str(paramGrp),char(59),num2str(paramNum)];
            sendStr = obj.leyboldCRC(sendStr);
            dataOut = obj.devRW(sendStr);

        end

        function leyboldWrite(obj,paramGrp,paramNum,val)

            sendStr = [char(14),num2str(paramGrp),char(59),num2str(paramNum),char(59),num2str(val),char(32)];
            sendStr = obj.leyboldCRC(sendStr);

            obj.devRW(sendStr);

        end

        function pressure = readPressure(obj,sensorNum)
            if ~exist('sensorNum','var')
                sensorNum = 1:3;
            end

            pressure = zeros(1,length(sensorNum));
            for iS = 1:length(sensorNum)
                dataOut = obj.leyboldRead(sensorNum(iS),29);
                press = str2double(strtrim(dataOut(2:end-2)));
                pressure(iS) = press;
                if isnan(pressure(iS))
                    %warning("leyboldGraphix3:sensorUnconnected","No pressure sensor connected on output %i...",sensorNum(iS));
                end
            end
        end

        function readPressure_async(obj, sensorNum)
            % Initialize or validate sensor numbers
            if nargin < 2 || isempty(sensorNum)
                sensorNum = 1;
            end
            
            % Initialize pressure array in object for async collection
            obj.lastRead = nan(1, length(sensorNum));
            
            % Store sensor list and current index in object for async use
            obj.sensorList = sensorNum;
            obj.currentSensorIndex = sensorNum;
            
            % Create listener for data collection
            obj.pressureListener = addlistener(obj, 'dataOut', 'PostSet', ...
                @(src,evt) handlePressureResponse(obj, src, evt));
            
            % Start first sensor read
            sendStr = obj.leyboldCRC([char(15), num2str(sensorNum(1)), char(59), num2str(29)]);
            obj.devRW_async(sendStr);
            
            function handlePressureResponse(obj, ~, ~)
                % Process current sensor's data
                try
                    pressure = str2double(strtrim(obj.dataOut(2:end-2)));
                    obj.lastRead(obj.currentSensorIndex) = pressure;
                    display(pressure);
                catch
                    obj.lastRead(obj.currentSensorIndex) = nan;
                end
                % Clean up when done
                delete(obj.pressureListener);
                obj.pressureListener = [];
                obj.currentSensorIndex = [];
                obj.sensorList = [];
            end
        end
    end

    methods (Static)

        function [outStr,checksum] = leyboldCRC(inStr)

            checksum = 255-mod(sum(double(inStr)),256);
            if checksum < 32
                checksum = checksum+32;
            end

            outStr = [inStr,char(checksum)];

        end

    end
end


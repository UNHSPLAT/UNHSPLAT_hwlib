classdef leyboldGraphix3 < hVisaHw
    %LEYBOLDGRAPHIX3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        Type string = "Pressure Sensor"
        ModelNum string = "Graphix 3"
    end
    
    properties (Access = private)
        currentSensorIndex
        sensorList
    end

    properties
        pressureListener
    end

    
    methods
        function obj = leyboldGraphix3(address,varargin)
            %LEYBOLDGRAPHIX3 Construct an instance of this class
            if nargin < 1; address = ''; end
            obj@hVisaHw(address,varargin{:});

            obj.hVisa.BaudRate = 38400;
            obj.hVisa.Terminator = 4;
            obj.lastRead = [nan,nan,nan];
            obj.readFunc = @(x) x.readPressure_async();
            obj.postConstruct();
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
            arguments
                obj = nan;
                sensorNum = [1,2,3];
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
                        pressure = str2double(strtrim(obj.dataOut(2:end-2)));
                        obj.lastRead(obj.currentSensorIndex) = pressure;
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
            
            % Start first sensor read
            sendStr = obj.leyboldCRC([char(15), num2str(obj.currentSensorIndex), char(59), num2str(29)]);
            obj.devRW_async(sendStr,@(~,~) handlePressureResponse(obj));
            
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


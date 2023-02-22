classdef leyboldCenter2 < hwDevice
    %LEYBOLDCENTER2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        Type string = "Pressure Sensor"
        ModelNum string = "Center 2"
    end
    
    methods
        function obj = leyboldCenter2(address,funcConfig)
            %LEYBOLDCENTER2 Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                address string='';%
                funcConfig = @(x) x;
            end
            obj@hwDevice(address,funcConfig);

            obj.hVisa.BaudRate = 9600;
            obj.hVisa.Terminator = 'CR';
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
                    warning("leyboldCenter2:sensorUnconnected","No pressure sensor connected on output %i...",sensorNum(iS));
                else
                    pressure(iS) = str2double(tokes{2});
                end
            end

        end

        function ask(obj)
            if ~exist('sensorNum','var')
                sensorNum = 1:2;
            end

            pressure = zeros(1,length(sensorNum));
            for iS = 1:length(sensorNum)
                inStr = ['PR',num2str(sensorNum(iS))];
                obj.call(inStr);
            end

        end
    end
end


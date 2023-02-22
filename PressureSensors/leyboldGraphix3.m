classdef leyboldGraphix3 < hwDevice
    %LEYBOLDGRAPHIX3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        Type string = "Pressure Sensor"
        ModelNum string = "Graphix 3"
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
        end
        
        function dataOut = leyboldRead(obj,paramGrp,paramNum)
            sendStr = [char(15),num2str(paramGrp),char(59),num2str(paramNum)];
            sendStr = obj.leyboldCRC(sendStr);
            dataOut = obj.devRW(sendStr);
        end

        function ask(obj)
            if ~exist('sensorNum','var')
                sensorNum = 1:3;
            end
            pressure = zeros(1,length(sensorNum));
            for iS = 1:length(sensorNum)
                paramGrp = sensorNum(iS);
                paramNum = 29;
                sendStr = [char(15),num2str(paramGrp),char(59),num2str(paramNum)];
                sendStr = obj.leyboldCRC(sendStr);
                obj.call(sendStr);
            end
        end
            
        function leyboldAnswer(obj)
            dataOut = obj.leyboldRead(sensorNum,29);
            pressure(iS) = str2double(strtrim(dataOut(2:end-2)));
            if isnan(pressure(iS))
                warning("leyboldGraphix3:sensorUnconnected","No pressure sensor connected on output %i...",sensorNum(iS));
            end
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
                pressure(iS) = str2double(strtrim(dataOut(2:end-2)));
                if isnan(pressure(iS))
                    warning("leyboldGraphix3:sensorUnconnected","No pressure sensor connected on output %i...",sensorNum(iS));
                end
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


classdef keithleyDAQ6510 < multimeter
    %KEITHLEYDAQ6510 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        ModelNum string = "DAQ6510"
    end
    
    methods
        function obj = keithleyDAQ6510(address,funcConfig)
            % Construct an instance of this class
            %   Detailed explanation goes here
            obj@multimeter(address,funcConfig);
            obj.lastRead = [nan,nan,nan];
        end
        
        function val = measure(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            dataOut = obj.devRW("measure?");
            val = str2double(strtrim(dataOut));
        end

        function dataOut = initThenRead(obj)

            obj.devRW('INIT');
            obj.devRW('*WAI');
            dataOut = obj.devRW(':READ?');

        end

        function dataOut = performScan(obj,startIndex,endIndex)

            obj.devRW('INIT');
            obj.devRW('*WAI');
            dataOut = obj.devRW([':TRAC:DATA? ',num2str(startIndex),', ',num2str(endIndex)]);
            tokes = regexp(strtrim(dataOut),',','split');
            dataOut = str2double(tokes);

        end
    end
end


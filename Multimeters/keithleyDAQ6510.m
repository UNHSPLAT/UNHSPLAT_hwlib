classdef keithleyDAQ6510 < multimeter
    %KEITHLEYDAQ6510 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        ModelNum string = "DAQ6510"
    end
    
    methods
        function obj = keithleyDAQ6510(address)
            %KEITHLEYDAQ6510 Construct an instance of this class
            %   Detailed explanation goes here
            obj@multimeter(address);
        end
        
        function val = measure(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            dataOut = obj.devRW("measure?");
            val = str2double(strtrim(dataOut));
        end
    end
end


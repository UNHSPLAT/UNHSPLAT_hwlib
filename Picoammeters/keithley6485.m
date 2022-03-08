classdef keithley6485 < hwDevice

    properties
        NPLC double
    end

    properties (Constant)
        Type = "Picoammeter"
        ModelNum = "6485"
    end

    methods
        function obj = keithley6485(address)

            obj@hwDevice(address);
        end

        function dataOut = read(obj)

            dataOut = obj.devRW("FETC?");
            dataOut = str2double(strtrim(dataOut));

        end
    end
end

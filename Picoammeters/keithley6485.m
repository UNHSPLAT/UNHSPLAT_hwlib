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

            dataOut = obj.devRW('READ?');

        end

        function dataOut = devRW(obj)

            dataOut = devRW@hwDevice(obj);

            if strcmp(obj.hVisa.Status,'open')
                deviceAlreadyOpen = true;
            else
                deviceAlreadyOpen = false;
            end

            fprintf(obj.hVisa,':SYST:LOC');

            if ~deviceAlreadyOpen
                fclose(obj.hVisa);
            end

        end


    end
end

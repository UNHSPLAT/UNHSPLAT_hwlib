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
            dataOut = str2double(strtrim(dataOut));

        end

%         function dataOut = devRW(obj,dataIn)
% 
%             if nargout > 0
%                 dataOut = devRW@hwDevice(obj,dataIn);
%             else
%                 devRW@hwDevice(obj,dataIn);
%             end
% 
%             pause(0.3); % For testing comm errors
% 
%             if strcmp(obj.hVisa.Status,'open')
%                 deviceAlreadyOpen = true;
%             else
%                 deviceAlreadyOpen = false;
%             end
% 
%             if ~deviceAlreadyOpen
%                 fopen(obj.hVisa);
%             end
% 
%             fprintf(obj.hVisa,':SYST:LOC');
% 
%             if ~deviceAlreadyOpen
%                 fclose(obj.hVisa);
%             end
% 
%         end


    end
end

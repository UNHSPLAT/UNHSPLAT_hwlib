classdef srsHVPS < powerSupply
    %SRSHVPS Summary of this class goes here
    %   Detailed explanation goes here

    properties (Constant)
        NumOutputs double = 1
    end

    methods
        function obj = srsHVPS(address)
            %SRSHVPS Construct an instance of this class
            %   Detailed explanation goes here
            obj@powerSupply(address);

            obj.getAllSettings;
        end

        function setVSet(obj,volt)

            obj.devRW(['VSET',num2str()]);
            obj.VSet = volt;

        end

        function volt = getVSet(obj)

            dataOut = obj.devRW('VSET?');
            volt = str2double(strtrim(dataOut));

            obj.VSet = volt;

        end

        function volt = measV(obj)

            dataOut = obj.devRW('VOUT?');
            volt = str2double(strtrim(dataOut));
            
        end

        function setISet(obj,curr)

            obj.devRW(['ILIM',num2str()]);
            obj.ISet = curr;

        end

        function curr = getISet(obj)

            dataOut = obj.devRW('ILIM?');
            curr = str2double(strtrim(dataOut));

            obj.ISet = curr;

        end

        function curr = measI(obj)

            dataOut = obj.devRW('IOUT?');
            curr = str2double(strtrim(dataOut));

        end

        function pow = measP(obj)

            volt = obj.measV;
            curr = obj.measI;

            pow = volt.*curr;
        
        end

        function setOutputState(obj,state)

            if state
                obj.devRW('HVON');
                obj.OutputState = true;
            else
                obj.devRW('HVOF');
                obj.OutputState = false;
            end

        end

        function state = getOutputState(obj)

            obj.devRW('HVOF');
            obj.OutputState = false;
            state = false;

        end

        function [volt,curr,state] = getAllSettings(obj)

            volt = obj.getVSet;
            curr = obj.getISet;
            state = obj.getOutputState;

        end

    end
end


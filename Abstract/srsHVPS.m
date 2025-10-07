classdef srsHVPS < powerSupply
    %SRSHVPS Summary of this class goes here
    %   Detailed explanation goes here

    properties (Constant)
        NumOutputs double = 1
    end

    properties
        Vmeas double = nan%
        Imeas double = nan%
    end

    methods
        function obj = srsHVPS(address,funcConfig)
            % Construct an instance of this class
            %   Detailed explanation goes here
            obj@powerSupply(address,funcConfig);

            %obj.getAllSettings;
        end

        function setVSet(obj,volt)

            obj.devRW(['VSET',num2str(volt)]);
            obj.VSet = volt;

        end

        function volt = getVSet(obj)

            dataOut = obj.devRW('VSET?');
            volt = str2double(strtrim(dataOut));

            obj.VSet = volt;

        end

        function getVSet_async(obj)
            function readVasync(~,~)
                dataOut = fscanf(obj.hVisa);
                obj.dataOut = dataOut;
                display(dataOut);
                obj.VSet = str2double(strtrim(dataOut));
            end
            obj.devRW_async('VSET?',@readVasync);
        end

        function volt = measV(obj)
            dataOut = obj.devRW('VOUT?');
            volt = str2double(strtrim(dataOut));
            obj.Vmeas = volt;
        end

        function measVasync(obj)
            function readVasync(~,~)
                dataOut = fscanf(obj.hVisa);
                obj.dataOut = dataOut;
                obj.lastRead = str2double(strtrim(dataOut));
                
                obj.hVisa.BytesAvailableFcn = @obj.devR_async;
                if strcmp(obj.hVisa.Status,'open')
                    flushoutput(obj.hVisa);
                    flushinput(obj.hVisa);
                    fclose(obj.hVisa);
                end
            end
            obj.devRW_async('VOUT?',@readVasync);
        end

        function setISet(obj,curr)
            obj.devRW(['ILIM',num2str(curr)]);
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

        function measIasync(obj)
            function readVasync(~,~)
                dataOut = fscanf(obj.hVisa);
                obj.dataOut = dataOut;
                display(dataOut);
                obj.Imeas = str2double(strtrim(dataOut));
            end
            obj.devRW_async('IOUT?',@readVasync);
        end

        function readAsync(obj)
            obj.measVasync;
            obj.measIasync;
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


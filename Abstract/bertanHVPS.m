classdef bertanHVPS < powerSupply
    %BERTANHVPS Summary of this class goes here
    %   Detailed explanation goes here

    properties (Constant)
        NumOutputs double = 1
    end

    methods
        function obj = bertanHVPS(address)
            %BERTANHVPS Construct an instance of this class
            %   Detailed explanation goes here
            obj@powerSupply(address);

            obj.getAllSettings;
        end

        function setVSet(obj,volt)

            obj.devRW(['P',num2str(volt/1000,'%.4f'),'KG']);
            obj.VSet = volt;

        end

        function volt = measV(obj)

            volt = obj.getAllSettings;

        end

        function setISet(obj,curr)

            obj.devRW(['L',num2str(curr*1000,'%.4f'),'M']);
            obj.ISet = curr;

        end

        function curr = measI(obj)

            [~,curr] = obj.getAllSettings;

        end

        function [pow,volt,curr] = measP(obj)

            [volt,curr] = obj.getAllSettings;

            pow = volt.*curr;
        
        end

        function setOutputState(obj,state)

            if state
                obj.devRW('R');
                obj.OutputState = true;
            else
                obj.devRW('Z');
                obj.OutputState = false;
            end

        end

        function state = getOutputState(obj)

            [~,~,state] = obj.getAllSettings;
            obj.OutputState = state;

        end

        function [volt,curr,state] = getAllSettings(obj)

            dataOut = obj.devRW('T0');
            tokes = regexp(strtrim(dataOut),' ','split');

            volt = str2double(tokes{2}(2:end-1))*1000;
            curr = str2double(tokes{3}(2:end-1))/1000;
            if strcmpi(tokes{1},'N')
                state = true;
            elseif strcmpi(tokes{1},'S')
                state = false;
            end

        end

    end
end


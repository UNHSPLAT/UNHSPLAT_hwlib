classdef keysightE36313A < powerSupply
    %KEYSIGHTE36313A Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        ModelNum string = "E36313A"
        NumOutputs double = 3
        VMin double = [0,0,0]
        VMax double = [6.18,25.75,25.75]
        IMin double = [0,0,0]
        IMax double = [10.3,2.06,2.06]
    end

    properties (SetAccess = protected)
        VSet double
        ISet double
        OutputState logical
    end
    
    methods
        function obj = keysightE36313A(address,resourcelist,funcConfig)
            %KEYSIGHTE36313A Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                address string='';%
                resourcelist = table([],[],[],[],[],[],...
                        'VariableNames',["ResourceName","Alias","Vendor","Model","SerialNumber","Type"]);% 
                funcConfig = @(x) x;
            end
            obj@powerSupply(address,resourcelist,funcConfig);
            %obj.getAllSettings;
        end
        
        function setVSet(obj,volt,output)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if ~exist('output', 'var')
                if length(volt) == 3
                    output = 1:3;
                elseif length(volt) == 2
                    error('keysightE36313A:missingOutput','Invalid input arguments! Outputs must be specified explicitly for two voltage inputs...');
                elseif length(volt) == 1
                    warning('keysightE36313A:outputDefault','No output provided! Defaulting to first output...')
                    output = 1;
                end
            elseif length(volt) ~= length(output)
                error('keysightE36313A:invalidLengths','Invalid input arguments! Voltage and output arguments must be same length...');
            end

            for iO = 1:length(output)
                obj.devRW(['VOLT ',num2str(volt(iO)),', (@',num2str(output(iO)),')']);
                obj.VSet(output(iO)) = volt(iO);
            end

        end

        function volt = getVSet(obj,output)

            if ~exist('output','var')
                output = 1:3;
            end
            
            chStr = num2str(output,'%i,');
            chStr = chStr(1:end-1);

            dataOut = obj.devRW(['VOLT? (@',chStr,')']);
            volt = str2double(regexp(strtrim(dataOut),',','split'));
            
            % Set VSet property to retrieved value
            obj.VSet(output) = volt;

        end

        function volt = measV(obj,output)

            if ~exist('output','var')
                output = [1,2,3];
            end
            
            chStr = num2str(output,'%i,');
            chStr = chStr(1:end-1);

            dataOut = obj.devRW(['MEAS:VOLT? (@',chStr,')']);
            volt = str2double(regexp(strtrim(dataOut),',','split'));

        end

        function setISet(obj,curr,output)
            
            if ~exist('output', 'var')
                if length(curr) == 3
                    output = [1, 2, 3];
                elseif length(curr) == 2
                    error('keysightE36313A:missingOutput','Invalid input arguments! Outputs must be specified explicitly for two current inputs...');
                elseif length(curr) == 1
                    warning('keysightE36313A:outputDefault','No output provided! Defaulting to first output...')
                    output = 1;
                end
            elseif length(curr) ~= length(output)
                error('keysightE36313A:invalidLengths','Invalid input arguments! Current and output arguments must be same length...');
            end

            for iO = 1:length(output)
                obj.devRW(['CURR ',num2str(curr(iO)),', (@',num2str(output(iO)),')']);
                obj.ISet(output(iO)) = curr(iO);
            end

        end

        function curr = getISet(obj,output)

            if ~exist('output', 'var')
                output = 1:3;
            end
            
            chStr = num2str(output,'%i,');
            chStr = chStr(1:end-1);

            dataOut = obj.devRW(['CURR? (@',chStr,')']);
            curr = str2double(regexp(strtrim(dataOut),',','split'));
            
            % Set ISet property to retrieved value
            obj.ISet(output) = curr;

        end

        function curr = measI(obj,output)

            if ~exist('output', 'var')
                output = 1:3;
            end
            
            chStr = num2str(output,'%i,');
            chStr = chStr(1:end-1);

            dataOut = obj.devRW(['MEAS:CURR? (@',chStr,')']);
            curr = str2double(regexp(strtrim(dataOut),',','split'));

        end

        function setOutputState(obj,state,output)
            
            if ~exist('output', 'var')
                if length(state) == 3
                    output = 1:3;
                elseif length(state) == 2
                    error('keysightE36313A:missingOutput','Invalid input arguments! Outputs must be specified explicitly for two current inputs...');
                elseif length(state) == 1
                    warning('keysightE36313A:outputDefault','No output provided! Defaulting to first output...')
                    output = 1;
                end
            elseif length(state) ~= length(output)
                error('keysightE36313A:invalidLengths','Invalid input arguments! State and output arguments must be same length...');
            end

            for iO = 1:length(output)
                obj.devRW(['OUTP ',num2str(state(iO)),', (@',num2str(output(iO)),')']);
                obj.OutputState(output(iO)) = state(iO);
            end

        end

        function out = getOutputState(obj,output)

            if ~exist('output', 'var')
                output = 1:3;
            end
            
            chStr = num2str(output,'%i,');
            chStr = chStr(1:end-1);

            dataOut = obj.devRW(['OUTP? (@',chStr,')']);
            out = logical(str2double(regexp(strtrim(dataOut),',','split')));
            
            % Set OutputState property to retrieved value
            obj.OutputState(output) = out;

        end

        function pow = measP(obj,output)

            if ~exist('output', 'var')
                output = 1:3;
            end

            volt = obj.measV(output);
            curr = obj.measI(output);

            pow = volt.*curr;

        end

        function [volt,curr,state] = getAllSettings(obj)

            volt = obj.getVSet(1:obj.NumOutputs);
            curr = obj.getISet(1:obj.NumOutputs);
            state = obj.getOutputState(1:obj.NumOutputs);
            
        end

        function selectOutput(obj,output)

            arguments
                obj
                output (1,1) double {mustBeMember(output,1:3)}
            end

            obj.devRW(['INST:SEL CH',num2str(output)]);

        end

    end
end


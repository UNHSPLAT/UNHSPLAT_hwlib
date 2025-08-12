classdef powerSupply < hwDevice
    %POWERSUPPLY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        Type string = "Power Supply"
    end

    properties (Abstract, Constant)
        NumOutputs double
        VMin double
        VMax double
        IMin double
        IMax double
    end

    properties (Abstract, SetAccess = protected)
        VSet double
        ISet double
        OutputState logical
    end
    
    methods
        function obj = powerSupply(address,funcConfig)
            % Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                address string='';%
                funcConfig = @(x) x;
            end
            
            obj@hwDevice(address,funcConfig);
        end
    end

    methods (Abstract)
        setVSet(obj,volt,output)
        volt = measV(obj,output)
        setISet(obj,curr,output)
        curr = measI(obj,output)
        setOutputState(obj,state,output)
        out = getOutputState(obj,output)
        pow = measP(obj,output)
    end
end


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
        function obj = powerSupply(address)
            %POWERSUPPLY Construct an instance of this class
            %   Detailed explanation goes here
            obj@hwDevice(address);
        end
    end

    methods (Abstract)
        setVSet(obj, volt, output)
        volt = getVSet(obj, output)
        volt = measV(obj, output)
        setISet(obj, curr, output)
        curr = getISet(obj, output)
        curr = measI(obj, output)
        setOutputState(obj, state, output)
        out = getOutputState(obj, output)
        pow = measP(obj, output)
    end
end


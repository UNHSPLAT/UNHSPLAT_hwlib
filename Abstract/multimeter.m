classdef multimeter < hwDevice
    %MULTIMETER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        Type string = "Multimeter"
    end
    
    methods
        function obj = multimeter(address,funcConfig)
            % Construct an instance of this class
            %   Detailed explanation goes here
            obj@hwDevice(address,funcConfig);
        end
    end
end


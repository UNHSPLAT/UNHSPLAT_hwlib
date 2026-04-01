classdef multimeter < hVisaHw
    %MULTIMETER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        Type string = "Multimeter"
    end
    
    methods
        function obj = multimeter(address,funcConfig)
            % Construct an instance of this class
            %   Detailed explanation goes here
            obj@hVisaHw(address,funcConfig);
        end
    end
end


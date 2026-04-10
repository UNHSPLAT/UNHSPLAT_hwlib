classdef multimeter < hVisaHw
    %MULTIMETER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        Type string = "Multimeter"
    end
    
    methods
        function obj = multimeter(address,varargin)
            % Construct an instance of this class
            obj@hVisaHw(address,varargin{:});
        end
    end
end


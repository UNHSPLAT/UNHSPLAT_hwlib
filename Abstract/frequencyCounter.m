classdef frequencyCounter < hVisaHw
    %FREQUENCYCOUNTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        Type string = "Frequency Counter"
    end
    
    methods
        function obj = frequencyCounter(address,varargin)
            %FREQUENCYCOUNTER Construct an instance of this class
            obj@hVisaHw(address,varargin{:});
        end
    end
end


classdef frequencyCounter < hVisaHw
    %FREQUENCYCOUNTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        Type string = "Frequency Counter"
    end
    
    methods
        function obj = frequencyCounter(address)
            %FREQUENCYCOUNTER Construct an instance of this class
            %   Detailed explanation goes here
            obj@hVisaHw(address);
        end
    end
end


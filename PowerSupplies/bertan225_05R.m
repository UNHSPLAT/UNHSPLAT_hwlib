classdef bertan225_05R < bertanHVPS
    %BERTAN225_05R Summary of this class goes here
    %   Detailed explanation goes here

    properties (Constant)
        ModelNum string = "225-05R"
        VMin double = 0
        VMax double = 5000
        IMin double = 0
        IMax double = 0.005
    end

    properties (SetAccess = protected)
        VSet double
        ISet double
        OutputState logical
    end

    methods
        function obj = bertan225_05R(address)
            %BERTAN225_05R Construct an instance of this class
            %   Detailed explanation goes herew\
            obj@bertanHVPS(address);

        end
    end
end


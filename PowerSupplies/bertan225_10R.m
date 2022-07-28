classdef bertan225_10R < bertanHVPS
    %BERTAN225_10R Summary of this class goes here
    %   Detailed explanation goes here

    properties (Constant)
        ModelNum string = "225-10R"
        VMin double = 0
        VMax double = 10000
        IMin double = 0
        IMax double = 0.0025
    end

    properties (SetAccess = protected)
        VSet double
        ISet double
        OutputState logical
    end

    methods
        function obj = bertan225_10R(address)
            %BERTAN225_10R Construct an instance of this class
            %   Detailed explanation goes here
            obj@bertanHVPS(address);

        end
    end
end


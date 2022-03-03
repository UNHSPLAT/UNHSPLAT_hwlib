classdef srsPS350 < srsHVPS
    %SRSPS350 Summary of this class goes here
    %   Detailed explanation goes here

    properties (Constant)
        ModelNum string = "PS350"
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
        function obj = srsPS350(address)
            %SRSPS350 Construct an instance of this class
            %   Detailed explanation goes here
            obj@srsHVPS(address);

        end
    end
end


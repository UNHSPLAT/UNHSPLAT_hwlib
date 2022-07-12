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
        function obj = srsPS350(address,resourcelist,funcConfig)
            % Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                address string='';%
                resourcelist = table([],[],[],[],[],[],...
                        'VariableNames',["ResourceName","Alias","Vendor","Model","SerialNumber","Type"]);% 
                funcConfig = @(x) x;
            end
            obj@srsHVPS(address,resourcelist,funcConfig);

        end
    end
end


classdef flukeHydra2620A < multimeter
    %KEITHLEYDAQ6510 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        ModelNum string = "2620A"
    end
    
    methods
        function obj = flukeHydra2620A(address,funcConfig)
            % Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                address string='';%
                funcConfig = @(x) x;
            end

            obj@multimeter(address,funcConfig);
            obj.lastRead = [nan,nan,nan,nan];

            function stuff = read_it(self)
                stuff = self.read_scan();
            end
            obj.readFunc =@read_it;
        end

        function dataOut = read_scan(obj)
            dataOut = obj.devRW('LAST?');
            tokes = regexp(strtrim(dataOut),',','split');
            dataOut = str2double(tokes);
        end

        function ask_async(obj)
            obj.devRW_async('LAST?',@obj.read_async);
        end

        function read_async(obj)
            obj.devR_async();
            tokes = regexp(strtrim(obj.dataOut),',','split');
            obj.lastRead = str2double(tokes);
        end
    end
end


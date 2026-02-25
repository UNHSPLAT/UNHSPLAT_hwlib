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
                stuff = self.scan();
            end
            obj.readFunc =@read_it;
        end
        
        function val = measure(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            dataOut = obj.devRW("measure?");
            val = str2double(strtrim(dataOut));
        end

        function dataOut = initThenRead(obj)

            obj.devRW('INIT');
            obj.devRW('*WAI');
            dataOut = obj.devRW(':READ?');

        end

        function dataOut = scan(obj)
            dataOut = obj.devRW('LAST?');
            tokes = regexp(strtrim(dataOut),',','split');
            dataOut = str2double(tokes);
        end
    end
end


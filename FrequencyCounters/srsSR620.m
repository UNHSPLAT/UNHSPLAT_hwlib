classdef srsSR620 < frequencyCounter
    %SRSSR620 Summary of this class goes here
    %   Detailed explanation goes here

    properties (Constant)
        ModelNum string = "SR620"
    end

    properties (SetAccess = protected)
        VSet double
        ISet double
        OutputState logical
    end

    methods
        function obj = srsSR620(address)
            %SRSSR620 Construct an instance of this class
            %   Detailed explanation goes here
            obj@frequencyCounter(address);
        end

        function dataOut = measure(obj)

            dataOut = obj.devRW('MEAS? 0');
            dataOut = str2double(strtrim(dataOut));
            display(dataOut);

        end

        function measure_async(obj)
            function read_async(~,~)
                dataOut = fscanf(obj.hVisa);
                display(dataOut);
                obj.dataOut = dataOut;
                obj.lastRead = str2double(strtrim(dataOut));
                obj.lastReadTime = datetime('now');

                obj.hVisa.BytesAvailableFcn = @(~,~) nan;
                if strcmp(obj.hVisa.Status,'open')
                    flushoutput(obj.hVisa);
                    flushinput(obj.hVisa);
                    fclose(obj.hVisa);
                end
            end
            obj.devRW_async('MEAS? 0',@read_async);
        end
    end
end


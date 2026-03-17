classdef webpowerstrip < hwDevice
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    properties (Constant)
        Type string = "powerstrip"
        ModelNum string = "webpowerstrip"
    end

    properties
        address = '';
        username = '';
        password = '';
    end
    
    methods
        function obj = webpowerstrip(Address,funcConfig,username,password)
            % Initialize control
            arguments
                Address string
                funcConfig = @(x) x
                username = 'admin'
                password = '1234'
            end
            % Call parent constructor
            obj@hwDevice(funcConfig);
            
            obj.Connected = false;
            obj.lastRead = ones(8)*nan;

            obj.address = Address;
            obj.username = username;
            obj.password = password;
        end
        
        function disconnectDevice(obj)
            % Disconnect from the Newport XPS stage
            if ~isempty(obj.myxps)
                try
                    obj.myxps.CloseInstrument;
                catch
                    % Ignore errors during shutdown
                end
            end
            obj.stopTimer();
            obj.Connected = false;
            obj.lastRead = nan;
        end

        function connectDevice(obj)
            if ~ obj.Connected
                if ~isempty(obj.myxps)
                    open_code=obj.myxps.OpenInstrument(obj.Address,5001,1000);
                    if open_code == 0
                        obj.Connected = true;
                    else
                        warning('Failed to connect to Newport XPS stage');
                    end               
                    obj.funcConfig(obj);
                end
            end
        end

        function cmdout = checkState(obj,nOutlet)
            arguments
                obj
                nOutlet = 'all'
            end

            if nOutlet=='all'
                cout = 'all;';
            elseif isinteger(nOutlet)
                cout = sprintf('=%d',nOutlet);
            end

            cmdr = sprintf("curl -u %s:%s http://%s/restapi/relay/outlets/%s/state/",obj.username,obj.password,obj.address,cout);

            [status,cmdout] = system(cmdr);

            % Parse curl output: strip progress header lines, decode JSON from last line
            lines = strtrim(strsplit(cmdout, newline));
            lines = lines(~cellfun(@isempty, lines));
            cmdout = jsondecode(lines{end});
            
        end

    end
end


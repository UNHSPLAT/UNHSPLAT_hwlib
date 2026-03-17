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
                %Check connection by asking for own ip address
                cmdr = obj.buildCurlRestapiAsk('cred/ip_address/');
                [open_code,cmdout]=system(cmdr);
                cmdout = obj.parseCurlOutput(cmdout);
                
                host = java.net.InetAddress.getLocalHost();
                ipAddress = char(host.getHostAddress());
                
                if open_code == 0 && strcmp(cmdout, ipAddress)
                    obj.Connected = true;
                else
                    warning('Failed to connect to Newport XPS stage');
                end               
                obj.funcConfig(obj);
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
            cmdr = obj.buildCurlRestapiAsk(sprintf(...
                'relay/outlets/%s/state/%s', cout));

            [status,cmdout] = system(cmdr);
            cmdout = obj.parseCurlOutput(cmdout);
            
        end

    end

    methods (Access = private)
        function result = parseCurlOutput(~, raw)
            % Strip curl progress header lines and decode the JSON payload
            lines = strtrim(strsplit(raw, newline));
            lines = lines(~cellfun(@isempty, lines));
            result = jsondecode(lines{end});
        end

        function cmd = buildCurlRestapiAsk(obj, endstring)
            % Build the curl command string for the given outlet selector
            cmd = sprintf("curl -u %s:%s http://%s/restapi/%s", ...
                obj.username, obj.password, obj.address, endstring);
        end
    end
end


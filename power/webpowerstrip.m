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
            obj.stopTimer();
            obj.Connected = false;
            obj.lastRead = obj.lastRead*nan;
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
                    warning(sprintf('Failed to connect to webpowerstrip:%s',obj.address));
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

        function cmdout = setOn(obj, nOutlet)
            % Build the curl command string for the given outlet selector
            cmdr = sprintf('curl -u %s:%s  -X PUT -H "X-CSRF: x" --data "value=true" "http://%s/restapi/relay/outlets/=%d/state/"', ...
                obj.username, obj.password, obj.address, nOutlet);
            [status,cmdout] = system(cmdr);
            cmdout = obj.parseCurlOutput(cmdout);
        end

        function cmdout = setOff(obj, nOutlet)
            % Build the curl command string for the given outlet selector
            cmdr = sprintf('curl -u %s:%s  -X PUT -H "X-CSRF: x" --data "value=false" "http://%s/restapi/relay/outlets/=%d/state/"', ...
                obj.username, obj.password, obj.address, nOutlet);
            [status,cmdout] = system(cmdr);
            cmdout = obj.parseCurlOutput(cmdout);
        end
    end

    methods (Access = private)
        function result = parseCurlOutput(~, raw)
            % Strip curl progress header lines and decode the JSON payload.
            % If no data was returned (e.g. successful PUT with no body), return [].
            lines = strtrim(strsplit(raw, newline));
            lines = lines(~cellfun(@isempty, lines));
            try
                result = jsondecode(lines{end});
            catch
                result = [];
            end
        end

        function cmd = buildCurlRestapiAsk(obj, endstring)
            % Build the curl command string for the given outlet selector
            cmd = sprintf("curl -u %s:%s http://%s/restapi/%s", ...
                obj.username, obj.password, obj.address, endstring);
        end
    end
end


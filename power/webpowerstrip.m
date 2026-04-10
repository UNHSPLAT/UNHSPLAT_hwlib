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
        readListen
    end
    
    methods
        function obj = webpowerstrip(Address,varargin)
            % Initialize control
            if nargin < 1; Address = ''; end
            % Call parent constructor
            obj@hwDevice(varargin{:});
            
            obj.Connected = false;
            obj.lastRead = ones(8,1)*nan;

            obj.address = Address;

            function state = reader(x)
                state = x.checkState();
            end

            obj.readFunc = @reader;
        end
        
        function disconnectDevice(obj)
            obj.stopTimer();
            obj.Connected = false;
            obj.lastRead = obj.lastRead*nan;
        end

        function connectDevice(obj)
            if ~ obj.Connected

                if isempty(obj.username) || isempty(obj.password)
                    obj.logon();
                    if isempty(obj.username) || isempty(obj.password)
                        warning('webpowerstrip:noCredentials', ...
                            'Connection aborted: no credentials provided for %s', obj.address);
                        return
                    end
                end

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

        function startCollect(obj)
            obj.readListen = addlistener(obj,'lastRead','PostSet',@obj.readState);
            obj.readListen.Recursive = true;
            obj.readState()
        end

        function stopCollect(obj)
            obj.readListen.Enabled = false;
            delete(obj.readListen);
        end
            
        function readState(obj,~,~)
            if obj.Connected
                display(datetime('now'));
                pause(4);
                drawnow();
                obj.read();
            else
                display('pass');
            end

        end

        function cmdout = checkState(obj,nOutlet)
            arguments
                obj
                nOutlet = 'all'
            end

            if strcmp(nOutlet,'all')
                cout = 'all;';
            elseif isnumeric(nOutlet)
                cout = sprintf('=%d',nOutlet);
            end
            cmdr = obj.buildCurlRestapiAsk(sprintf(...
                'relay/outlets/%s/state/%s', cout));

            [status,cmdout] = system(cmdr);
            if status == 0
                cmdout = obj.parseCurlOutput(cmdout);
                if length(cmdout) ~= 8
                    cmdout = ones(8,1)*nan;
                end

            end
        end

        function cmdout = checkTransientState(obj,nOutlet)
            arguments
                obj
                nOutlet = 'all'
            end

            if strcmp(nOutlet,'all')
                cout = 'all;';
            elseif isnumeric(nOutlet)
                cout = sprintf('=%d',nOutlet);
            end
            cmdr = obj.buildCurlRestapiAsk(sprintf(...
                'relay/outlets/%s/transient_state/%s', cout));

            [status,cmdout] = system(cmdr);
            if status == 0
                cmdout = obj.parseCurlOutput(cmdout);
                if length(cmdout) ~= 8
                    cmdout = ones(8,1)*nan;
                end

            end
        end

        function setOn(obj, nOutlet)
            cmdOutlet = nOutlet-1;
            cmdr = sprintf('curl -u %s:%s  -X PUT -H "X-CSRF: x" --data "value=true" "http://%s/restapi/relay/outlets/=%d/state/"', ...
                obj.username, obj.password, obj.address, cmdOutlet);
            [status, cmdout] = system(cmdr);
            obj.checkCurlError(status, cmdout, nOutlet, 'setOn');
        end

        function setOff(obj, nOutlet)
            cmdOutlet = nOutlet-1;
            cmdr = sprintf('curl -u %s:%s  -X PUT -H "X-CSRF: x" --data "value=false" "http://%s/restapi/relay/outlets/=%d/state/"', ...
                obj.username, obj.password, obj.address, cmdOutlet);
            [status, cmdout] = system(cmdr);
            obj.checkCurlError(status, cmdout, nOutlet, 'setOff');
        end

        function logon(obj)
            % Prompt the user for credentials via a dialog box
            answer = inputdlg({'Username', 'Password'}, ...
                sprintf('Log on to webpowerstrip (%s)', obj.address), ...
                [1 40; 1 40], {obj.username, obj.password});
            if isempty(answer)
                return  % user cancelled
            end
            obj.username = answer{1};
            obj.password = answer{2};
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

        function checkCurlError(obj, status, raw, nOutlet, caller)
            % Warn if curl returned a non-zero exit code or a JSON error payload
            if status ~= 0
                warning('webpowerstrip:%s: curl failed (exit code %d) for outlet %d on %s', ...
                    caller, status, nOutlet, obj.address);
                return
            end
            response = obj.parseCurlOutput(raw);
            if ~isempty(response)
                warning('webpowerstrip:%s: unexpected response for outlet %d on %s: %s', ...
                    caller, nOutlet, obj.address, jsonencode(response));
            end
        end
    end
end


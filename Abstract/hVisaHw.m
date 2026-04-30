classdef hVisaHw < hwDevice
    %HVISAHW Abstract class for VISA-based hardware devices
    %   Provides VISA communication functionality for devices connected via
    %   GPIB, TCPIP, USB, or Serial protocols

    properties (SetAccess = private)
        Address string % Device address in VISA format (i.e. GPIB0::4::INSTR, TCPIP0::169.254.2.20::inst0::INSTR, etc.)
    end

    properties (SetAccess = protected)
        hVisa % Handle to MATLAB visa object
    end

    properties (SetObservable)
        Protocol string % Device protocol (i.e. gpib, tcpip, usb, etc.)
        dataOut % Data output from async operations
    end

    methods
        function obj = hVisaHw(address, varargin)
            %HVISAHW Construct an instance of this class
            %   address: Device address (numeric, string, or VISA format)
            %   varargin: Name-value pairs for hwDevice properties
            if nargin < 1; address = ''; end
            
            % Call superclass constructor
            obj@hwDevice(varargin{:});
            
            % Format and store the address
            if isnumeric(address)
                obj.Protocol = "gpib";
                obj.Address = "GPIB0::" + num2str(address) + "::INSTR";
            elseif ischar(address) || isstring(address)
                if ~isnan(str2double(address))
                    obj.Protocol = "gpib";
                    obj.Address = "GPIB0::" + address + "::INSTR";
                elseif regexp(address, 'GPIB')
                    obj.Protocol = "gpib";
                    obj.Address = string(address);
                elseif regexp(address, 'TCPIP')
                    obj.Protocol = "tcpip";
                    obj.Address = string(address);
                elseif regexp(address, 'USB')
                    obj.Protocol = "usb";
                    obj.Address = string(address);
                elseif regexp(address, 'ASRL')
                    obj.Protocol = "serial";
                    obj.Address = string(address);
                else
                    error("hVisaHw:invalidAddress", "Invalid address! Must be VISA-readable address format...");
                end
            else
                error("hVisaHw:invalidAddress", "Invalid address! Must be VISA-readable address format...");
            end
            % Initialize instrument object
            if isempty(obj.hVisa)
                obj.hVisa = visa('ni', obj.Address); %#ok<VISA> Recommended visadev code causes comm issues
            end
        end

        function connectDevice(obj, varargin)
            %CONNECTDEVICE Connect to VISA device
            if ~obj.Connected
                try
                    
                    if ~strcmp(obj.hVisa.Status, 'open')
                        fopen(obj.hVisa);
                    end
                    clrdevice(obj.hVisa);
                    fclose(obj.hVisa);

                    obj.Connected = true;
                    obj.funcConfig(obj);
                catch
                    obj.Connected = false;
                    obj.stopTimer();
                end
            end
        end

        function disconnectDevice(obj)
            %DISCONNECTDEVICE Disconnect from VISA device
            if obj.Connected
                obj.stopTimer();
                if ~isempty(obj.hVisa)
                    if strcmp(obj.hVisa.Status, 'open')
                        fclose(obj.hVisa);
                    end
                end
                obj.Connected = false;
            end
        end

        function dataOut = devRW(obj, dataIn)
            %DEVRW Read/Write to VISA device
            %   dataOut = devRW(obj, dataIn) sends dataIn to device and
            %   optionally reads response
            if obj.Connected
                trynum = 0;
                while trynum < 3
                    try
                        if strcmp(obj.hVisa.Status, 'open')
                            deviceAlreadyOpen = true;
                        else
                            deviceAlreadyOpen = false;
                        end

                        if ~deviceAlreadyOpen
                            fopen(obj.hVisa);
                        end

                        if strcmp(obj.hVisa.TransferStatus, 'idle')
                            obj.hVisa.BytesAvailableFcn = @(~,~) nan;
                            fprintf(obj.hVisa, dataIn);

                            if nargout > 0
                                readasync(obj.hVisa);
                                while ~strcmp(obj.hVisa.TransferStatus, 'idle')
                                    pause(0.01);
                                    drawnow;
                                end
                                dataOut = fscanf(obj.hVisa);
                                drawnow;
                            end

                            if strcmp(obj.hVisa.Status, 'open')
                                flushoutput(obj.hVisa);
                                flushinput(obj.hVisa);
                                fclose(obj.hVisa);
                            end
                            return
                        else
                            trynum = trynum + 1;
                            fprintf("%s:communication attempt %d failed, Visa Busy\n", obj.Tag, trynum);
                            pause(.1);
                        end
                    catch
                        trynum = trynum + 1;
                        fprintf("%s:communication attempt %d failed\n", obj.Tag, trynum);
                    end
                end
                obj.Connected = false;
                fclose(obj.hVisa);
                obj.stopTimer();
            end
            dataOut = "nan";
        end

        function devRW_async(obj, dataIn, readFunc)
            %DEVRW_ASYNC Asynchronous read/write to VISA device
            %   devRW_async(obj, dataIn, readFunc) sends dataIn to device
            %   and sets up async read with callback function
            if nargin < 3
                readFunc = @obj.devR_async;
            end

            if obj.Connected
                trynum = 0;
                while trynum < 3
                    try
                        if strcmp(obj.hVisa.Status, 'open')
                            deviceAlreadyOpen = true;
                        else
                            deviceAlreadyOpen = false;
                        end

                        if ~deviceAlreadyOpen
                            fopen(obj.hVisa);
                        end

                        if strcmp(obj.hVisa.TransferStatus, 'idle')
                            obj.hVisa.BytesAvailableFcn = @(~,~) nan;
                            fprintf(obj.hVisa, dataIn);

                            obj.hVisa.BytesAvailableFcn = readFunc;
                            readasync(obj.hVisa);
                            return
                        else
                            pause(.1);
                            fprintf('Device busy\n');
                        end
                    catch
                        trynum = trynum + 1;
                        fprintf("%s:communication attempt %d failed\n", obj.Tag, trynum);
                    end
                end
                obj.Connected = false;
                fclose(obj.hVisa);
                obj.stopTimer();
            end
%             obj.dataOut = "nan";
        end

        function devR_async(obj, ~, ~)
            %DEVR_ASYNC Async read callback function
            obj.dataOut = fscanf(obj.hVisa);
            obj.hVisa.BytesAvailableFcn = @(~,~) nan;
            flushoutput(obj.hVisa);
            flushinput(obj.hVisa);
            fclose(obj.hVisa);
        end

        function delete(obj, ~)
            %DELETE Destructor - cleanup VISA resources
            if ~isempty(obj.hVisa)
                if strcmp(obj.hVisa.Status, 'open')
                    fclose(obj.hVisa);
                end
                delete(obj.hVisa);
            end
            delete@hwDevice(obj);
        end
    end
end

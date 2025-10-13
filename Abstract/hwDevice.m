classdef hwDevice < handle & matlab.mixin.Heterogeneous
    %GPIBDEVICE Abstract class for communicating with various GPIB-connected devices
    %   Detailed explanation goes here

    properties (Abstract, Constant)
        Type string % Device type (i.e. Power Supply, Temperature Controller, etc.)
        ModelNum string % Device model number
    end

    properties (SetAccess = private)
        Address string % Device address in VISA format (i.e. GPIB0::4::INSTR, TCPIP0::169.254.2.20::inst0::INSTR, etc.)
    end

    properties (SetAccess = protected)
        hVisa % Handle to MATLAB visa object
    end

    properties 
        Tag string = "" % User-configurable label for device
        funcConfig %
    end

    properties (SetObservable) 
        Connected = false %connection status of hwDevice
        readFunc = @(x) nan%
        lastRead %
        refreshRate = 4 %
        Timer = timer
        Protocol string % Device protocol (i.e. gpib, tcpip, usb, etc.)
        dataOut
        read_delay = nan
    end

    methods
        function obj = hwDevice(address,funcConfig)
            %GPIBDEVICE Construct an instance of this class
            %   Detailed explanation goes here
            
            obj.funcConfig = funcConfig;
            %format and store the address
            if isnumeric(address)
                obj.Protocol = "gpib";
                obj.Address = "GPIB0::"+num2str(address)+"::INSTR";
            elseif ischar(address) || isstring(address)
                if ~isnan(str2double(address))
                    obj.Protocol = "gpib";
                    obj.Address = "GPIB0::"+address+"::INSTR";
                    % elseif length(regexp(address,'\.')) == 3
                elseif regexp(address,'GPIB')
                    obj.Protocol = "gpib";
                    obj.Address = string(address);
                elseif regexp(address,'TCPIP')
                    obj.Protocol = "tcpip";
                    obj.Address = string(address);
                elseif regexp(address,'USB')
                    obj.Protocol = "usb";
                    obj.Address = string(address);
                elseif regexp(address,'ASRL')
                    obj.Protocol = "serial";
                    obj.Address = string(address);
                else
                    error("hwDevice:invalidAddress","Invalid address! Must be VISA-readable address format...");
                end
            else
                error("hwDevice:invalidAddress","Invalid address! Must be VISA-readable address format...");
            end  

            obj.initTimer();
            obj.connectDevice();
        end

        function connectDevice(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if ~obj.Connected     
                try
                    % Initialize instrument object
                    if isempty(obj.hVisa)
                        obj.hVisa = visa('ni',obj.Address); %#ok<VISA> Recommended visadev code causes comm issues
                    end
                    if ~strcmp(obj.hVisa.Status,'open')
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

        function dataOut = devRW(obj,dataIn)
            if obj.Connected
                trynum = 0;
                while trynum <3
                    try
                      if strcmp(obj.hVisa.Status,'open')
                          deviceAlreadyOpen = true;
                      else
                          deviceAlreadyOpen = false;
                      end
    
                      if ~deviceAlreadyOpen
                          fopen(obj.hVisa);
                      end

                      if strcmp(obj.hVisa.TransferStatus,'idle')
                          obj.hVisa.BytesAvailableFcn =@(~,~) nan;
                          fprintf(obj.hVisa,dataIn);
        
                          if nargout > 0
                              readasync(obj.hVisa);
                              while ~strcmp(obj.hVisa.TransferStatus,'idle')
                                  pause(0.1);
                                  drawnow;
                              end
                              dataOut = fscanf(obj.hVisa);
                              drawnow;
                          end
        
                          if strcmp(obj.hVisa.Status,'open')
                              flushoutput(obj.hVisa);
                              flushinput(obj.hVisa);
                              fclose(obj.hVisa);
                          end
                          return
                      else
                          trynum = trynum+1;
                          fprintf("%s:communication attempt %d failed, Visa Busy\n",obj.Tag,trynum);
                          pause(.1);
                      end
                    catch
                        trynum = trynum+1;
                        fprintf("%s:communication attempt %d failed\n",obj.Tag,trynum);
                    end
                end
                obj.Connected = false;
                fclose(obj.hVisa);
                obj.stopTimer();
            end
            dataOut = "nan";
        end
        
        function devRW_async(obj,dataIn,readFunc)
            if nargin < 3
                readFunc = @obj.devR_async;
            end
            
            if obj.Connected
                trynum = 0;
                while trynum <3
                    try
                      if strcmp(obj.hVisa.Status,'open')
                          deviceAlreadyOpen = true;
                      else
                          deviceAlreadyOpen = false;
                      end
    
                      if ~deviceAlreadyOpen
                          fopen(obj.hVisa);
                      end

                      if strcmp(obj.hVisa.TransferStatus,'idle')
                            fprintf(obj.hVisa,dataIn);

                            obj.hVisa.BytesAvailableFcn = readFunc;
                            readasync(obj.hVisa);
                        return
                      else
                        pause(.1);
                        fprintf('Device busy\n');
                      end
                    catch
                        trynum = trynum+1;
                        fprintf("%s:communication attempt %d failed\n",obj.Tag,trynum);
                    end
                end
                obj.Connected = false;
                fclose(obj.hVisa);
                obj.stopTimer();
            end
            obj.dataOut = "nan";
        end

        function devR_async(obj,~,~)
            obj.dataOut = fscanf(obj.hVisa);
            obj.hVisa.BytesAvailableFcn = @(~,~) nan;
            flushoutput(obj.hVisa);
            flushinput(obj.hVisa);
            fclose(obj.hVisa);
        end

        function read(obj,~,~) 
            if obj.Connected
                tic;
                % execute read function, assign output to lastRead if output exists
                if nargout(obj.readFunc)>0
                    obj.lastRead = obj.readFunc(obj);
                else
                    obj.readFunc(obj);
                end
                drawnow;
                obj.read_delay = toc;
            else
                obj.lastRead = obj.lastRead*nan;
                obj.read_delay = nan;
            end
        end

        function delete(obj,~)
            if strcmp(obj.hVisa.Status,'open')
                fclose(obj.hVisa);
            end
            if ~isempty(obj.hVisa)
                delete(obj.hVisa);
            end
            obj.stopTimer();
            delete(obj.Timer);
        end
        
        function initTimer(obj)
            obj.Timer = timer('Period',obj.refreshRate,... %period
                                      'ExecutionMode','fixedSpacing',... %{singleShot,fixedRate,fixedSpacing,fixedDelay}
                                      'BusyMode','drop',... %{drop, error, queue}       
                                      'StartDelay',0,...
                                      'TimerFcn',@obj.read...
                                      );
        end

        function restartTimer(obj)
            %RESTARTTIMER Restarts timer if error

            % Stop timer if still running
            if strcmp(obj.Timer.Running,'on')
                stop(obj.Timer);
            end

            % Restart timer
            if obj.Connected
                start(obj.Timer);
            end
        end

        function stopTimer(obj)
            % Stop timer if still running
            if strcmp(obj.Timer.Running,'on')
                stop(obj.Timer);
            end
        end
        
    end
end


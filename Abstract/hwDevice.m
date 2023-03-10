classdef hwDevice < handle & matlab.mixin.Heterogeneous
    %GPIBDEVICE Abstract class for communicating with various GPIB-connected devices
    %   Detailed explanation goes here

    properties (Abstract, Constant)
        Type string % Device type (i.e. Power Supply, Temperature Controller, etc.)
        ModelNum string % Device model number
    end

    properties (SetAccess = private)
        Address string % Device address in VISA format (i.e. GPIB0::4::INSTR, TCPIP0::169.254.2.20::inst0::INSTR, etc.)
        Protocol string % Device protocol (i.e. gpib, tcpip, usb, etc.)
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
            obj.connectDevice();
        end

        function connectDevice(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if ~obj.Connected     
                try
                    % Initialize instrument object
                    obj.hVisa = visa('ni',obj.Address); %#ok<VISA> Recommended visadev code causes comm issues
                    obj.Connected = true;
%                     pause(1)
                    obj.funcConfig(obj);
                catch
                    obj.Connected = false;
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
    
                      fprintf(obj.hVisa,dataIn);
    
                      if nargout > 0
                          readasync(obj.hVisa);
                          while ~strcmp(obj.hVisa.TransferStatus,'idle')
                              pause(0.1);
                          end
                          dataOut = fscanf(obj.hVisa);
                      end
    
                      if ~deviceAlreadyOpen
                          fclose(obj.hVisa);
                      end
                      return
                    catch
                        trynum = trynum+1;
                        fprintf("%s:communication attempt %d failed\n",obj.Tag,trynum);
                    end
                end
                obj.Connected = false;
                fclose(obj.hVisa);
            end
            dataOut = "nan";
        end

        function delete(obj)
                if strcmp(obj.hVisa.Status,'open')
                    fclose(obj.hVisa);
                end
           
        end
    end
end


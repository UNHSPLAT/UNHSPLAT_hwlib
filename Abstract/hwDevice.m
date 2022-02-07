classdef hwDevice < handle & matlab.mixin.Heterogeneous
    %GPIBDEVICE Abstract class for communicating with various GPIB-connected devices
    %   Detailed explanation goes here

    properties (Abstract, Constant)
        Type string % Device type (i.e. Power Supply, Temperature Controller, etc.)
        ModelNum string % Device model number
    end

    properties (SetAccess = protected)
        Address string % Device address in VISA format (i.e. GPIB0::4::INSTR, TCPIP0::169.254.2.20::inst0::INSTR, etc.)
        Protocol string % Device protocol (i.e. gpib, tcpip, usb, etc.)
        hVisa % Handle to MATLAB visa object
    end

    methods
        function obj = hwDevice(address)
            %GPIBDEVICE Construct an instance of this class
            %   Detailed explanation goes here
            obj.connectDevice(address);
        end

        function connectDevice(obj, address)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
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

            % Initialize instrument object
            obj.hVisa = visa('ni', obj.Address); %#ok<VISA> Recommended visadev code causes comm issues

        end

        function dataOut = devRW(obj, dataIn)

              if strcmp(obj.hVisa.Status, 'open')
                  deviceAlreadyOpen = true;
              else
                  deviceAlreadyOpen = false;
              end

              if ~deviceAlreadyOpen
                  fopen(obj.hVisa);
              end

              fprintf(obj.hVisa, dataIn);

              if nargout > 0
                  readasync(obj.hVisa);
                  while ~strcmp(obj.hVisa.TransferStatus, 'idle')
                      pause(0.1);
                  end
                  dataOut = fscanf(obj.hVisa);
              end

              if ~deviceAlreadyOpen
                  fclose(obj.hVisa);
              end

        end

        function delete(obj)

            if strcmp(obj.hVisa.Status, 'open')
                fclose(obj.hVisa);
            end

        end
    end
end


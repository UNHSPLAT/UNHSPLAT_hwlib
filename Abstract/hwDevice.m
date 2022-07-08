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
        Connected = false %connection status of hwDevice
        resourcelist = table([],[],[],[],[],[],...
                        'VariableNames',["ResourceName","Alias","Vendor","Model","SerialNumber","Type"])%
    end

    methods
        function obj = hwDevice(address,varargin)
            %GPIBDEVICE Construct an instance of this class
            %   Detailed explanation goes here

            %assign all properties provided
            if (nargin > 0)
                props = varargin(1:2:numel(varargin));
                vals = varargin(2:2:numel(varargin));
                for i=1:numel(props)
                    obj.(props{i})=vals{i};
                end
            end

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
        end

        function connectDevice(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if any(strcmp(obj.resourcelist.ResourceName,obj.Address))         
                try
                    % Initialize instrument object
                    obj.hVisa = visa('ni',obj.Address); %#ok<VISA> Recommended visadev code causes comm issues
                    obj.Connected = true;
                end
            end
        end

        function dataOut = devRW(obj,dataIn)
            %
            if obj.Connected
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
            else
                dataOut = "nan"
            end
        end

        function delete(obj)

            if strcmp(obj.hVisa.Status,'open')
                fclose(obj.hVisa);
            end

        end
    end
end


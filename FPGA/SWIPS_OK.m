classdef SWIPS_OK < handle

    properties
%         Tag string =""%
        textLabel string = ""% 
        unit string = ""%
        address string = ""%
        asmInfo %
    end

    properties (Constant)
        Type string = "Power Supply"
        ModelNum string = "caen_N1470"
    end

    properties (SetObservable) 
        Timer=timer%
        Connected = false%
        lastRead = struct('rawLCnt',zeros(1,16),'rawUCnt',zeros(1,4),'PPACnt',zeros(1,16))
        funcConfig

        bitfile string   % fpga bit file
        dac_table = ones(1,16); % default DAC table
        okfp % opal kelly object
        acq_time = 0; % '0' for 1 sec acquisition time; '1' for 10 sec    
    end

    methods
        function obj = SWIPS_OK(bitfile,funcConfig)
            arguments
                bitfile string='bitfile_git-0x0f27429b_swips.bit';%
                funcConfig = @(x) x;
            end
            obj.bitfile = bitfile;
            obj.funcConfig = funcConfig;
        end

        function connectDevice(obj)
            if ~obj.Connected
                %% Configuration - Load Library and Open Device
                % load OkLibrary
                if ~libisloaded('okFrontPanel')
                    loadlibrary('okFrontPanel', 'okFrontPanel.h');
                end

                % Construct FrontPanel
                obj.okfp = calllib('okFrontPanel','okFrontPanel_Construct');

                % get device number
                n = calllib('okFrontPanel','okFrontPanel_GetDeviceCount',obj.okfp);

                if n == 0
                    disp('Please Connect Opal Kelly Device')
                    calllib('okFrontPanel','okFrontPanel_Destruct',obj.okfp);
                    obj.Connected = false;
                    return
                elseif n > 1
                    disp('Too Many Opal Kelly Devices Connected')
                    calllib('okFrontPanel','okFrontPanel_Destruct',obj.okfp);
                    obj.Connected = false;
                    return
                end 

                err = calllib('okFrontPanel', 'okFrontPanel_OpenBySerial',obj.okfp,'');
                if ~strcmp(err,'ok_NoError')
                    calllib('okFrontPanel','okFrontPanel_Destruct',obj.okfp);
                    disp('Error Opening FrontPanel Device')
                    
                    obj.Connected = false;
                    return
                end

                % program the device
                err = calllib('okFrontPanel', 'okFrontPanel_ConfigureFPGA', obj.okfp, obj.bitfile);
                if ~strcmp(err,'ok_NoError')
                    calllib('okFrontPanel', 'okFrontPanel_Close',obj.okfp);
                    calllib('okFrontPanel','okFrontPanel_Destruct',obj.okfp);
                    disp('Error Programming FrontPanel Device')
                    
                    obj.Connected = false;
                    return
                end

                %% Code Execution
                % Do things here.
                calllib('okFrontPanel', 'okFrontPanel_UpdateWireOuts', obj.okfp);

                git = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', obj.okfp, hex2dec('20'));
                disp(['Git Hash: 0x',dec2hex(git,8)])
                obj.Connected = true;

                obj.funcConfig(obj);
            end
        end

        function connect(obj)
            obj.funcConfig(obj);
            % obj.Timer = timer('ExecutionMode','fixedRate',...
            %                     'Period',1,...
            %                     'TimerFcn',@(~,~) obj.readData());
            % start(obj.Timer);
        end

        function delete(obj)
            if obj.Connected
                stop(obj.Timer);
                delete(obj.Timer);
                
                calllib('okFrontPanel', 'okFrontPanel_Close',obj.okfp);
                calllib('okFrontPanel','okFrontPanel_Destruct',obj.okfp);
            end
        end

        function congigurePPA_ok(obj, dac_table)

            if obj.Connected
                obj.dac_table = dac_table;
                configurePPA_ok(obj.okfp, dac_table, obj.acq_time); % 1 for 10 sec acquisition time
            end
        end

        function readData(obj)
            if obj.Connected
                stuff = acquirePPA_ok(obj.okfp,obj.acq_time);
                
                obj.lastRead('rawLCnt') = stuff(1);
                obj.lastRead('rawUCnt') = stuff(2);
                obj.lastRead('PPACnt') = stuff(3);
            else
                obj.read_nan();
            end
        end

        function read_nan(obj);
            obj.lastRead.rawLCnt = obj.lastRead.rawLCnt*nan;
            obj.lastRead.rawUCnt = obj.lastRead.rawUCnt*nan;
            obj.lastRead.PPACnt = obj.lastRead.PPACnt*nan;
        end
    end
end

function [rawCntFinal, ppaCntFinal] = findThreshold_ok(bitfile,acq_time,dac_table)

%% Parameter configuration
% bitfile = 'bitfile_git-0x0f27429b_swips.bit';   % fpga bit file

% acq_time = 1;       % '1' for 10 sec acquisition time; '0' for 1 sec
%dac_table = [99 82 78 80 80 70 68 71 95 99 103 103 98 90 80 90];
% dac_table = ones(1,16);

%% Output
filename = 'TRL6_Threshold_DarkCount.xlsx';     % output file name
rawCntFinal = 0:15;
ppaCntFinal = 0:15;



% Create XLS sheets
writematrix(0:15, filename, 'Sheet', 'rawCnt');
writematrix(0:15, filename, 'Sheet', 'ppaCnt');

% Set DAC values


% TODO: Add actual processing
for i = 60:70
    configurePPA_ok(okfp, i*dac_table, acq_time);         % DAC table ... all 60s; 10 sec acquisition time
    
    [rawCnt, ppaCnt] = acquirePPA_ok(okfp,acq_time);
    
    rawCntFinal = [rawCntFinal; rawCnt];
    ppaCntFinal = [ppaCntFinal; ppaCnt];

    writematrix(rawCnt,filename, 'Sheet', 'rawCnt', 'WriteMode','append');
    writematrix(ppaCnt,filename, 'Sheet', 'ppaCnt', 'WriteMode','append');

end

%% Cleanup and close

% It's polite to clean up after yourself
calllib('okFrontPanel', 'okFrontPanel_Close',okfp);
calllib('okFrontPanel','okFrontPanel_Destruct',okfp);
end

function [rawLCnt, rawUCnt, ppaCnt] = acquirePPA_ok(okfp,acq_time)
    % acquirePPA_ok - Rev 0, SXL, 8/13/2025
    %  "okfp": opal kelly object
    %  "acq_time": int where '0' correspond to 1 sec acquisition time and '1' to
    %  10 sec
    %  "rawLCnt": 16x1 double holding the values of the raw count; note that
    %  Anode 0,7,8,15 are 32 bit while the others are 16 bit
    %  "rawUCnt": 4x1 double holding the values of the raw count; they
    %  correspond to Anode 0,7,8,15; all values are 32 bit
    %  "ppACnt": 16x1 double holding the values of the ppa count (divided by 2); 
    %  all values are 32 bit
    rawLCnt = zeros(1,16);      % empty array for raw count (for low threshold)
    rawUCnt = zeros(1,4);       % empty array for raw count (for high threshold)
    ppaCnt = zeros(1,16);       % empty array for ppa count

    % Clear Counters

    calllib('okFrontPanel', 'okFrontPanel_ActivateTriggerIn', okfp, hex2dec('41'), 2);  % Clear PPA Counters
    calllib('okFrontPanel', 'okFrontPanel_ActivateTriggerIn', okfp, hex2dec('41'), 3);  % Clear Upper Raw Counters
    calllib('okFrontPanel', 'okFrontPanel_ActivateTriggerIn', okfp, hex2dec('41'), 4);  % Clear Lower Raw Counters
    
    calllib('okFrontPanel', 'okFrontPanel_ActivateTriggerIn', okfp, hex2dec('41'), 0);  % Start Acquisition
    
   
    % '0' is 1 sec acquisition time; '1' is 10 sec (with an extra 1 sec for a little wiggle room)
    if(acq_time == 0)
        pause(1+1);
    elseif(acq_time == 1)
        pause(10+1);
    end

    calllib('okFrontPanel', 'okFrontPanel_UpdateWireOuts', okfp);       % get the final wireout (count values)
    
    for i = 0:15

        ppaCnt(i+1) = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', okfp, hex2dec('22')+i);       % PPA map to address x"22" - x"31"
        
        if(i==0) % Anode 0 - raws
            rawLCnt(0+1) = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', okfp, hex2dec('39'));
            rawUCnt(1) = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', okfp, hex2dec('35'));
        elseif(i==7)  % Anode 7 - raws
            rawLCnt(i+1) = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', okfp, hex2dec('38'));
            rawUCnt(2) = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', okfp, hex2dec('34'));
        elseif(i==8)  % Anode 8 - raws
            rawLCnt(i+1) = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', okfp, hex2dec('37'));
            rawUCnt(3) = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', okfp, hex2dec('33'));
        elseif(i==15)  % Anode 15 - raws
            rawLCnt(i+1) = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', okfp, hex2dec('36'));
            rawUCnt(4) = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', okfp, hex2dec('32'));
        else % All other Anodes - raws
            if(i<8) % mapping to the correct address
                raw = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', okfp, hex2dec('3F')-floor((i-1)/2));
            else
                raw = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', okfp, hex2dec('3F')-floor((i-3)/2));
            end

            if(mod(i,2)) % odd # anode (apply mask)
                rawLCnt(i+1) = bitand(raw, hex2dec('ffff'));
            else % even # anode (apply mask)
                rawLCnt(i+1) = bitand(raw, hex2dec('ffff0000')) / 2^16;
            end
        end
    
        %disp(['Anode ' num2str(i) ': ' num2str(rawLCnt(i+1)) ' | ' num2str(ppaCnt(i+1)/2)]);
    end

end

function configurePPA_ok(okfp, DAC_table, acq_time)
    % configurePPA_ok - Rev 0, SXL, 8/13/2025
    %  "okfp": opal kelly object
    %  "DAC_tabl"e: 1x16 double holding the threshold values for Anode0-15 (in
    %  order)
    %  "acq_time": int where '0' correspond to 1 sec acquisition time and '1' to
    %  10 sec
    % Set DAC values
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('02'), uint32(DAC_table(1)  * 2^0),   hex2dec('ff'));          % Lower 0
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('02'), uint32(DAC_table(2)  * 2^8),   hex2dec('ff00'));        % Lower 1
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('02'), uint32(DAC_table(3)  * 2^16),  hex2dec('ff0000'));      % Lower 2
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('02'), uint32(DAC_table(4)  * 2^24),  hex2dec('ff000000'));    % Lower 3
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('03'), uint32(DAC_table(5)  * 2^0),   hex2dec('ff'));          % Lower 4
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('03'), uint32(DAC_table(6)  * 2^8),   hex2dec('ff00'));        % Lower 5
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('03'), uint32(DAC_table(7)  * 2^16),  hex2dec('ff0000'));      % Lower 6
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('03'), uint32(DAC_table(8)  * 2^24),  hex2dec('ff000000'));    % Lower 7
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('04'), uint32(DAC_table(9)  * 2^0),   hex2dec('ff'));          % Lower 8
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('04'), uint32(DAC_table(10) * 2^8),   hex2dec('ff00'));        % Lower 9
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('04'), uint32(DAC_table(11) * 2^16),  hex2dec('ff0000'));      % Lower 10
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('04'), uint32(DAC_table(12) * 2^24),  hex2dec('ff000000'));    % Lower 11
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('05'), uint32(DAC_table(13) * 2^0),   hex2dec('ff'));          % Lower 12
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('05'), uint32(DAC_table(14) * 2^8),   hex2dec('ff00'));        % Lower 13
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('05'), uint32(DAC_table(15) * 2^16),  hex2dec('ff0000'));      % Lower 14
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('05'), uint32(DAC_table(16) * 2^24),  hex2dec('ff000000'));    % Lower 15
    calllib('okFrontPanel', 'okFrontPanel_UpdateWireIns', okfp);

    % Update the DAC values
    calllib('okFrontPanel', 'okFrontPanel_ActivateTriggerIn', okfp, hex2dec('40'), 1);

    % Check DACs updated
    pause(0.5);
    calllib('okFrontPanel', 'okFrontPanel_UpdateTriggerOuts', okfp);
    if calllib('okFrontPanel', 'okFrontPanel_IsTriggered', okfp, hex2dec('60'), 1)
        disp(['DACs updated with ' num2str(max(DAC_table))]);
    else
        disp('DACs did not update :(');
    end
    
    % Set Acquisition Time
    calllib('okFrontPanel', 'okFrontPanel_SetWireInValue', okfp, hex2dec('08'), uint32(acq_time),hex2dec('1'));          % '0' for 1 sec, '1' for 10 sec
    calllib('okFrontPanel', 'okFrontPanel_UpdateWireIns', okfp);

    % Update the PPA trigger
    calllib('okFrontPanel', 'okFrontPanel_ActivateTriggerIn', okfp, hex2dec('40'), 2);
end
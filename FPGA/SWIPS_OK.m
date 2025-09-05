function [rawCntFinal, ppaCntFinal] = findThreshold_ok(filename)

%% Parameter configuration
bitfile = 'bitfile_git-0x0f27429b_swips.bit';   % fpga bit file

acq_time = 1;       % '1' for 10 sec acquisition time; '0' for 1 sec
%dac_table = [99 82 78 80 80 70 68 71 95 99 103 103 98 90 80 90];
dac_table = ones(1,16);

%% Output
filename = 'TRL6_Threshold_DarkCount.xlsx';     % output file name
rawCntFinal = 0:15;
ppaCntFinal = 0:15;

%% Configuration - Load Library and Open Device
% load OkLibrary
if ~libisloaded('okFrontPanel')
    loadlibrary('okFrontPanel', 'okFrontPanel.h');
end

% Construct FrontPanel
okfp = calllib('okFrontPanel','okFrontPanel_Construct');

% get device number
n = calllib('okFrontPanel','okFrontPanel_GetDeviceCount',okfp);

if n == 0
    disp('Please Connect Opal Kelly Device')
    calllib('okFrontPanel','okFrontPanel_Destruct',okfp);
    return
elseif n > 1
    disp('Too Many Opal Kelly Devices Connected')
    calllib('okFrontPanel','okFrontPanel_Destruct',okfp);
    return
end 

err = calllib('okFrontPanel', 'okFrontPanel_OpenBySerial',okfp,'');
if ~strcmp(err,'ok_NoError')
    calllib('okFrontPanel','okFrontPanel_Destruct',okfp);
    disp('Error Opening FrontPanel Device')
    return
end

% program the device
err = calllib('okFrontPanel', 'okFrontPanel_ConfigureFPGA', okfp, bitfile);
if ~strcmp(err,'ok_NoError')
    calllib('okFrontPanel', 'okFrontPanel_Close',okfp);
    calllib('okFrontPanel','okFrontPanel_Destruct',okfp);
    disp('Error Programming FrontPanel Device')
    return
end

%% Code Execution
% Do things here.
calllib('okFrontPanel', 'okFrontPanel_UpdateWireOuts', okfp);

git = calllib('okFrontPanel', 'okFrontPanel_GetWireOutValue', okfp, hex2dec('20'));
disp(['Git Hash: 0x',dec2hex(git,8)])

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
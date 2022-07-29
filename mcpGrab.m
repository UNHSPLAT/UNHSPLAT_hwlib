function mcpGrab(volt,startVolt)

arguments
    volt double
    startVolt double = 0
end


minstep = 50;

if startVolt ~= 0
    startVolt = round(startVolt/minstep)*minstep;
end
if volt > 2400
    errordlg('MCP maximum voltage is 2400!','Invalid input!');
end

mySR = srsSR620("GPIB0::30::INSTR");
myPC = leyboldGraphix3("ASRL8::INSTR");
myPS = bertan225_05R("GPIB0::9::INSTR");
myNS = bertan225_05R("GPIB0::7::INSTR");

rootdir = "C:\Users\145 Acc. Lab\data\McpGrab";
testSequence = num2str(round(now*1e6));
datadir = fullfile(rootdir,testSequence);
if ~exist(datadir,"dir")
    mkdir(datadir);
end
multivolt = startVolt:minstep:volt;
for iV = 1:numel(multivolt)
    myPS.setVSet(multivolt(iV));
    if multivolt(iV) == 1000 || multivolt(iV) == 2000 || multivolt(iV) == 2300
        pause(600);
        answer = questdlg('Check MCP noise and verify you''d like to continue.','Verify MCP Noise','Continue','Cancel','Continue');
        if isempty(answer) || strcmpi(answer,'cancel')
            return
        end
    elseif multivolt(iV) < 1000 && multivolt(iV) > 0
        pause(1);
    elseif multivolt(iV) > 1000 && multivolt(iV) < 2000
        pause(15);
    elseif multivolt(iV) > 2000 && multivolt(iV) < 2400
        pause(20);
    end

    timestamp(iV) = now;
    freq(iV) = mySR.measure;
    [pPos(iV),vPos(iV),iPos(iV)] = myPS.measP;
    [pNeg(iV),vNeg(iV),iNeg(iV)] = myNS.measP;
    pChamber(iV) = myPC.readPressure(2);
    fprintf('MCP freq: %.8e Hz\nMCP+ volt: %.4f V\nMCP- volt: %.4f V\nChamber pressure: %.2e torr\n\n',freq(iV),vPos(iV),vNeg(iV),pChamber(iV));
    save(fullfile(datadir,['readings_',testSequence]),"timestamp","freq","pPos","vPos","iPos","pNeg","vNeg","iNeg","pChamber");
end



end
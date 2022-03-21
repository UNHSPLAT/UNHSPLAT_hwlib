function hardware = initializeInstruments
%INITIALIZEINSTRUMENTS Summary of this function goes here
%   Detailed explanation goes here

iFoundHW = 0;
hardware = hwDevice.empty;

devlist = visadevlist;

for iD = 1:size(devlist,1)
    modelNum = devlist{iD,4};
    switch modelNum
        case "MODEL DAQ6510"
            iFoundHW = iFoundHW+1;
            hardware(iFoundHW) = keithleyDAQ6510(devlist{iD,1});
        case "E36313A"
            iFoundHW = iFoundHW+1;
            hardware(iFoundHW) = keysightE36313A(devlist{iD,1});
        case "PS350"
            iFoundHW = iFoundHW+1;
            hardware(iFoundHW) = srsPS350(devlist{iD,1});
        case "MODEL 6485"
            iFoundHW = iFoundHW+1;
            hardware(iFoundHW) = keithley6485(devlist{iD,1});
    end
end

end


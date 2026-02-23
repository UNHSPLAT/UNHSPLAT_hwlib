function [anode_active,anode_pos, pulseheight] = parse_ph_file(fname)

fid = fopen(fname);

% the data is 32-bit words. OpalKelly pipes send the LSB of the word first.
% so read it out using little endian
data = fread(fid,Inf,'uint32',0,'l'); 

% the format of the PH word is as follows:
%   Bit       31: data valid
%   Bits 30 - 25: unused (0)
%   Bit       24: anode_active
%   Bits 23 - 20: unused (0)
%   Bits 19 - 16: anode position (number)
%   Bits 15 - 14: unused (0)
%   Bits 13 -  0: pulseheight

% we only want to report out the valid data. drop all the rest
idx = bitand(data, 2^31) ~= 0;
pulseheight = bitand(data(idx), 2^14-1);
anode_pos = bitshift(bitand(data(idx),2^20-1), -16);
anode_active = bitshift(bitand(data(idx),2^24), -24);

% cleanup
fclose(fid);


%% Plott
numBins = 20;
edges = 200:50:1600;

histVal = zeros(length(find(anode_pos == mode(anode_pos))),16);

for i=1:16
    indices = find(anode_pos == i);
    if(~isempty(indices))
        histVal(1:length(pulseheight(indices)),i) = pulseheight(indices);
        % histogram(selectedValues, numBins); hold on
    end
end

for i=1:16
   data = histVal(:,i);
   histogram(data(data~=0),'BinWidth',100); hold on;
end
legend({'Anode 1', 'Anode 2', 'Anode 3', 'Anode 4', 'Anode 5', 'Anode 6', 'Anode 7', 'Anode 8', 'Anode 9', 'Anode 10', 'Anode 11', 'Anode 12', 'Anode 13', 'Anode 14', 'Anode 15'});




end
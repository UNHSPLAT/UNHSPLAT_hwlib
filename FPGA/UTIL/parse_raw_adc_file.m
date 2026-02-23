function [adc, oor] = parse_raw_adc_file(fname)

fid = fopen(fname);

% the data is 32-bit words. OpalKelly pipes send the LSB of the word first.
% so read it out using little endian
data = fread(fid,Inf,'uint32',0,'l'); 

% the top bit is the OOR flag, the rest of the word (technically, the lower
% 14 bit) is the adc data
oor = bitshift(data, -31);
adc = bitand(data,2^31-1);

%plot because i'm lazy
figure, hold on
yyaxis left
plot(adc)
ylabel('ADC Reading')
yyaxis right
plot(oor)
ylabel('ADC Out of Range')
title(fname);

% cleanup
fclose(fid);

end
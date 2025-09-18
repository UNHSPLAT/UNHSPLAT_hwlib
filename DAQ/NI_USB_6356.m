daqreset;

d = daqlist("ni");

% Create DAQ session
s = daq('ni');

% Add analog input channel (Device ID may vary: check NI MAX for "Dev1")
ai = addinput(s, 'Dev1', 'ai6', 'Voltage');
% a_pulse = addinput(s, 'Dev1', 'ctr0','PulseWidth');

% Configure
ai.Range = [-10 10];     % Voltage range in volts
s.Rate = 10;          % Sample rate in Hz
% s.DurationInSeconds = 1; % Duration

% s.ScansAvailableFcn = @(src,evt) fprintf('Received %d scans\n',evt.Data);
% Start the acquisition
% start(s,"continuous");
% while toc<duration
%     pause(1);
% stop(s);


% Create buffer for data collection
data = [];
timepoints = [];
startTime = datetime('now');
len_time = 1;

i = 0;
tic;
while i < 30
    % Read available data
    display(read(s));
    pause(1);  % Brief pause to prevent excessive CPU usage
    i= i+1;
end

% Stop the acquisition
% stop(s);

% Plot
% plot(time, data);
% xlabel('Time (s)');
% ylabel('Voltage (V)');
% title('USB-6356 AI0 Data');
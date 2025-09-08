classdef caen_hvps < handle

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
        Connected%
        lastRead = [nan,nan,nan,nan];%
        funcConfig

        equip_config_folder string = "" % folder containing config file
        equip_config_filename string = 'config_caenPS.ini'
        hvps_section string = 'HVPS'
        port_key 
        LBus_Address = 2
    end

    methods
        function obj = caen_hvps(address,funcConfig)
            arguments
                address string='';%
                funcConfig = @(x) x;
            end
%             obj@hwDevice(address,funcConfig);
        end

        function con_stat = connectDevice(obj)
            con_stat = HVPS_connect(obj.equip_config_folder, obj.equip_config_filename, obj.hvps_section, obj.port_key);
        end

        function resp = command(obj, command_type, channel, parameter, value)
            % Args:
            %   command_type (char)
            %     CMD : MON, SET
            %   HVPS_Channel (scalar)
            %     CH : 0..4 (4 for the commands related to all Channels)
            %   HVPS_Parameter (char)
            %     PAR : (see parameters tables)
            %   HVPS_Value (scalar or char) or [] to omit
            %     VAL : (numerical value must have a Format compatible with resolution and range) 

            tic;
            cmd = HVPS_command(obj.LBus_Address,command_type, channel, parameter, value);
            resp = send_command_to_HVPS(cmd, obj.equip_config_folder, obj.equip_config_filename, obj.hvps_section);
            display(toc);
        end

        function val = read(obj,~,~)
            % needs update
%             obj.lastRead=obj.getAllPositions();
            val = obj.lastRead;
        end

        function setVSet(obj,chn,volt) %sets the voltage for channel chn (V)
            resp = command(obj,"SET",chn,"VSET",volt);
        end

        function volt = getVSet(obj,chn) %returns value of VSET (voltage setting, not actual monitored voltage) in channels 0-3 (V)
            resp = command(obj,"MON",chn,"VSET",[]);
            dum  = extractNumFromStr(resp);
            if chn == 4 volt = dum(2:5); else volt = dum(2); end;
        end

        function volt = measV(obj,chn) %returns value of VMON (voltage monitor) in channels 0-3 (V)
            resp = command(obj,"MON",chn,"VMON",[]);
            dum  = extractNumFromStr(resp);
            if chn == 4 volt = dum(2:5); else volt = dum(2); end
        end

        function setISet(obj,chn,curr) %sets the trip current threshold (uA)
            resp = command(obj,"SET",chn,"ISET",curr);
        end

        function curr = getISet(obj,chn) %returns value of the trip current threshold values (uA)
            resp = command(obj,"MON",chn,"ISET",[]);
            dum  = extractNumFromStr(resp);
            if chn == 4 curr = dum(2:5); else curr = dum(2); end
        end

        function curr = measI(obj,chn) %returns value of IMON (current monitor) in channels 0-3 (uA)
            resp = command(obj,"MON",chn,"IMON",[]);
            dum  = extractNumFromStr(resp);
            if chn == 4 curr = dum(2:5); else curr = dum(2); end
        end

        function setIMRANGE(obj,chn,range) %sets the range for the current (high or low)
            if range == "HIGH" || range == "LOW"
                resp = command(obj,"SET",chn,"IMRANGE",range);
            else 
                fprintf("Not HIGH or LOW\n"); 
            end
        end

        function range = getIMRANGE(obj) %returns value of the current range for all channels (0 is low, 1 is high)
            resp = command(obj,"MON",4,"IMRANGE",[]);
            first  = extractBetween(resp,"VAL:",";");
            second = extractBetween(resp,first+";",";");
            third  = extractBetween(resp,first+";"+second+";",";");
            fourth  = extractAfter(resp,first+";"+second+";"+third+";");
            range = [0,0,0,0];
            if first  == "HIGH"
                range(1) = 1; end
            if second == "HIGH"
                range(2) = 1; end
            if third  == "HIGH"
                range(3) = 1; end
            if fourth == "HIGH"
                range(4) = 1; end
        end

        function setRUP(obj,chn,curr) %sets the ramp up rate (V)
            resp = command(obj,"SET",chn,"RUP",curr);
        end

        function rup = getRUP(obj,chn) %returns value of the ramp up rate values (V)
            resp = command(obj,"MON",chn,"RUP",[]);
            dum  = extractNumFromStr(resp);
            if chn == 4 rup = dum(2:5); else rup = dum(2); end
        end

        function setRDW(obj,chn,curr) %sets the ramp down rate (V)
            resp = command(obj,"SET",chn,"RDW",curr);
        end

        function rdw = getRDW(obj,chn) %returns value of the ramp down rate (V)
            resp = command(obj,"MON",chn,"RDW",[]);
            dum  = extractNumFromStr(resp);
            if chn == 4 rdw = dum(2:5); else rdw = dum(2); end
        end

        function setON(obj,chn) %sets the channel on
            resp = command(obj,"SET",chn,"ON",[]);
        end

        function setOFF(obj,chn) %sets the channel off
            resp = command(obj,"SET",chn,"OFF",[]);
        end

        function pow = measP(obj,chn) %returns channel status
            resp = command(obj,"MON",chn,"STAT",[]);
            dum  = extractNumFromStr(resp);
            if chn == 4 pow = dum(2:5); else pow = dum(2); end
        end

        function shutdown(obj,~,~)
                stop(obj.Timer);
                obj.Connected = false;
                obj.lastRead = nan*obj.lastRead;
        end

        function restart(obj,~,~)
            obj.shutdown();
            obj.initDevice();
        end
        
        function restartTimer(obj)
            %RESTARTTIMER Restarts timer if error

            % Stop timer if still running
            if strcmp(obj.Timer.Running,'on')
                stop(obj.Timer);
            end

            % Restart timer
            if obj.Connected
                start(obj.Timer);
            end
        end

        function stopTimer(obj)
            % Stop timer if still running
            if strcmp(obj.Timer.Running,'on')
                stop(obj.Timer);
            end
        end

        function delete(obj)
            % Delete the webcam object
            obj.shutdown();
        end

    end
end


function ok = HVPS_connect(equip_config_folder, equip_config_filename, hvps_section, port_key)
% Checks if the HVPS is connected to the port specified in the INI config.
% Args:
%   equip_config_folder (char/string)
%   equip_config_filename (char/string)
%   hvps_section (optional, default 'HVPS')
%   port_key (optional, default 'port')
%
% Returns: logical true/false

if nargin < 3 || isempty(hvps_section), hvps_section = 'HVPS'; end
if nargin < 4 || isempty(port_key),     port_key     = 'port';  end

ok = false;
try
    script_dir = get_script_dir();
    config_path = fullfile(script_dir, equip_config_folder, equip_config_filename);

    cfg = parse_ini(config_path);
    if ~isfield(cfg, hvps_section) || ~isfield(cfg.(hvps_section), port_key)
        fprintf("Error: Could not find '%s' in the '%s' section of '%s'.\n", port_key, hvps_section, equip_config_filename);
        return
    end

    port = cfg.(hvps_section).(port_key);
    % Try opening and immediately closing to verify connectivity
    s = serialport(port, 9600, "Timeout", 1); %#ok<NASGU>
    clear s
    fprintf("Successfully connected to HVPS port: %s (as listed in %s).\n", port, equip_config_filename);
    ok = true;
catch ME
    if strcmpi(ME.identifier, 'MATLAB:serialport:open:cannotOpenPort') || contains(ME.message, 'Failed to open serial port')
        fprintf("Error: Could not open serial port '%s' (as listed in %s). %s\n", port, equip_config_filename, ME.message);
    elseif strcmpi(ME.identifier, 'MATLAB:load:couldNotReadFile') || contains(ME.message, 'No such file')
        fprintf("Error: Configuration file not found at: %s\n", config_path);
    else
        fprintf("An unexpected error occurred while checking HVPS connection: %s\n", ME.message);
    end
end
end

function cmd = HVPS_command(LBus_Address,command_type, HVPS_Channel, HVPS_Parameter, HVPS_Value)
% Constructs the command string for the HVPS (with \r\n terminator).
% Args:
%   command_type (char)
%     CMD : MON, SET
%   HVPS_Channel (scalar)
%     CH : 0..4 (4 for the commands related to all Channels)
%   HVPS_Parameter (char)
%     PAR : (see parameters tables)
%   HVPS_Value (scalar or char) or [] to omit
%     VAL : (numerical value must have a Format compatible with resolution and range) 
%
% Returns: char

if nargin < 4 || isempty(HVPS_Value)
    cmd = sprintf('$BD:%2d,CMD:%s,CH:%d,PAR:%s\r\n',LBus_Address, string(command_type), HVPS_Channel, string(HVPS_Parameter));
else
    cmd = sprintf('$BD:%2d,CMD:%s,CH:%d,PAR:%s,VAL:%s\r\n',LBus_Address, string(command_type), HVPS_Channel, string(HVPS_Parameter), string(HVPS_Value));
end
end

function response_str = send_command_to_HVPS(command, config_folder, config_filename, hvps_section)
% Sends a command to the HVPS, using serial settings from the INI config.
% Args:
%   command (char): full command including \r\n (from HVPS_command)
%   config_folder (char)
%   config_filename (char)
%   hvps_section (optional, default 'HVPS')
%
% Returns:
%   response_str (char) or [] on error

if nargin < 4 || isempty(hvps_section), hvps_section = 'HVPS'; end
response_str = [];

try
    script_dir  = get_script_dir();
    config_path = fullfile(script_dir, config_folder, config_filename);

    cfg = parse_ini(config_path);
    if ~isfield(cfg, hvps_section)
        fprintf("Error: Section '%s' not found in '%s'.\n", hvps_section, config_filename);
        return
    end

    S = cfg.(hvps_section);

    % Match Python keys (including the 'buad_rate' typo)
    port      = get_str(S, 'port', 'COM6');
    baudrate  = get_num(S, 'buad_rate', 9600);
    bytesizeS = get_str(S, 'bytesize', 'EIGHTBITS');  % FIVEBITS..EIGHTBITS
    parityS   = get_str(S, 'parity',   'PARITY_NONE');% PARITY_NONE, _EVEN, _ODD, _MARK, _SPACE
    stopS     = get_str(S, 'stopbits', 'STOPBITS_ONE'); % STOPBITS_ONE, _ONE_POINT_FIVE, _TWO
    xonxoff   = get_bool(S, 'xonxoff', false);
    timeout   = get_num(S, 'timeout', 1);

    % Map to MATLAB serialport parameters
    dataBits = map_bytesize(bytesizeS);      % 5..8
    parity   = map_parity(parityS);          % 'none'|'even'|'odd'|'mark'|'space'
    stopBits = map_stopbits(stopS);          % 1|1.5|2  (MATLAB supports 1, 1.5, 2)
    flow     = ternary(xonxoff, 'software', 'none'); % XON/XOFF -> 'software'

    % Open serial port
    s = serialport(port, baudrate, ...
        "DataBits", dataBits, ...
        "Parity",   parity, ...
        "StopBits", stopBits, ...
        "FlowControl", flow, ...
        "Timeout",  timeout);

    % We expect newline-terminated responses
    configureTerminator(s, "LF");

    % Write EXACTLY what the command contains (already includes \r\n)
    write(s, uint8(command), "uint8");

    % Small pause to mirror Python's time.sleep(0.1)
    pause(0.01);

    % Read one line (until LF)
    resp = readline(s);
    response_str = strtrim(resp);

    % Echo like the Python print
    fprintf("%s  %s\n", command, response_str);

    % Clean up
    clear s

catch ME
    if strcmpi(ME.identifier, 'MATLAB:load:couldNotReadFile') || contains(ME.message, 'No such file')
        fprintf("Error: Configuration file not found.\n");
    elseif contains(ME.identifier, 'serialport')
        fprintf("Serial Error: %s\n", ME.message);
    else
        fprintf("An unexpected error occurred while sending command: %s\n", ME.message);
    end
end
end

% ------------------------ helpers ------------------------

function script_dir = get_script_dir()
% Equivalent to Python's __file__ handling
if isdeployed
    % Deployed apps don't have mfilename paths reliably; fallback to pwd
    script_dir = pwd;
else
    script_dir = fileparts(mfilename('fullpath'));
    if isempty(script_dir), script_dir = pwd; end
end
end

function s = parse_ini(path)
% Minimal INI parser: returns struct with sections and string values.
% Supports lines "key = value" within "[SECTION]".
% Keys are stored as lowercase fieldnames; values kept as raw strings.

if ~isfile(path)
    error('MATLAB:load:couldNotReadFile', 'File not found: %s', path);
end

lines = string(readlines(path, "EmptyLineRule", "skip"));
s = struct();
section = '';

for i = 1:numel(lines)
    line = strtrim(lines(i));
    if line == "" || startsWith(line, ";") || startsWith(line, "#")
        continue
    end
    if startsWith(line, "[") && endsWith(line, "]")
        section = char(strtrim(extractBetween(line, 2, strlength(line)-1)));
        if ~isfield(s, section)
            s.(section) = struct();
        end
    else
        eq = strfind(line, "=");
        if ~isempty(eq) && ~isempty(section)
            key = strtrim(extractBefore(line, eq(1)));
            val = strtrim(extractAfter(line,  eq(1)));
            % keep as raw string; normalize key to lower for convenience
            % but preserve original access in getters
            s.(section).(key) = char(val);
        end
    end
end
end

function v = get_str(S, key, default)
if isfield(S, key), v = string(S.(key)); else, v = string(default); end
end

function v = get_num(S, key, default)
if isfield(S, key)
    v = str2double(string(S.(key)));
    if isnan(v), v = default; end
else
    v = default;
end
end

function v = get_bool(S, key, default)
if isfield(S, key)
    raw = lower(strtrim(string(S.(key))));
    v = any(raw == ["1","true","yes","on"]);
else
    v = logical(default);
end
end

function n = map_bytesize(s)
switch upper(string(s))
    case "FIVEBITS",  n = 5;
    case "SIXBITS",   n = 6;
    case "SEVENBITS", n = 7;
    otherwise,        n = 8; % EIGHTBITS or default
end
end

function p = map_parity(s)
switch upper(string(s))
    case "PARITY_EVEN",  p = 'even';
    case "PARITY_ODD",   p = 'odd';
    case "PARITY_MARK",  p = 'mark';
    case "PARITY_SPACE", p = 'space';
    otherwise,           p = 'none';
end
end

function sb = map_stopbits(s)
switch upper(string(s))
    case "STOPBITS_TWO",            sb = 2;
    case "STOPBITS_ONE_POINT_FIVE", sb = 1.5;
    otherwise,                      sb = 1; % STOPBITS_ONE or default
end
end

function y = ternary(cond, a, b)
if cond, y = a; else, y = b; end
end

function numArray = extractNumFromStr(str)
  str1 = regexprep(str,'[,;=]', ' ');
  str2 = regexprep(regexprep(str1,'[^- 0-9.eE(,)/]',''), ' \D* ',' ');
  str3 = regexprep(str2, {'\.\s','\E\s','\e\s','\s\E','\s\e'},' ');
  numArray = str2num(str3);
end
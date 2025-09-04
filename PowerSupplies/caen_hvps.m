classdef caen_hvps < handle

    properties
        Tag string =""%
        textLabel string = ""% 
        unit string = ""%
        address string = ""%
        asmInfo %
    end

    properties (SetObservable) 
        Timer=timer%
        Connected%
        lastRead%
        funcConfig

        equip_config_folder string = "" % folder containing config file
        equip_config_filename string = 'config_caenPS.ini'
        hvps_section string = 'HVPS'
        port_key 
        
    end

    methods
        function obj = caen_hvps()
            
        end

        function con_stat = connectDevice(obj)
            con_stat = HVPS_connect(obj.equip_config_folder, obj.equip_config_filename, obj.hvps_section, obj.port_key);
        end

        function resp = command(obj, command_type, channel, parameter, value)
            cmd = HVPS_command(command_type, channel, parameter, value);
            resp = send_command_to_HVPS(cmd, obj.equip_config_folder, obj.equip_config_filename, obj.hvps_section);
            % Optionally process resp if needed
        end

        function val = read(obj,~,~)
%             obj.lastRead=obj.getAllPositions();
            val = obj.lastRead;
        end

        function shutdown(obj,~,~)
                if isvalid(obj.myxps)
                    things = obj.myxps.KillAll();
                    obj.myxps.CloseInstrument;
                end
                stop(obj.Timer);
                obj.Connected = false;
                obj.lastRead = nan;
        end

        function run(obj)
            obj.initDevice();
            obj.home();
            start(obj.Timer)
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

function out = hvps(varargin)
% hvps.m
% Convenience shim so the file can be on path even if you only call the
% inner functions directly. This top-level function does nothing.
% Use:
%   ok = HVPS_connect(folder, filename, hvps_section, port_key)
%   cmd = HVPS_command(command_type, channel, parameter, value)
%   resp = send_command_to_HVPS(command, config_folder, config_filename, hvps_section)

out = []; %#ok<NASGU>
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

function cmd = HVPS_command(command_type, HVPS_Channel, HVPS_Parameter, HVPS_Value)
% Constructs the command string for the HVPS (with \r\n terminator).
% Args:
%   command_type (char)
%   HVPS_Channel (scalar)
%   HVPS_Parameter (char)
%   HVPS_Value (scalar or char) or [] to omit
%
% Returns: char

if nargin < 4 || isempty(HVPS_Value)
    cmd = sprintf('$BD:00,CMD:%s,CH:%d,PAR:%s\r\n', string(command_type), HVPS_Channel, string(HVPS_Parameter));
else
    cmd = sprintf('$BD:00,CMD:%s,CH:%d,PAR:%s,VAL:%s\r\n', string(command_type), HVPS_Channel, string(HVPS_Parameter), string(HVPS_Value));
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
    pause(0.10);

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


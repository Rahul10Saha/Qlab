%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  TimeDomain.m
 %
 % Author/Date : Blake Johnson / October 19, 2010
 %
 % Description : A GUI sweeper for homodyneDetection2D.
 %
 % Version: 1.0
 %
 %    Modified    By    Reason
 %    --------    --    ------
 %
 %
 % Copyright 2010 Raytheon BBN Technologies
 %
 % Licensed under the Apache License, Version 2.0 (the "License");
 % you may not use this file except in compliance with the License.
 % You may obtain a copy of the License at
 %
 %     http://www.apache.org/licenses/LICENSE-2.0
 %
 % Unless required by applicable law or agreed to in writing, software
 % distributed under the License is distributed on an "AS IS" BASIS,
 % WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 % See the License for the specific language governing permissions and
 % limitations under the License.
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function status = TimeDomain(cfg_file_name)
% This script will execute a time domain (2D) experiment using the
% default parameters found in the cfg file or specified using the GUI.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%     CLEAR      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% close open instruments
temp = instrfind;
if ~isempty(temp)
    fclose(temp);
    delete(temp)
end
clear temp;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     BASIC INPUTS      %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% base_path is up two levels from this file
[base_path] = fileparts(mfilename('fullpath'));
base_path = parent_dir(base_path, 2);

data_path = [base_path '/experiments/muWaveDetection/data/'];
cfg_path = [base_path '/experiments/muWaveDetection/cfg/'];
basename = 'TimeDomain';

if nargin < 1
	cfg_file_name = [cfg_path 'TimeDomain.cfg'];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%     INITIALIZE PATH     %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%restoredefaultpath
addpath([ base_path '/experiments/muWaveDetection/'],'-END');
addpath([ base_path '/common/src'],'-END');
addpath([ base_path '/experiments/muWaveDetection/src'],'-END');
addpath([ base_path '/common/src/util/'],'-END');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%     CREATE GUI     %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mainWindow = figure( ...
	'Tag', 'figure1', ...
	'Units', 'pixels', ...
	'Position', [25 25 1250 800], ...
	'Name', 'TimeDomain', ...
	'MenuBar', 'none', ...
	'NumberTitle', 'off', ...
	'Color', get(0,'DefaultUicontrolBackgroundColor'), ...
	'Visible', 'off',...
    'KeyPressFcn', @keyPress);

% list of instruments expected in the settings structs
instrumentNames = {'scope', 'RFgen', 'LOgen', 'Specgen', 'Spec2gen', 'Spec3gen', 'TekAWG', 'BBNAPS', 'BBNdc'};
% load previous settings structs
[commonSettings, prevSettings] = get_previous_settings('TimeDomain', cfg_path, instrumentNames);

% add instrument panels
[get_acqiris_settings, set_acqiris_settings] = deviceGUIs.acqiris_settings_gui(mainWindow, 10, 155, prevSettings.InstrParams.scope);

% create tab group for microwave sources
warning('off','MATLAB:uitabgroup:OldVersion');
muWaveTabGroupPanel = uipanel('parent', mainWindow, ...
	'units', 'pixels', 'position', [350, 490, 405, 290]);
muWaveTabGroup = uitabgroup('parent', muWaveTabGroupPanel, ...
	'units', 'pixels', 'position', [2, 2, 400, 285]);
RFtab = uitab('parent', muWaveTabGroup, 'title', 'RF');
LOtab = uitab('parent', muWaveTabGroup, 'title', 'LO');
Spectab = uitab('parent', muWaveTabGroup, 'title', 'Spec');
Spec2tab = uitab('parent', muWaveTabGroup, 'title', 'Spec 2');
Spec3tab = uitab('parent', muWaveTabGroup, 'title', 'Spec 3');

get_rf_settings = deviceGUIs.uW_source_settings_GUI(RFtab, 10, 10, 'RF', prevSettings.InstrParams.RFgen);
get_lo_settings = deviceGUIs.uW_source_settings_GUI(LOtab, 10, 10, 'LO', prevSettings.InstrParams.LOgen);
get_spec_settings = deviceGUIs.uW_source_settings_GUI(Spectab, 10, 10, 'Spec', prevSettings.InstrParams.Specgen);
get_spec2_settings = deviceGUIs.uW_source_settings_GUI(Spec2tab, 10, 10, 'Spec2', prevSettings.InstrParams.Spec2gen);
get_spec3_settings = deviceGUIs.uW_source_settings_GUI(Spec3tab, 10, 10, 'Spec3', prevSettings.InstrParams.Spec3gen);

% add AWGs
AWGPanel = uipanel('parent', mainWindow, ...
	'units', 'pixels', 'position', [350, 235, 405, 260]);
AWGTabGroup = uitabgroup('parent', AWGPanel, ...
	'units', 'pixels', 'position', [2, 2, 400, 255]);
TekTab = uitab('parent', AWGTabGroup, 'title', 'Tek');
APSTab = uitab('parent', AWGTabGroup, 'title', 'APS');

[get_tekAWG_settings, set_tekAWG_GUI] = deviceGUIs.AWG5014_settings_GUI(TekTab, 5, 5, 'TekAWG', prevSettings.InstrParams.TekAWG);
[get_APS_settings, set_APS_settings] = deviceGUIs.APS_settings_GUI(APSTab, 5, 5, 'BBN APS', prevSettings.InstrParams.BBNAPS);

% add DC sources
get_DCsource_settings = deviceGUIs.DCBias_settings_GUI(mainWindow, 240, 775, prevSettings.InstrParams.BBNdc);

% add digital Homodyne
get_digitalHomodyne_settings = digitalHomodyne_GUI(mainWindow, 140, 350, prevSettings.ExpParams.digitalHomodyne);

% add filter settings
get_boxcarFilter_settings = boxcarFilter_GUI(mainWindow, 50, 350, prevSettings.ExpParams.filter);

% add tab group for sweeps
sweepsTabGroupPanel = uipanel('parent', mainWindow, ...
	'units', 'pixels', 'position', [775, 620, 440, 160]);
sweepsTabGroup = uitabgroup('parent', sweepsTabGroupPanel, ...
	'units', 'pixels', 'position', [2, 2, 430, 160]);
FreqAtab = uitab('parent', sweepsTabGroup, 'title', 'Freq A');
Powertab = uitab('parent', sweepsTabGroup, 'title', 'Power');
Phasetab = uitab('parent', sweepsTabGroup, 'title', 'Phase');
DCtab = uitab('parent', sweepsTabGroup, 'title', 'DC');
TekChtab = uitab('parent', sweepsTabGroup, 'title', 'TekCh');
Timetab = uitab('parent', sweepsTabGroup, 'title', 'Time');

get_freqA_settings = sweepGUIs.FrequencySweepGUI(FreqAtab, 5, 2, 'A');
get_power_settings = sweepGUIs.PowerSweepGUI(Powertab, 5, 2, '');
get_phase_settings = sweepGUIs.PhaseSweepGUI(Phasetab, 5, 2, '');
get_dc_settings = sweepGUIs.DCSweepGUI(DCtab, 5, 2, '');
get_tekChannel_settings = sweepGUIs.TekChannelSweepGUI(TekChtab, 5, 2, '');
get_time_settings = sweepGUIs.TimeSweepGUI(Timetab, 5, 2, '');

% add sweep/loop selector
fastLoop = labeledDropDown(mainWindow, [775 550 120 25], 'Fast Loop', ...
	{'frequencyA', 'power', 'phase', 'dc', 'TekCh', 'CrossDriveTuneUp', 'Repeat', 'nothing'});

% add path and file controls
get_path_and_file = path_and_file_controls(mainWindow, [910 525], commonSettings, prevSettings);

% add soft averages control
softAvgs = uicontrol(mainWindow, ...
    'Style', 'edit', ...
    'BackgroundColor', 'white', ...
    'String', '1', ...
    'Position', [775 495 100 25]);

% soft avgs label
uicontrol(mainWindow, 'Style' ,'text', 'String', 'Soft Avgs', 'Position', [775 520 100 25]);

% add check box for scope
scopeButton = uicontrol(mainWindow, ...
    'Style', 'checkbox', ...
    'Units', 'pixels', ...
    'Position', [775 200 25 25]);
% scope box label
uicontrol(mainWindow,...
    'Style', 'text',...
    'HorizontalAlignment', 'left',...
    'Units', 'pixels', ...
    'Position', [800 195 80 25],...
    'String', 'Scope');

% add run button
runHandle = uicontrol(mainWindow, ...
	'Style', 'pushbutton', ...
	'String', 'Run', ...
	'Position', [50 50, 75, 30], ...
	'Callback', {@run_callback});

%Add the experiment quick picker
GUIgetters = containers.Map();
GUIgetters('TekAWG') = get_tekAWG_settings;
GUIgetters('BBNAPS') = get_APS_settings;
GUIgetters('digitizer') = get_acqiris_settings;
GUIsetters = containers.Map();
GUIsetters('TekAWG') = set_tekAWG_GUI;
GUIsetters('BBNAPS') = set_APS_settings;
GUIsetters('digitizer') = set_acqiris_settings;


ExperimentQuickPicker_GUI(mainWindow, 50, 700, GUIgetters, GUIsetters);



% show mainWindow
drawnow;
set(mainWindow, 'Visible', 'on');

% add run callback

	function run_callback(hObject, eventdata)

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%     WRITE CONFIG     %%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		% construct settings cluster
		settings = struct();
		
		% get instrument settings
		settings.InstrParams.scope = get_acqiris_settings();
		settings.InstrParams.RFgen = get_rf_settings();
		settings.InstrParams.LOgen = get_lo_settings();
		settings.InstrParams.Specgen = get_spec_settings();
        settings.InstrParams.Spec2gen = get_spec2_settings();
        settings.InstrParams.Spec3gen = get_spec3_settings();
		settings.InstrParams.TekAWG = get_tekAWG_settings();
        settings.InstrParams.BBNAPS = get_APS_settings();
		settings.InstrParams.BBNdc = get_DCsource_settings();
		
		% get sweep settings
		settings.SweepParams.frequencyA = get_freqA_settings();
		settings.SweepParams.power = get_power_settings();
		settings.SweepParams.phase = get_phase_settings();
		settings.SweepParams.dc = get_dc_settings();
        settings.SweepParams.time = get_time_settings();
        settings.SweepParams.TekCh = get_tekChannel_settings();
        settings.SweepParams.CrossDriveTuneUp = struct('type', 'sweeps.CrossDriveTuneUp');
        settings.SweepParams.Repeat = struct('type', 'sweeps.Repeat', 'stop', 20);
		% add 'nothing' sweep
		settings.SweepParams.nothing = struct('type', 'sweeps.Nothing');
		
        % time is always sweep number 1
        % label fast loop as sweep 2
        settings.SweepParams.time.number = 1;
        if ~strcmp(get_selected(fastLoop), 'Nothing')
            settings.SweepParams.(get_selected(fastLoop)).number = 2;
        end
		
		% get other experiment settings
		settings.ExpParams.digitalHomodyne = get_digitalHomodyne_settings();
        settings.ExpParams.filter = get_boxcarFilter_settings();
        settings.ExpParams.softAvgs = str2double(get(softAvgs, 'String'));
		settings.displayScope = get(scopeButton, 'Value');
		settings.SoftwareDevelopmentMode = 0;
        
        % get file path, counter, device name, and experiment name
        [temppath, counter, deviceName, exptName] = get_path_and_file();
        if ~strcmp(temppath, '')
            data_path = temppath;
        end
        if (~strcmp(exptName, '') && ~strcmp(deviceName, ''))
            basename = [deviceName '_' exptName];
        end
        settings.data_path = data_path;
        settings.deviceName = deviceName;
        settings.exptName = exptName;
        settings.counter = counter.value;
        
        % save settings to specific program cfg file as well as common cfg.
		cfg_file_name = [cfg_path 'TimeDomain.cfg'];
        common_cfg_name = [cfg_path 'common.cfg'];
		writeCfgFromStruct(cfg_file_name, settings);
        writeCfgFromStruct(common_cfg_name, settings);

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%     PREPARE FOR EXPERIMENT      %%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% These methods are inherited from the superclass 'experiment'.  They are
		% generic for all Experiments
		Exp = expManager.homodyneDetection2D(data_path, cfg_file_name, basename, counter.value);
		Exp.parseExpcfgFile;

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%     RUN THE EXPERIMENT      %%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		% Initialize the data file and record the parameters
		Exp.openDataFile;
		Exp.writeDataFileHeader;
        % increment counter
        counter.increment();

		% Run the actual experiment
		Exp.Init;
		Exp.Do;
		Exp.CleanUp;

		% Close the data file and end connection to all insturments.  This is 
		% another method inherited from 'experiment'
		Exp.finalizeData;

		status = 0;
    end

    function keyPress(src, event)
        if strcmp(event.Modifier{1},'control') && strcmp(event.Key,'r')
            run_callback()
        end
    end

end

% find the nth parent of directory given in 'path'
function str = parent_dir(path, n)
	str = path;
	if nargin < 2
		n = 1;
	end
	for j = 1:n
		pos = find(str == filesep, 1, 'last');
		str = str(1:pos-1);
	end
end

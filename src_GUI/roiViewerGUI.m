function varargout = roiViewerGUI(varargin)
% ROIVIEWERGUI MATLAB code for roiViewerGUI.fig
%      ROIVIEWERGUI, by itself, creates a new ROIVIEWERGUI or raises the existing
%      singleton*.
%
%      H = ROIVIEWERGUI returns the handle to a new ROIVIEWERGUI or the handle to
%      the existing singleton*.
%
%      ROIVIEWERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ROIVIEWERGUI.M with the given input arguments.
%
%      ROIVIEWERGUI('Property','Value',...) creates a new ROIVIEWERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before roiViewerGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to roiViewerGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help roiViewerGUI

% Last Modified by GUIDE v2.5 26-Jun-2019 12:25:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @roiViewerGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @roiViewerGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before roiViewerGUI is made visible.
function roiViewerGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% varargin   command line arguments to roiViewerGUI (see VARARGIN)

handles.data = varargin{:};

% xlabel(handles.axes1, 'Frames'); 
% ylabel(handles.axes1, 'Intensity (AU)');

% make axes array to simplify goToROI input
handles.ax_array = [handles.axes1 handles.axes2 handles.axes3];

% init indices
% idx(1) = roi idx, idx(2) = ch idx
handles.idx(1) = 1;
handles.idx(2) = 1;

% init channel names and colors from function
[handles.channel_names, handles.channel_colors] = initChannels(handles.data);
set(handles.popupmenu_channelSelect, 'String', handles.channel_names);

% init disc_input from function
handles.disc_input = initDISC();

% init variables for filter values
handles.filters.enableSNR = 0;
handles.filters.enablenumStates = 0;
handles.filters.snr_min = [];
handles.filters.snr_max = [];
handles.filters.numstates_min = [];
handles.filters.numstates_max = [];

% Choose default command line output for roiViewerGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% This sets up the initial plot - only do when we are invisible
% so window can get raised using roiViewerGUI.
% initial load of ROI 1 at channel 1
if strcmp(get(hObject,'Visible'),'off')
    goToROI(handles.data, handles.idx, handles.ax_array,...
        handles.channel_colors);
    guidata(hObject, handles);
end


% --- Outputs from this function are returned to the command line.
function varargout = roiViewerGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);

% Get default command line output from handles structure
varargout{1} = handles.output;


function menuFile_loadData_Callback(hObject, eventdata, handles, fp)
if ~exist('fp', 'var')
    handles.data = loadData();
else
    handles.data = loadData(fp);
end
handles.idx = [1 1];

[handles.channel_names, handles.channel_colors] = initChannels(handles.data);
% reset channel popup and filter strings
handles.popupmenu_channelSelect.String = handles.channel_names;
handles.popupmenu_channelSelect.Value = 1;
handles.text_snr_filt.String = 'any';
handles.text_numstates_filt.String = 'any';

% recall axes from gui to send to goToROI
guidata(handles.figure_main, handles);
handles.idx = goToROI(handles.data, handles.idx, handles.ax_array,...
    handles.channel_colors);


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% autogenerated and unused, as the file menu calls the custom loadData function
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% loads the standard print dialog
printdlg(handles.figure_main)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% autogenerated and unused, as there is no necessary "close" option in the file menu
selection = questdlg(['Close ' get(handles.figure_main,'Name') '?'],...
                     ['Close ' get(handles.figure_main,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return
end

delete(handles.figure_main)


% --- Executes on selection change in popupmenu_channelSelect.
function popupmenu_channelSelect_Callback(hObject, eventdata, handles)
% changes the channel selected via popup, and remains on the current ROI.
% Supports an arbitrary number of channels

popup_sel_index = get(handles.popupmenu_channelSelect, 'Value');
for ii = 1:size(handles.data.rois,2)
    switch popup_sel_index
        case ii
            handles.idx(2) = ii;
            handles.idx = goToROI(handles.data, handles.idx, handles.ax_array,...
                handles.channel_colors);
            guidata(hObject, handles);
    end
end


% --- Executes during object creation, after setting all properties.
function popupmenu_channelSelect_CreateFcn(hObject, eventdata, handles)
% creates popup and fetches channel names
% Supports an arbitrary number of channels (though colors would need to be
% adapted as such in initChannels)

% create menu with default colors
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
     set(hObject,'BackgroundColor','white');
end

% set popup values based on channel names
%set(hObject, 'String', handles.channel_names);
set(hObject, 'Value', 1);
set(hObject, 'fontsize', 12);
set(hObject, 'fontname', 'arial');


% --- Executes on button press in pushbutton_nextROI.
function pushbutton_nextROI_Callback(hObject, eventdata, handles)
% go to the next ROI, stops at end of channel
handles.idx(1) = handles.idx(1) + 1;
handles.idx = goToROI(handles.data, handles.idx, handles.ax_array,...
    handles.channel_colors);
guidata(hObject, handles);


% --- Executes on button press in pushbutton_prevROI.
function pushbutton_prevROI_Callback(hObject, eventdata, handles)
% go to the previous ROI, stops at 1
handles.idx(1) = handles.idx(1) - 1;
handles.idx = goToROI(handles.data, handles.idx, handles.ax_array,...
    handles.channel_colors);
guidata(hObject, handles);


% --- Executes on button press in pushbutton_customROI.
function pushbutton_customROI_Callback(hObject, eventdata, handles)
% jump to any given ROI via a dialog
handles.idx(1) = -1;
handles.idx = goToROI(handles.data, handles.idx, handles.ax_array,...
    handles.channel_colors);
guidata(hObject, handles);


% --- Executes on button press in pushbutton_analyzeThis.
function pushbutton_analyzeThis_Callback(hObject, eventdata, handles)
% sets condition to run DISC on the current ROI and brings up param dialog
% will also return params, as they may have been changed in the dialog
[handles.data, handles.disc_input] = analyzeFromGUI(handles.data,...
    handles.disc_input, handles.idx, 0);
guidata(hObject, handles); % update gui
% display ROI selected before analysis
handles.idx = goToROI(handles.data, handles.idx, handles.ax_array,...
    handles.channel_colors);


% --- Executes on button press in pushbutton_analyzeAll.
function pushbutton_analyzeAll_Callback(hObject, eventdata, handles)
% sets condition to run DISC on all ROIs and brings up param dialog
% will also return params, as they may have been changed in the dialog
[handles.data, handles.disc_input] = analyzeFromGUI(handles.data,...
    handles.disc_input, handles.idx, 1);
guidata(hObject, handles); % update gui
% display ROI selected before analysis
handles.idx = goToROI(handles.data, handles.idx, handles.ax_array,...
    handles.channel_colors);


% --- Executes on key press with focus on figure_main or any of its controls.
function figure_main_WindowKeyPressFcn(hObject, eventdata, handles)
% handles all key presses as labeled on buttons. easily extended with the
% proper strings
switch eventdata.Key
    case 'rightarrow'
        uicontrol(handles.pushbutton_nextROI)
        pushbutton_nextROI_Callback(handles.pushbutton_nextROI,[],handles)
    case 'leftarrow'
        uicontrol(handles.pushbutton_prevROI)
        pushbutton_prevROI_Callback(handles.pushbutton_prevROI,[],handles)
    case 'uparrow'
        uicontrol(handles.pushbutton_toggleSelect)
        pushbutton_toggleSelect_Callback(handles.pushbutton_toggleSelect,[],handles)
    case 'downarrow'
        uicontrol(handles.pushbutton_toggleDeselect)
        pushbutton_toggleDeselect_Callback(handles.pushbutton_toggleDeselect,[],handles)
    case 'period'
        uicontrol(handles.pushbutton_nextSelected)
        pushbutton_nextSelected_Callback(handles.pushbutton_nextSelected,[],handles)
    case 'comma'
        uicontrol(handles.pushbutton_prevSelected)
        pushbutton_prevSelected_Callback(handles.pushbutton_prevSelected,[],handles)
end


% --- Executes on button press in pushbutton_clearThis.
function pushbutton_clearThis_Callback(hObject, eventdata, handles)
% clears analysis fields for current ROI
handles.data.rois(handles.idx(1), handles.idx(2)).disc_fit = [];
handles.data.rois(handles.idx(1), handles.idx(2)).SNR = [];
guidata(hObject, handles);
handles.idx = goToROI(handles.data, handles.idx, handles.ax_array,...
    handles.channel_colors);

% --- Executes on button press in pushbutton_clearAll.
function pushbutton_clearAll_Callback(hObject, eventdata, handles)
% clears analysis fields for all ROIs
[handles.data.rois(:, handles.idx(2)).disc_fit] = deal([]);
[handles.data.rois(:, handles.idx(2)).SNR] = deal([]);
guidata(hObject, handles);
handles.idx = goToROI(handles.data, handles.idx, handles.ax_array,...
    handles.channel_colors);


% --- Executes on button press in pushbutton_toggleSelect.
function pushbutton_toggleSelect_Callback(hObject, eventdata, handles)
% change "status" field for ROI (and title if necessary)
% change status on all channels
for ii = 1:size(handles.data.rois,2)
    handles.data.rois(handles.idx(1),ii).status = 1;
end
guidata(hObject, handles);

% count # of selected, update trajectory title
numsel = nnz(vertcat(handles.data.rois(:,handles.idx(2)).status)==1);
if handles.data.rois(handles.idx(1), handles.idx(2)).status == 1
    title_txt = sprintf('ROI # %u of %u - Status: Selected  (%u selected)',...
        handles.idx(1), size(handles.data.rois,1), numsel);
elseif handles.data.rois(handles.idx(1), handles.idx(2)).status == 0
    title_txt = sprintf('ROI # %u of %u - Status: Unselected  (%u selected)',...
        handles.idx(1), size(handles.data.rois,1), numsel);
else
    title_txt = sprintf('ROI # %u of %u - Status: null  (%u selected)',...
        handles.idx(1), size(handles.data.rois,1), numsel);
end
title(handles.axes1, title_txt);

% --- Executes on button press in pushbutton_toggleDeselect.
function pushbutton_toggleDeselect_Callback(hObject, eventdata, handles)
% change "status" field for ROI (and title if necessary)
% change status on all channels
for ii = 1:size(handles.data.rois, 2)
    handles.data.rois(handles.idx(1), ii).status = 0;
end
guidata(hObject, handles);

% count # of selected, update trajectory title
numsel = nnz(vertcat(handles.data.rois(:,handles.idx(2)).status)==1);
if handles.data.rois(handles.idx(1), handles.idx(2)).status == 1
    title_txt = sprintf('ROI # %u of %u - Status: Selected  (%u selected)',...
        handles.idx(1), size(handles.data.rois,1), numsel);
elseif handles.data.rois(handles.idx(1), handles.idx(2)).status == 0
    title_txt = sprintf('ROI # %u of %u - Status: Unselected  (%u selected)',...
        handles.idx(1), size(handles.data.rois,1), numsel);
else
    title_txt = sprintf('ROI # %u of %u - Status: null  (%u selected)',...
        handles.idx(1), size(handles.data.rois,1), numsel);
end
title(handles.axes1, title_txt);

% --- Executes on button press in pushbutton_nextSelected.
function pushbutton_nextSelected_Callback(hObject, eventdata, handles)
% finds next ROI with "selected" status and goes to it in the GUI
j = find(vertcat(handles.data.rois(handles.idx(1)+1:end, handles.idx(2)).status) == 1);
if ~isempty(j)
    handles.idx(1) = handles.idx(1) + j(1);
    handles.idx = goToROI(handles.data, handles.idx, handles.ax_array,...
        handles.channel_colors);
    guidata(hObject, handles);
end

% --- Executes on button press in pushbutton_prevSelected.
function pushbutton_prevSelected_Callback(hObject, eventdata, handles)
% finds previous ROI with "selected" status and goes to it in the GUI
j = find(vertcat(handles.data.rois(1:handles.idx(1)-1, handles.idx(2)).status) == 1);
if ~isempty(j)
    handles.idx(1) = j(end);
    handles.idx = goToROI(handles.data, handles.idx, handles.ax_array,...
        handles.channel_colors);
    guidata(hObject, handles);
end

    
% --- Executes on button press in pushbutton_filter.
function pushbutton_filter_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_filter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.filters = traceSelection(handles.filters);

% cancel if continue is not pressed
if ~handles.filters.contpr
    handles.text_snr_filt.String = 'any';
    handles.text_numstates_filt.String = 'any';
    return
end
% if cancel is pressed, no filter will be applied, but the traces from the
% previous filtering will still be selected.

% assign min and max values if entry boxes are left empty
if handles.filters.enableSNR && isempty(handles.filters.snr_max)
    handles.filters.snr_max = Inf;
end
if handles.filters.enableSNR && isempty(handles.filters.snr_min)
    handles.filters.snr_min = -Inf;
end
if handles.filters.enablenumStates && isempty(handles.filters.numstates_max)
    handles.filters.numstates_max = Inf;
end
if handles.filters.enablenumStates && isempty(handles.filters.numstates_min)
    handles.filters.numstates_min = 0;
end
guidata(hObject, handles);

[handles.data.rois.status] = deal(0); % clear any existing selections

% sort by SNR only
if handles.filters.snrEnable && ~handles.filters.numstatesEnable
    % change corresponding text in GUI
    handles.text_snr_filt.String = sprintf('%.1f → %.1f',...
        handles.filters.snr_min, handles.filters.snr_max);
    handles.text_numstates_filt.String = 'any';
    % adjust trace status if parameters are met
    handles.data = computeSNR(handles.data, handles.idx(2), 0); % fill field in data struct    
    for ii = 1:size(handles.data.rois, 1)
        if ~isempty(handles.data.rois(ii,handles.idx(2)).SNR)
            trace_snr = handles.data.rois(ii,handles.idx(2)).SNR;
            if trace_snr <= handles.filters.snr_max && ...
                    trace_snr >= handles.filters.snr_min
                for jj = 1:size(handles.data.rois,2)
                    handles.data.rois(ii,jj).status = 1;
                end
            end
        end
    end
% sort by # of states only
elseif handles.filters.numstatesEnable && ~handles.filters.snrEnable
    % change corresponding text in GUI
    handles.text_numstates_filt.String = sprintf('%.0f → %.0f',...
        handles.filters.numstates_min, handles.filters.numstates_max);
    handles.text_snr_filt.String = 'any';
    % adjust trace status if parameters are met
    for ii = 1:size(handles.data.rois, 1)
        if ~isempty(handles.data.rois(ii,handles.idx(2)).disc_fit)
            n_components = size(handles.data.rois(ii,handles.idx(2)).disc_fit.components, 1);
            if n_components <= round(handles.filters.numstates_max) && ...
                    n_components >= round(handles.filters.numstates_min)
                for jj = 1:size(handles.data.rois,2)
                    handles.data.rois(ii,jj).status = 1;
                end
            end
        end
    end
% sort by SNR and # of states
elseif handles.filters.numstatesEnable && handles.filters.snrEnable
    % change corresponding text in GUI
    handles.text_snr_filt.String = sprintf('%.1f → %.1f',...
        handles.filters.snr_min, handles.filters.snr_max);
    handles.text_numstates_filt.String = sprintf('%.0f → %.0f',...
        handles.filters.numstates_min, handles.filters.numstates_max);
    % adjust trace status if parameters are met
    handles.data = computeSNR(handles.data, handles.idx(2), 0);
    for ii = 1:size(handles.data.rois, 1)
        if ~isempty(handles.data.rois(ii, handles.idx(2)).disc_fit)
            n_components = size(handles.data.rois(ii,handles.idx(2)).disc_fit.components, 1);
            trace_snr = handles.data.rois(ii, handles.idx(2)).SNR;
            if n_components <= round(handles.filters.numstates_max) && ...
                    n_components >= round(handles.filters.numstates_min) && ...
                    trace_snr <= handles.filters.snr_max && ...
                    trace_snr >= handles.filters.snr_min
                for jj = 1:size(handles.data.rois,2)
                    handles.data.rois(ii,jj).status = 1;
                end
            end
        end
    end
end
guidata(hObject, handles);
% redraw titles
handles.idx = goToROI(handles.data, handles.idx, handles.ax_array,...
    handles.channel_colors);

function menuPlots_dwellAnalysis_Callback(hObject, eventdata, handles)
getDwellTimes(handles.data, handles.idx(2));

function menuPlots_numStatesHist_Callback(hObject, eventdata, handles)
numStatesHist(handles.data, handles.idx(2), 1);

function menuPlots_snrHist_Callback(hObject, eventdata, handles)
handles.data = computeSNR(handles.data, handles.idx(2), 1);
guidata(hObject, handles);

function menuFile_exportFigs_Callback(hObject, eventdata, handles)
exportFigs(handles.data, handles.idx, handles.channel_colors);

function menuFile_exportDat_Callback(hObject, eventdata, handles)
exportText(handles.data, handles.idx(2));

function menuFile_saveData_Callback(hObject, eventdata, handles)
saveData(handles.data);

function menuFile_expRelSel_Callback(hObject, eventdata, handles)
saveData(handles.data, 1, hObject);

% unused
function menuFile_Callback(~, ~, ~)
function menuPlots_Callback(~, ~, ~)
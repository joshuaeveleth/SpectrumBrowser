function varargout = RadarOccupancy(varargin)
% RADAROCCUPANCY MATLAB code for RadarOccupancy.fig
%      RADAROCCUPANCY, by itself, creates a new RADAROCCUPANCY or raises the existing
%      singleton*.
%
%      H = RADAROCCUPANCY returns the handle to a new RADAROCCUPANCY or the handle to
%      the existing singleton*.
%
%      RADAROCCUPANCY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RADAROCCUPANCY.M with the given input arguments.
%
%      RADAROCCUPANCY('Property','Value',...) creates a new RADAROCCUPANCY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RadarOccupancy_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RadarOccupancy_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RadarOccupancy

% Last Modified by GUIDE v2.5 17-Feb-2015 13:15:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @RadarOccupancy_OpeningFcn, ...
    'gui_OutputFcn',  @RadarOccupancy_OutputFcn, ...
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


% --- Executes just before RadarOccupancy is made visible.
function RadarOccupancy_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RadarOccupancy (see VARARGIN)

% Choose default command line output for RadarOccupancy
handles.output = hObject;

% Asks user for the location of the initialization file
[FileName,~] = uigetfile('*.json','Select the JSON code file');
if isequal(FileName,0)
    delete(handles.figure1);
else
    try
        % Initialize parameters from init.json
        [ Loc, Out, IP, Model] = ReadInitFile(FileName);
        set(handles.edtFileNum, 'String', ['#### (' int2str(Out.StartFileNum) ')']);
        %set(handles.edtComment, 'String', Comment);
        
        % Hardware certain fields in the Sys and Loc structures
        set(handles.popBand, 'Value', 1); 
        handles = InitSystemStruct(handles, Loc, Model); 
        UpdateGuiFields(handles, Out, Loc); UpdateGuiEdits(handles);

        handles.LMeasure = Loc; handles.OMeasure = Out;
        handles.WMeasure = IP; handles.MMeasure = Model; setappdata(handles.figure1, 'state', 1);
        
        if length(cellstr(get(handles.popBand,'String'))) == 1
            set(handles.popBand,'Enable','off');
        end
        
        guidata(hObject, handles);
    catch
        quest = questdlg('The selected file was incompatible. Would you like to try again?','File Error','Yes','No','Yes');
        
        if isempty(quest)
            delete(handles.figure1);
        end
        
        switch quest
            case 'Yes'
                delete(handles.figure1)
                SensorCode
            otherwise
                delete(handles.figure1)
        end
    end
end


% --- Outputs from this function are returned to the command line.
function varargout = RadarOccupancy_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isempty(handles)
    varargout{1} = {''};
else
    varargout{1} = handles.output;
end


% --- Executes on button press in btnCalibrateSys.
function btnCalibrateSys_Callback(hObject, eventdata, handles)
% hObject    handle to btnCalibrateSys (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Check if Measurement is Running%
str = get(handles.txtStatus,'String');

if strcmpi(str,'Measurement in progress') == 1
    uiwait('Please wait until the current measurement has finished!');
    return;
else
    setappdata(handles.figure1, 'state', 1); band = get(handles.popBand, 'Value');
    
    set(handles.measurementStop, 'Enable', 'on');
    set(handles.measurementStart, 'Enable', 'off');
    set(handles.txtStatus,'BackgroundColor','green');
    set(handles.txtStatus,'String','Measurement in progress');
    drawnow
    
    Out = handles.OMeasure; IP = handles.WMeasure; Loc = handles.LMeasure;
    
    switch band
        case 1
            Sys = handles.ASR;
        case 2
            Sys = handles.BoatNav;
        case 3
            Sys = handles.SPN43;
    end
    
    % Record time stamp
    tV = clock; Sys.t = etime(tV, [1970, 1, 1, 0, 0, 0]); % This assumes that the computer clock is Coordinated Universal time
    tVlocal = datevec(TimezoneConvert(datenum(tV), 'UTC', Loc.TimeZone));
    
    % Write starting file number, date, and time to GUI monitor
    set(handles.edtFileNum, 'String', [int2str(Out.StartFileNum) ' (' int2str(Out.StartFileNum) ')'])
    set(handles.edtDateTimeStart, 'String', datestr(datenum(tVlocal), 'mm/dd/yy HH:MM'));
    drawnow
    
    % Initalize spectrum analyzer
    [SAiObj, SAdObj] = SA_Init(IP.SA, MeasParameters(band));
    
    % Initialize web relay
    WRobj = WR_Init(IP.WR, 1024);
    
    % Inititialize Sys.Cal structure - this defines measurment parameters
    Sys.Cal.Temp = GetPreselectorTemp(WRobj);
    switch band
        case 1
            
        case 2
            
        case 3
            Sys.Cal.mType = 'Y-factor: swept-frequency';
            Sys.Cal.nM = 2;
            Sys.Cal.Processed = '';
            Sys.Cal.mPar = MeasParameters(band);
            Sys.Cal.mPar.td = 0.1;
            Sys.Cal.mPar.Det = 'Positive';
    end
    
    % Y-factor procedure
    SetFrontEndInput(WRobj, 1, handles); % input = noise diode
    SetVDC2NoiseDiode(WRobj, 1, handles) % noise diode = on
    [wOn, ~] = SA_FreqSweepMeas(SAdObj, Sys.Cal.mPar, handles);
    SetVDC2NoiseDiode(WRobj, 0, handles) % noise diode = off
    [wOff, ~] = SA_FreqSweepMeas(SAdObj, Sys.Cal.mPar, handles);
    SetFrontEndInput(WRobj, 0, handles); % input = antenna
    
    % Write JSON Sys message
    [fn, g, ~] = yFactCalcs(wOn, wOff, Sys.Preselector.enrND, Sys.Cal.mPar.RBW);
    Sys.Cal.Processed = 'True';
    filename = [Out.Prefix zzz2str(Out.StartFileNum,6) 'SysProc.json'];
    savejson('', Sys, filename);
    WriteDataBlock2File(filename, fn, Sys.Cal.DataType);
    WriteDataBlock2File(filename, g, Sys.Cal.DataType);
    
    Sys.Cal.Processed = 'False';
    filename = [Out.Prefix zzz2str(Out.StartFileNum,6) 'SysRaw.json'];
    savejson('', Sys, filename);
    WriteDataBlock2File(filename, wOn, Sys.Cal.DataType);
    WriteDataBlock2File(filename, wOff, Sys.Cal.DataType);
    clear filename
    
    % Populate GUI monitor
    Mfn = W2dBW(mean(dBW2W(fn)));
    Mg = W2dBW(mean(dBW2W(g)));
    set(handles.edtDateTimeLastCal, 'String', datestr(datenum(tVlocal), 'mm/dd/yy HH:MM'));
    set(handles.edtGainLastCal, 'String', num2str(round(10*Mg)/10));
    set(handles.edtNoiseFigLastCal, 'String', num2str(round(10*Mfn)/10));
    set(handles.edtTempLastCal, 'String', num2str(Sys.Cal.Temp));
    
    % Increment Out.StartFileNum in global variables and init file
    Out.StartFileNum = Out.StartFileNum + 1;
    WriteInitFile('init.json', Loc, Out, IP);
    
    % Disconnect SA and reset GUI
    SA_Close(SAiObj, SAdObj);
    setappdata(handles.figure1, 'state', 0);
    set(handles.measurementStop, 'Enable', 'off');
    set(handles.measurementStart, 'Enable', 'on');
    set(handles.txtStatus,'BackgroundColor','red');
    set(handles.txtStatus,'String','Measurement idle');
    drawnow
end

guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edtComment_CreateFcn(hObject, ~, ~)
% hObject    handle to edtComment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtSensorID_CreateFcn(hObject, ~, handles)
% hObject    handle to edtSensorID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtSensorKey_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtSensorKey (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtRadarParameters_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtRadarParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtLat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtLat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtLon_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtLon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtAlt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtAlt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function popupTimeZone_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupTimeZone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtDateTimeStart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtDateTimeStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function edtFileNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtFileNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtCalsPerHour_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtCalsPerHour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function popBand_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popBand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in btnOutputDBG.
function btnOutputDBG_Callback(hObject, eventdata, handles)
% hObject    handle to btnOutputDBG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of btnOutputDBG


% --- Executes during object creation, after setting all properties.
function edtVerMSOD_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtVerMSOD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtPrefix_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtPrefix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function popupDataType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupDataType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function popupByteOrder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupByteOrder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function popupCompress_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupCompress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtfStop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtfStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtNfreqs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtNfreqs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtfStart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtfStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtRBW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtRBW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtDet_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtDet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edttd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edttd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtDateTimeLastCal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtDateTimeLastCal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtGainLastCal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtGainLastCal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtNoiseFigLastCal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtNoiseFigLastCal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtSysNoiseLastCal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtSysNoiseLastCal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtTempLastCal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtTempLastCal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function popupModelCOTSsensor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupModelCOTSsensor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtfLowPassBPF_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtfLowPassBPF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtfHighPassBPF_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtfHighPassBPF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtENR_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtENR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtGainLNA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtGainLNA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtPmaxLNA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtPmaxLNA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtfLowStopBPF_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtfLowStopBPF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtfHighStopBPF_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtfHighStopBPF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtNoiseFigLNA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtNoiseFigLNA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtAntennaEL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtAntennaEL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtAntennaAZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtAntennaAZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edtAntennaCableLoss_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtAntennaCableLoss (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function popupAntennaModel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupAntennaModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);

function UpdateGuiFields( handles, Out, Loc )
% Populate GUI measurement system values
band = get(handles.popBand, 'Value');

switch band
    case 1
        Sys = handles.ASR;
    case 2
        Sys = handles.BoatNav;
    case 3
        Sys = handles.SPN43;
end

rPar = RadarParameters(band);
set(handles.edtRadarParameters, 'String', [rPar.Name ': T_A = ' num2str(rPar.TA) ' s/rot, PI = ' num2str(1000*rPar.PI) ' ms, PW = ' num2str(1e6*rPar.PW) ' us'])
set(handles.btnOutputJSON, 'Value', Out.JSON4MSOD);
set(handles.btnOutputDBG, 'Value', Out.MAT4DBG);
set(handles.edtPrefix, 'String', Out.Prefix)
set(handles.edtCalsPerHour, 'String', num2str(Sys.Cal.CalsPerHour))
set(handles.edtVerMSOD, 'String', Sys.Ver)

mPar = MeasParameters(band);
set(handles.edtfStart,'String',num2str(mPar.fStart/1e6));
set(handles.edtfStop,'String',num2str(mPar.fStop/1e6));
set(handles.edtNfreqs,'String',num2str(mPar.n));
set(handles.edtRBW,'String',num2str(mPar.RBW/1e6));
set(handles.edtDet,'String',mPar.Det);
set(handles.edttd,'String',num2str(mPar.td));
drawnow

if strcmpi(Sys.Cal.DataType, 'Binary - float32')
    set(handles.popupDataType, 'Value', 1)
elseif strcmpi(Sys.Cal.DataType, 'Binary - int16')
    set(handles.popupDataType, 'Value', 2)
elseif strcmpi(Sys.Cal.DataType, 'Binary - int8')
    set(handles.popupDataType, 'Value', 3)
elseif strcmpi(Sys.Cal.DataType, 'ASCII')
    set(handles.popupDataType, 'Value', 4)
end

if strcmpi(Sys.Cal.ByteOrder, 'Network')
    set(handles.popupByteOrder, 'Value', 1)
elseif strcmpi(Sys.Cal.ByteOrder, 'Big Endian')
    set(handles.popupByteOrder, 'Value', 2)
elseif strcmpi(Sys.Cal.ByteOrder, 'Little Endian')
    set(handles.popupByteOrder, 'Value', 3)
end
if strcmpi(Sys.Cal.Compression, 'None')
    set(handles.popupCompress, 'Value', 1)
elseif strcmpi(Sys.Cal.Compression, 'Zip')
    set(handles.popupCompression, 'Value', 2)
elseif strcmpi(Sys.Cal.Compression, 'N/A')
    set(handles.popupCompression, 'Value', 3)
end

% Populate GUI measurement location default values
if strcmpi(Loc.Mobility, 'Stationary')
    set(handles.btgMobility, 'SelectedObject', handles.btnStationary)
elseif strcmpi(Loc.Mobility, 'Mobile')
    set(handles.btgMobility, 'SelectedObject', handles.btnMobile)
end
set(handles.edtLat, 'String', num2str(Loc.Lat))
set(handles.edtLon, 'String', num2str(Loc.Lon))
set(handles.edtAlt, 'String', num2str(Loc.Alt))
if strcmpi(Loc.TimeZone, 'America/New_York')
    set(handles.popupTimeZone, 'Value', 1)
elseif strcmpi(Loc.TimeZone, 'America/Chicago')
    set(handles.popupTimeZone, 'Value', 2)
elseif strcmpi(Loc.TimeZone, 'America/Denver')
    set(handles.popupTimeZone, 'Value', 3)
elseif strcmpi(Loc.TimeZone, 'America/Phoenix')
    set(handles.popupTimeZone, 'Value', 4)
elseif strcmpi(Loc.TimeZone, 'America/Los_Angeles')
    set(handles.popupTimeZone, 'Value', 5)
end

% Populate GUI system hardware default values
set(handles.edtSensorID, 'String', Sys.SensorID)
set(handles.edtSensorKey, 'String', num2str(Sys.SensorKey));
if strcmpi(Sys.Antenna.Model, 'AAC SPBODA-1080/Omni/Slant')
    set(handles.popupAntennaModel, 'Value', 1);
elseif strcmpi(Sys.Antenna.Model, 'Alpha AW3232/Sector/Slant')
    set(handles.popupAntennaModel, 'Value', 2);
elseif strcmpi(Sys.Antenna.Model, 'Cobham OA2-0.3-10.0v/1505/Omni/VPOL')
    set(handles.popupAntennaModel, 'Value', 3);
end
set(handles.edtAntennaAZ, 'String', num2str(Sys.Antenna.AZ)); 
set(handles.edtAntennaEL, 'String', num2str(Sys.Antenna.EL));
set(handles.edtAntennaCableLoss, 'String', num2str(Sys.Antenna.lCable));
set(handles.edtfLowPassBPF, 'String', num2str(Sys.Preselector.fLowPassBPF/1e6));
set(handles.edtfHighPassBPF, 'String', num2str(Sys.Preselector.fHighPassBPF/1e6));
set(handles.edtfLowStopBPF, 'String', num2str(Sys.Preselector.fLowStopBPF/1e6));
set(handles.edtfHighStopBPF, 'String', num2str(Sys.Preselector.fHighStopBPF/1e6));
set(handles.edtNoiseFigLNA, 'String', num2str(Sys.Preselector.fnLNA));
set(handles.edtGainLNA, 'String', num2str(Sys.Preselector.gLNA));
set(handles.edtPmaxLNA, 'String', num2str(Sys.Preselector.pMaxLNA));
set(handles.edtENR, 'String', num2str(Sys.Preselector.enrND));
if strcmpi(Sys.COTSsensor.Model, 'Agilent E4440A')
    set(handles.popupModelCOTSsensor, 'Value', 1);
elseif strcmpi(Sys.COTSsensor.Model, 'Agilent Sensor N6841A')
    set(handles.popupModelCOTSsensor, 'Value', 2);
elseif strcmpi(Sys.COTSsensor.Model, 'CRFS RFeye')
    set(handles.popupModelCOTSsensor, 'Value', 3);
elseif strcmpi(Sys.COTSsensor.Model, 'NI USRP N210')
    set(handles.popupModelCOTSsensor, 'Value', 4);
elseif strcmpi(Sys.COTSsensor.Model, 'Signal Hound BB60C')
    set(handles.popupModelCOTSsensor, 'Value', 5);
elseif strcmpi(Sys.COTSsensor.Model, 'ThinkRF WSA5000-108')
    set(handles.popupModelCOTSsensor, 'Value', 6);
end

function UpdateGuiEdits( handles )
% Disable monitor text boxes
set(handles.edtSensorID, 'Enable', 'off')
set(handles.edtSensorKey, 'Enable', 'off')
set(handles.popupAntennaModel, 'Enable', 'off')
set(handles.edtAntennaAZ, 'Enable', 'off')
set(handles.edtAntennaEL, 'Enable', 'off')
set(handles.edtAntennaCableLoss, 'Enable', 'off')
set(handles.edtENR, 'Enable', 'off')
set(handles.edtfLowPassBPF, 'Enable', 'off')
set(handles.edtfHighPassBPF, 'Enable', 'off')
set(handles.edtfLowStopBPF, 'Enable', 'off')
set(handles.edtfHighStopBPF, 'Enable', 'off')
set(handles.edtGainLNA, 'Enable', 'off')
set(handles.edtNoiseFigLNA, 'Enable', 'off')
set(handles.edtPmaxLNA, 'Enable', 'off')
set(handles.popupModelCOTSsensor, 'Enable', 'off');

set(handles.edtDateTimeStart, 'Enable', 'off')
set(handles.edtFileNum, 'Enable', 'off')
set(handles.edtDateTimeLastCal, 'Enable', 'off')
set(handles.edtGainLastCal, 'Enable', 'off')
set(handles.edtNoiseFigLastCal, 'Enable', 'off')
set(handles.edtSysNoiseLastCal, 'Enable', 'off')
set(handles.edtTempLastCal, 'Enable', 'off')
set(handles.edtfStart, 'Enable', 'off')
set(handles.edtfStop, 'Enable', 'off')
set(handles.edtNfreqs, 'Enable', 'off')
set(handles.edtRBW, 'Enable', 'off')
set(handles.edtDet, 'Enable', 'off')
set(handles.edttd, 'Enable', 'off')
set(handles.edtRadarParameters, 'Enable', 'off')

set(handles.edtLat, 'Enable', 'off')
set(handles.edtLon, 'Enable', 'off')
set(handles.edtAlt, 'Enable', 'off')
set(handles.popupTimeZone, 'Enable', 'off')

function rPar = RadarParameters(b)
switch b
    case 1
        rPar.Name = 'Radar - ASR';
        rPar.TA = 4;
        rPar.PI = .001;
        rPar.PW = .000001;
    case 2
        rPar.Name = 'Radar - BoatNav';
        rPar.TA = 4;
        rPar.PI = .001;
        rPar.PW = .000001;
    case 3
        rPar.Name = 'Radar - SPN43';
        rPar.TA = 4;
        rPar.PI = .001;
        rPar.PW = .000001;
end

function mPar = MeasParameters(b)
% Defines the measurement parameters to measure a specific radar band.
% These parameters cannot be edited via the GUI.

rPar = RadarParameters(b);
switch b
    case 1
        mPar.RBW = 1e6;
        mPar.fStart = 2.7e9 + mPar.RBW/2;
        mPar.fStop = 2.9e9 - mPar.RBW/2;
        mPar.n = floor(abs(mPar.fStop - mPar.fStart)/mPar.RBW) + 1;
        mPar.td = 1.25*rPar.TA;
        mPar.Det = 'Positive';
        mPar.Atten = 4;
        mPar.VBW = 50e6; % Maximum VBW for all measurements (hertz)
    case 2
        mPar.RBW = 1e6;
        mPar.fStart = 2.9e9 + mPar.RBW/2;
        mPar.fStop = 3.2e9 - mPar.RBW/2;
        mPar.n = floor(abs(mPar.fStop - mPar.fStart)/mPar.RBW) + 1;
        mPar.td = 1.25*rPar.TA;
        mPar.Det = 'Positive';
        mPar.Atten = 4;
        mPar.VBW = 50e6; % Maximum VBW for all measurements (hertz)
    case 3
        mPar.RBW = 1e6;
        mPar.fStart = 3.45e9 + mPar.RBW/2;
        mPar.fStop = 3.65e9 - mPar.RBW/2;
        mPar.n = floor(abs(mPar.fStop - mPar.fStart)/mPar.RBW) + 1;
        mPar.td = 1.25*rPar.TA;
        mPar.Det = 'Positive';
        mPar.Atten = 4;
        mPar.VBW = 50e6; % Maximum VBW for all measurements (hertz)
end

function saPar = SysAntennaParameters(b)
%Antennas In Development
saPar = '';
switch b
    case 'Cobham OA2-0.3-10.0v/1505/Omni/VPOL'
        saPar.Model = b;
        saPar.fLow = 0.3e9;
        saPar.fHigh = 10e9;
        saPar.g = 1.5;
        saPar.bwH = 360;
        saPar.bwV = 93.2;
        saPar.AZ = 90;
        saPar.EL = 32;
        saPar.Pol = 'VL';
        saPar.XSD = 19.9;
        saPar.VSWR = -1;
    case 'AAC SPBODA-1080_NFi'
        saPar.Model = b;
        saPar.fLow = 1e9;
        saPar.fHigh = 8e9;
        saPar.g = 0;
        saPar.bwH = 360;
        saPar.bwV = -1;
        saPar.AZ = 0;
        saPar.EL = 0;
        saPar.Pol = 'Slant';
        saPar.XSD = -1;
        saPar.VSWR = 2.5;
    case 'Alpha AW3232'
        saPar.Model = b;
        saPar.fLow = 3.3e9;
        saPar.fHigh = 3.8e9;
        saPar.g = 15;
        saPar.bwH = 120;
        saPar.bwV = 7;
        saPar.AZ = 0;
        saPar.EL = 0;
        saPar.Pol = 'Slant';
        saPar.XSD = 13;
        saPar.VSWR = -1;
end

saPar.lCable = 1;

function spPar = SysPreselectorParameters()
%Default Values for All Preselectors
spPar = '';
spPar.fLowPassBPF = 3430000000;
spPar.fHighPassBPF = 3674000000;
spPar.fLowStopBPF = 3390000000;
spPar.fHighStopBPF = 3710000000;
spPar.fnLNA = 1.34;
spPar.gLNA = 43.29;
spPar.pMaxLNA = 27.29;
spPar.enrND = 14.34;

function scPar = SysCOTSParameters(b)
%Sensors Currently in Development Stage
scPar = '';
switch b
    case 'Agilent E4440A'
        scPar.Model = b;
        scPar.fLow = 3;
        scPar.fHigh = 2.65e+10;
        scPar.fn = 22;
        scPar.pMax = 0;
    case 'Agilent Sensor N6841A'
        scPar.Model = b;
        scPar.fLow = 20e6;
        scPar.fHigh = 6e9;
        scPar.fn = -1;
        scPar.pMax = -1;
    case 'CRFS RFeye'
        scPar.Model = b;
        scPar.fLow = 10e6;
        scPar.fHigh = 6e9;
        scPar.fn = 8;
        scPar.pMax = 10;
    case 'NI USRP N210'
        scPar.Model = b;
        scPar.fLow = 3;
        scPar.fHigh = 2.65e+10;
        scPar.fn = 22;
        scPar.pMax = 0;
    case 'Signal Hound BB60C'
        scPar.Model = b;
        scPar.fLow = 9e3;
        scPar.fHigh = 6e9;
        scPar.fn = -1;
        scPar.pMax = -1;
    case 'ThinkRF WSA5000-108'
        scPar.Model = b;
        scPar.fLow = 3;
        scPar.fHigh = 2.65e+10;
        scPar.fn = 22;
        scPar.pMax = 0;
end

function scaPar = SysCalParameters(b)
%Sensors Currently in Development Stage
switch b
    case 1
        scaPar.CalsPerHour = 1;
        scaPar.MeasCycle = 'Hourly';
        scaPar.Temp = 82.2;
        scaPar.mType = 'Y-factor: swept-frequency';
        scaPar.nM = 2;
        scaPar.Processed = '';
        scaPar.DataType = 'ASCII';
        scaPar.ByteOrder = 'Network';
        scaPar.Compression = 'None';
    case 2
        scaPar.CalsPerHour = 1;
        scaPar.MeasCycle = 'Hourly';
        scaPar.Temp = 82.2;
        scaPar.mType = 'Y-factor: swept-frequency';
        scaPar.nM = 2;
        scaPar.Processed = '';
        scaPar.DataType = 'ASCII';
        scaPar.ByteOrder = 'Network';
        scaPar.Compression = 'None';
    case 3
        scaPar.CalsPerHour = 1;
        scaPar.MeasCycle = 'Hourly';
        scaPar.Temp = 82.2;
        scaPar.mType = 'Y-factor: swept-frequency';
        scaPar.nM = 2;
        scaPar.Processed = '';
        scaPar.DataType = 'ASCII';
        scaPar.ByteOrder = 'Network';
        scaPar.Compression = 'None';
end

scaPar.mPar = MeasParameters(b);

function handles = InitSystemStruct(handles, Loc, Model)
i = 1;

while i <= 3
    x.Ver = Loc.Ver;
    x.Type = 'Sys';
    x.SensorID = Loc.SensorID;
    x.SensorKey = Loc.SensorKey;
    x.t = -1;
    x.Antenna = SysAntennaParameters(Model.Antenna);
    x.Preselector = SysPreselectorParameters();
    x.COTSsensor = SysCOTSParameters(Model.COTSsensor);
    x.Cal = SysCalParameters(i);
    switch i
        case 1
            handles.ASR = x;
        case 2
            handles.BoatNav = x;
        case 3
            handles.SPN43 = x;
    end
    i = i + 1; x = '';
end

function x = InitDataStruct(band, Sys)
rPar = RadarParameters(band);
x.Ver = Sys.Ver;
x.Type = 'Data';
x.SensorID = Sys.SensorID;
x.SensorKey = Sys.SensorKey;
x.t = -1;
x.Sys2Detect = rPar.Name;
x.Sensitivity = 'Medium';
x.mType = 'Swept-frequency';
x.t1 = -1;
x.a = -1;
x.nM = 1;
x.Ta = 0;
x.OL = -1;
x.wnI = -1;
x.Comment = '';
x.Processed = '';
x.DataType = Sys.Cal.DataType;
x.ByteOrder = Sys.Cal.ByteOrder;
x.Compression = Sys.Cal.Compression;
x.mPar = MeasParameters(band);

function WriteDataBlock2File(filename, x, DataType)
if strcmpi(DataType, 'ASCII')
    fid = fopen(filename, 'a');
    fprintf(fid, '%s\r\n', savejson('', transpose(x)));
else
    fid = fopen(filename, 'a', 'ieee-be');
    fwrite(fid, transpose(x), Precision(DataType));
end
fclose(fid);

function p = Precision(DataType)
if strcmpi(DataType, 'Binary - float32')
    p = 'float32';
elseif strcmpi(DataType, 'Binary - int16')
    p = 'int16';
elseif strcmpi(DataType, 'Binary - int8')
    p = 'int8';
end

function obj = WR_Init(IP, BufferSize)
% Inititialize web relay
% Connect to web relay
obj = tcpip(IP, 80);
obj.Terminator = 'CR/LF';
obj.TransferDelay = 'off';
obj.InputBufferSize = BufferSize;

function SetFrontEndInput(obj, s, h)
% Set front-end input
% s: 0=antenna, 1=noise diode
WR_SetRelayState(obj, 2, s);
if nargin > 2
    if s == 0; str = 'green'; elseif s == 1; str = 'red'; end
    set(h.txtFrontEndInput, 'BackgroundColor', str);
    drawnow
end

function SetVDC2NoiseDiode(obj, s, h)
% Turn on/off noise diode - apply DC voltage to noise diode
% s: 0=off/0VDC, 1=on/28VDC
WR_SetRelayState(obj, 1, s);
if nargin > 2
    if s == 1; str = 'red'; elseif s == 0; str = 'green'; end
    set(h.txtNDon_off, 'BackgroundColor', str);
    drawnow
end

function WR_SetRelayState(obj, r, s)
fopen(obj);
fprintf(obj, '%s\n\n', ['GET /state.xml?relay' num2str(r) 'State=' num2str(s) ' HTTP/1.1']);
fclose(obj);

function s = WR_GetRelayState(obj, r)
fopen(obj);
fprintf(obj, '%s\n\n', 'GET /state.xml HTTP/1.1');
tic
while obj.BytesAvailable == 0
    t = toc;
    if t>5; break; end
end
if obj.BytesAvailable ~= 0
    reply = transpose(char(fread(obj, obj.BytesAvailable)));
    jj = findstr(reply, ['relay' num2str(r) 'state']);
    s = str2double(reply(jj(2)-3));
else
    s = NaN;
end
fclose(obj);

function T = GetPreselectorTemp(obj)
u = WR_GetTempUnits(obj);
if ~isempty(u)
    TT = WR_GetTemp(obj, 1);
    if ~isnan(TT)
        if strcmpi(u, 'F')
            T = TT;
        elseif strcmpi(u, 'C')
            T = 9*TT/5 + 32;
        elseif strcmpi(u, 'K')
            T = 9*(TT - 273)/5 + 32;
        end
    else
        T = -999;
    end
else
    T = -999;
end

function T = WR_GetTemp(obj, SensorNum)
% Turn on/off noise diode - apply DC voltage to noise diode
% arg: 0=off/0VDC, 1=on/28VDC
fopen(obj);
fprintf(obj, '%s\n\n', 'GET /state.xml HTTP/1.1');
tic
while obj.BytesAvailable == 0
    t = toc;
    if t>5; break; end
end
if obj.BytesAvailable ~= 0
    reply = transpose(char(fread(obj, obj.BytesAvailable)));
    jj = findstr(reply, ['sensor' num2str(SensorNum) 'temp']);
    idx1 = jj(1) + findstr(reply(jj(1):jj(2)), '>');
    idx2 = jj(1) + findstr(reply(jj(1):jj(2)), '<') - 2;
    T = str2double(reply(idx1:idx2));
else
    T = NaN;
end
fclose(obj);

function u = WR_GetTempUnits(obj)
fopen(obj);
fprintf(obj, '%s\n\n', 'GET /state.xml HTTP/1.1');
tic
while obj.BytesAvailable == 0
    t = toc;
    if t>5; break; end
end
if obj.BytesAvailable ~= 0
    reply = transpose(char(fread(obj, obj.BytesAvailable)));
    jj = findstr(reply, 'units');
    if length(jj)==2; u = reply(jj(2)-3); else u = ''; end
else
    u = '';
end
fclose(obj);

function [iObj, dObj] = SA_Init(IP, mPar)
% Connect to spectrum analyzer
[iObj, dObj] = ConnectToInstrument('E4440SA', 'Visa', IP, 'NI');
% Inititialize spectrum analzer
invoke(dObj, 'iGenPreset');
set(dObj, 'iGenAutoCal', 'Off');
invoke(dObj, 'iGenSetOvrDrvAndAlignRqst');
invoke(dObj, 'iGenAutoCouple', 1, false, 1, 1);
set(dObj, 'iGenAtten', mPar.Atten);
set(dObj, 'iGenRefLevel', 0);
% if Sys.COTSsensor.yUnits==2; set(handles.SAdObj, 'iGenYUnits', 'W'); end
set(dObj, 'iGenSweepMode', 'Single');
% Perform alignment in specified frequency range
set(dObj, 'iGenStartFreq', mPar.fStart);
set(dObj, 'iGenStopFreq', mPar.fStop);
invoke(dObj, 'iGenCalNow', 1);

function SA_Close(SAiObj, SAdObj)
% Disconnect spectrum analyzer
disconnect(SAdObj);
delete(SAdObj);
delete(SAiObj)

function [w, f, OL] = SA_FreqSweepMeas(dObj, mPar, h)
% Input variable:
% mPar is a data structure w the following measurement parameters
%   fStart = start frequency (Hz)
%   fStop = stop frequency (Hz)
%   RBW = resolution bandwidth (Hz)
%   VBW = video bandwidth (Hz)
%   td = time per frequency bin (seconds)
%   Det = detector
StepSize = mPar.RBW;
nSteps = floor(abs(mPar.fStop - mPar.fStart)/StepSize) + 1;
f = mPar.fStart + transpose(0:(nSteps-1))*StepSize;
if nargin > 2
    % Update GUI
    set(h.edtfStart, 'String', num2str(mPar.fStart/1e6));
    set(h.edtfStop, 'String', num2str(mPar.fStop/1e6));
    set(h.edtNfreqs, 'String', num2str(nSteps));
    set(h.edtRBW, 'String', num2str(mPar.RBW/1e6));
    set(h.edtDet, 'String', mPar.Det);
    set(h.edttd, 'String', num2str(mPar.td));
    drawnow
end
set(dObj, 'iGenStartFreq', mPar.fStart);
set(dObj, 'iGenStopFreq', mPar.fStop);
set(dObj, 'iGenSweepPoints', nSteps);
set(dObj, 'iGenRBW', mPar.RBW);
set(dObj, 'iGenVBW', mPar.VBW);
set(dObj, 'iGenDetector', mPar.Det);
set(dObj, 'iGenSweepTime', nSteps*mPar.td);
w = invoke(dObj, 'iGenTraceData', 1, 1, 0);
OL = invoke(dObj, 'iGenGetOvrDrvAndAlignRqst');

function [fn_dB, g_dB, w0r_dBm] = yFactCalcs(wNDon, wNDoff, enrND, RBW)
% Calculates noise figure (linear units), gain (linear units), and mean power (Watts)
% for a y-factor calibration measurement.
% input variables:
% wNDon = Measured power (dBm) w noise diode on
% wNDoff = Measured power (dBm) w noise diode off
% enrND = excess noise ratio (dB) of noise diode
% RBW = resolution bandwidth (Hz)
wOn = dBW2W(wNDon-30);
wOff = dBW2W(wNDoff-30);
enr = dBW2W(enrND);
y = wOn./wOff;
fn = enr./(y - 1); % noise figure
% 1.128 is factor for converting from RBW to noise equiv bandwidth
g = wOn./(1.38e-23*(25 + 273.15)*1.128*RBW*(enr + fn));
% Mean power of receiver noise (Watts)
w0r = 1.38e-23*(25 + 273.15)*1.128*RBW*fn.*g;
fn_dB = W2dBW(fn);
g_dB = W2dBW(g);
w0r_dBm = W2dBm(w0r);

function idxf0 = findPeaks(w, wT)
% Returns indices of peak of band of continguous frequency bins with
% measured radar signals that exceed threshold wT
n = nXgtY(w, wT);
if n == 0
    idxf0 = [];
else
    [~, idx1] = sort(w, 'descend');
    idx2 = sort(idx1(1:n));
    m = 0; % Number of blocks of contiguous frequency bins with w >= wT
    for k = 1:n
        if k == 1 || idx2(k) ~= idx2(k-1)+1
            cnt = 1; % Number of contiguous frequency bins with w >= wT
            m = m + 1;
            idxf0(m) = idx2(k);
        else
            cnt = cnt + 1;
            [~,idxMax] =  max(w(idx2(k - cnt + 1):idx2(k)));
            idxf0(m) = idxMax + idx2(k - cnt + 1) - 1;
        end
    end
end

function ClearPlots(h)
axes(h.axsCal);
hold off;
plot([], [])
axes(h.axsFreq);
hold off;
plot([], [])
axes(h.axsContour);
hold off
plot([], [])

function [Loc, Out, IP, Model] = ReadInitFile(filename)
if isequal(exist(filename, 'file'), 2)
    [~,name,ext] = fileparts(which(filename));
    fid = fopen(strcat(name,ext), 'r');
    Loc = loadjson(ReadJsonPacket(fid));
    Out = loadjson(ReadJsonPacket(fid));
    IP = loadjson(ReadJsonPacket(fid));
    Model = loadjson(ReadJsonPacket(fid));
    fclose(fid);
end

function [s, nC, nl] = ReadJsonPacket(fid)
% ReadJsonPacket reads the next JSON packet starting from the file pointer
% (fid). A JSON packet begins and ends with curly brackets.
n = 0;
s = '';
nC = 0;
nl = 0;
% Find the first open bracket
while n == 0 && ~feof(fid)
    l = fgetl(fid);
    n = length(strfind(l, '{'));
end
% If open bracket was found read until close bracket
if n > 0
    s = strcat(s, l);
    nl = 1;
    while n>0
        clear l
        l = fgetl(fid);
        n = n + length(strfind(l, '{')) - length(strfind(l, '}'));
        s = strcat(s, l);
        nl = nl + 1;
    end
    nC = length(s);
end

function WriteInitFile(filename, Loc, Out, IP)
fid = fopen(filename, 'w');
str = strrep(savejson('', Loc), sprintf('\n'), sprintf('\r\n'));
fprintf(fid, '%s', str);
str = strrep(savejson('', Out), sprintf('\n'), sprintf('\r\n'));
fprintf(fid, '%s', str);
str = strrep(savejson('', IP), sprintf('\n'), sprintf('\r\n'));
fprintf(fid, '%s', str);
fclose(fid);

function plotPkFreqDomainData(h, f, w, OL, wT, idxf0, wnPk, w0r, tStr, lStr)
% Input variables:
% h = handle to the axes
% f = frequency (Hz)
% w = Detected power (dBm)
% OL = Overload flag {0, 1}
% wT = threshold (dBm)
% idxf0 = indices at peaks of observed signals
% wnPk = peak of system noise (dBm)
% w0r = mean power of system noise (dBm)
% tStr = title string
% lStr = legend string
axes(h);
[fAdj fUnits] = adjFreq(f);
hA = area(fAdj, wnPk, W2dBm(mean(dBm2W(w0r))));
set(hA,'FaceColor',[.70 .70 .70],'LineStyle','none');
hold on;
grid on;
title(tStr);
xlabel(['f (' fUnits ')']);
ylabel('w (dBm)');
yMin = 10*floor(min([min(w0r) min(w)])/10);
yMax = 10;
ylim([yMin yMax]);
set(gca,'Layer','top');
plot(fAdj, w);
plot([fAdj(1) fAdj(length(fAdj))], wT*[1 1], 'g--')
if ~isempty(idxf0)
  for k = 1:length(idxf0)
    plot(fAdj(idxf0(k))*[1 1], [yMin yMax], 'r-')
  end
  hL = legend('< Peak & > Mean Rx Noise', lStr, 'w_T', 'f_{0,k}');
else
  hL = legend('< Peak & > Mean Rx Noise', lStr, 'w_T');
end
set(hL,'Visible','on','FontSize',8);
if OL; str = 'red'; else str = 'black'; end
set(h, 'XColor', str, 'YColor', str);
hold off;

% --------------------------------------------------------------------
function measurementStart_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to measurementStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Clear plot and Enable/Disable/Color GUI Objects
ClearPlots(handles);

setappdata(handles.figure1, 'state', 1);

set(handles.measurementStop, 'Enable', 'on');
set(handles.measurementStart, 'Enable', 'off');
set(handles.txtStatus,'BackgroundColor','green');
set(handles.txtStatus,'String','Measurement in progress');
guidata(hObject, handles);
drawnow

pause(30)

set(handles.measurementStart, 'Enable', 'on');
set(handles.measurementStop, 'Enable', 'on');
set(handles.txtStatus,'BackgroundColor','red');
set(handles.txtStatus,'String','System will shutdown after current measurement cycle');
guidata(hObject, handles);
drawnow

pause(30)

set(handles.measurementStop, 'Enable', 'off');
set(handles.measurementStart, 'Enable', 'off');
set(handles.txtStatus,'BackgroundColor','green');
set(handles.txtStatus,'String','Measurement in progress');

pause(30)

set(handles.measurementStop, 'Enable', 'off');
set(handles.measurementStart, 'Enable', 'on');
set(handles.txtStatus,'BackgroundColor','yellow');
set(handles.txtStatus,'String','Measurement in progress');

% Start System Calibration/Messages/Plot Timer %
%sysCalTimer(handles); Band35Timer(handles);

%Update GUI Handles
guidata(hObject, handles);

function sysCalTimer(handles)

files_obj = timer(...
    'TimerFcn',         {@sysCal_update, handles}, ...  % timer function, has to specific the handle to the GUI,
    'StopFcn',          @sysCal_stop, ...               % stop function
    'ErrorFcn',         @sysCal_err, ...                % error function
    'ExecutionMode',    'fixedRate', ...                %
    'Period',           3600.0, ...                     % updates every 01 Hour
    'TasksToExecute',   inf, ...
    'BusyMode',         'drop');


start(files_obj);        % start the timer object

setappdata(hObject, 'sysCal', files_obj');  % save the timer object as app data

function sysCal_update( src,evt, handles )
set(handles.measurementStart, 'Enable', 'off');
set(handles.measurementStop, 'Enable', 'on');
set(handles.txtStatus,'BackgroundColor','green');
set(handles.txtStatus,'String','Measurement in progress');
drawnow

% Initialize variables
persistent a tVlastCal
Out = handles.OMeasure; IP = handles.WMeasure; Loc = handles.LMeasure;
FileNum = Out.StartFileNum;

if isempty(a)
    a = 1; tVlastCal = [0, 0, 0, 0, 0, 0];
else
    a = a + 1;
end

switch band
    case 1
        Sys = handles.ASR;
    case 2
        Sys = handles.BoatNav;
    case 3
        Sys = handles.SPN43;
        
        % Inititialize Sys.Cal.mPar according to chosen band
        Sys.Cal.nM = 2;
        Sys.Cal.mType = 'Y-factor: swept-frequency';
        Sys.Cal.mPar = MeasParameters(rPar);
        Sys.Cal.mPar.td = 0.1;
        Sys.Cal.mPar.Det = 'Positive';
end

% Initalize spectrum analyzer
[SAiObj, SAdObj] = SA_Init(IP.SA, MeasParameters(rPar));

Initialize web relay
WRobj = WR_Init(IP.WR, 1024);

Initialize web relay to occupancy measurement configuration
SetFrontEndInput(WRobj, 0, handles); % input = antenna
SetVDC2NoiseDiode(WRobj, 0, handles) % noise diode = off

% Populate GUI monitor - start date/time and file number
set(handles.edtFileNum, 'String', [int2str(FileNum) ' (' int2str(FileNum - a + 1) ')'])
drawnow

% Clear variables
clear Data tV t tVlocal teDay tStr w x OL wI fAdj fUnits idxf0 lStr

% Record time stamp
tV = clock; t = etime(tV, [1970, 1, 1, 0, 0, 0]); % This assumes that the computer clock is Coordinated Universal time
tVlocal = datevec(TimezoneConvert(datenum(tV), 'UTC', Loc.TimeZone));
if a == 1
    t1 = t;
    set(handles.edtDateTimeStart, 'String', datestr(datenum(tVlocal), 'mm/dd/yy HH:MM'))
end

% Write JSON Loc messages
if Out.JSON4MSOD && (a==1 || strcmpi(Loc.Mobility, 'Mobile'))
    Loc.t = t; filename = [Out.Prefix zzz2str(FileNum,6) 'Loc.json'];
    savejson('', Loc, filename);
end

% Generate plotting variables and strings
teDay = etime(tVlocal, [tVlocal(1), tVlocal(2), tVlocal(3), 0, 0, 0]);


% Clear cal variables
clear AlignNeeded wOn wOff fn g w0r Mfn Mg wnPk wT V MwnPkI

% Acquire temperature reading
Sys.Cal.Temp = GetPreselectorTemp(WRobj);

% Perform alignment if needed
[~, AlignNeeded] = invoke(SAdObj, 'iGenGetOvrDrvAndAlignRqst');
if AlignNeeded; invoke(SAdObj, 'iGenQuickCalNow', 1); end

% Y-factor procedure
SetFrontEndInput(WRobj, 1, handles); % input = noise diode
SetVDC2NoiseDiode(WRobj, 1, handles) % noise diode = on
[wOn, ~] = SA_FreqSweepMeas(SAdObj, Sys.Cal.mPar, handles);
SetVDC2NoiseDiode(WRobj, 0, handles) % noise diode = off
[wOff, ~] = SA_FreqSweepMeas(SAdObj, Sys.Cal.mPar, handles);
SetFrontEndInput(WRobj, 0, handles); % input = antenna

% Calculate system noise figure and gain
[fn, g, w0r] = yFactCalcs(wOn, wOff, Sys.Preselector.enrND, Sys.Cal.mPar.RBW);
Mfn = W2dBW(mean(dBW2W(fn))); Mg = W2dBW(mean(dBW2W(g)));

% Write JSON Sys message
if Out.JSON4MSOD
    Sys.t = t;  % Time stamp cal
    Sys.Cal.Processed = 'True';
    filename = [Out.Prefix zzz2str(FileNum,6) 'SysProc.json'];
    savejson('', Sys, filename);
    WriteDataBlock2File(filename, fn, Sys.Cal.DataType);
    WriteDataBlock2File(filename, g, Sys.Cal.DataType);
    clear filename
    if a == 1
        Sys.Cal.Processed = 'False';
        filename = [Out.Prefix zzz2str(FileNum,6) 'SysRaw.json'];
        savejson('', Sys, filename);
        WriteDataBlock2File(filename, wOn, Sys.Cal.DataType);
        WriteDataBlock2File(filename, wOff, Sys.Cal.DataType);
        clear filename
    end
end

% Plot today's cal data
axes(handles.axsCal);
if length(find(tVlastCal==0)) == 6 || tVlocal(3) ~= tVlastCal(3)
    yMin = -10; yMax = 60;
    hold off;
    if a==1; hA = area([0 teDay]/3600, [yMax yMax], yMin); else hA = area([0 0], [yMax yMax], yMin); end
    set(hA,'FaceColor',[.70 .70 .70],'LineStyle','none');
    hold on;
    c(1) = plot(teDay/3600, Mfn, 'rx');
    c(2) = plot(teDay/3600, Mg, 'k+');
    title(['Calibration Data: ' datestr(tVlocal, 1)]);
    xlabel('Hour');
    ylabel('dB');
    xlim([0 24]);
    ylim([yMin yMax]);
    set(handles.axsCal, 'Layer', 'top', 'XTick', 0:4:24);
    grid on;
    hL = legend(c,'F_n', 'G');
    set(hL, 'FontSize', 8);
    clear yMin yMax hA hL;
else
    plot(teDay/3600, Mfn, 'rx');
    plot(teDay/3600, Mg, 'k+');
end

% Populate GUI monitor with cal info
set(handles.edtDateTimeLastCal, 'String', datestr(datenum(tVlocal), 'mm/dd/yy HH:MM'));
set(handles.edtGainLastCal, 'String', num2str(round(10*Mg)/10));
set(handles.edtNoiseFigLastCal, 'String', num2str(round(10*Mfn)/10));
set(handles.edtSysNoiseLastCal, 'String', num2str(round(10*MwnPkI)/10));
set(handles.edtTempLastCal, 'String', num2str(Sys.Cal.Temp));
drawnow

tVlastCal = tVlocal;

function sysCal_stop( src, evt )
stop(timerfindall);
delete(timerfindall);

function sysCal_err( src, evt )
disp('Timer Error: System Calibration' );


function Band35Timer(handles)

files_obj = timer(...
    'TimerFcn',         {@Band35_update, handles}, ...  % timer function, has to specific the handle to the GUI,
    'StopFcn',          @Band35_stop, ...               % stop function
    'ErrorFcn',         @Band35_err, ...                % error function
    'ExecutionMode',    'fixedRate', ...                %
    'Period',           1280.0, ...                     % updates every 01 Hour
    'TasksToExecute',   inf, ...
    'BusyMode',         'drop');


start(files_obj);        % start the timer object

setappdata(hObject, 'Band35', files_obj');  % save the timer object as app data

function Band35_update( src,evt, handles )
set(handles.measurementStart, 'Enable', 'off');
set(handles.measurementStop, 'Enable', 'on');
set(handles.txtStatus,'BackgroundColor','green');
set(handles.txtStatus,'String','Measurement in progress');
drawnow

% Initialize variables
persistent aa;
Sys = handles.SPN43; tV = clock; t = etime(tV, [1970, 1, 1, 0, 0, 0]);
tVlocal = datevec(TimezoneConvert(datenum(tV), 'UTC', Loc.TimeZone));

% Y-factor procedure
SetFrontEndInput(WRobj, 1, handles); % input = noise diode
SetVDC2NoiseDiode(WRobj, 1, handles) % noise diode = on
[wOn, ~] = SA_FreqSweepMeas(SAdObj, Sys.Cal.mPar, handles);
SetVDC2NoiseDiode(WRobj, 0, handles) % noise diode = off
[wOff, ~] = SA_FreqSweepMeas(SAdObj, Sys.Cal.mPar, handles);
SetFrontEndInput(WRobj, 0, handles); % input = antenna

% Calculate system noise figure and gain
[~, g, w0r] = yFactCalcs(wOn, wOff, Sys.Preselector.enrND, Sys.Cal.mPar.RBW);

% Calculate system noise parameters at COTS sensor
wnPk = W2dBm(dBm2W(w0r)*SA_P2A(Data.mPar.td, Data.mPar.RBW)); % Peak-detected receiver noise level (dBm)
wT = 3+max(wnPk); % Threshold that identifies signal in peak-detected measurement (dBm)
V = transpose(floor(wT):10*ceil(Sys.COTSsensor.pMax/10)); % Color scale vector for contour plot

% Calculate detected system noise power [dBm ref to terminal of isotropic antenna]
MwnPkI = W2dBm(mean(dBm2W(wnPk + Sys.Antenna.lCable - g - Sys.Antenna.g)));
% Measure peaks above threshold over entire band
[w, x, OL] = SA_FreqSweepMeas(SAdObj, Data.mPar, handles);
wI = w + Sys.Antenna.lCable - Sys.Antenna.g - g;
[fAdj fUnits] = adjFreq(x); idxf0 = findPeaks(w, wT); % Find band centers

% Plot frequency domain data
lStr = ['RBW=' num2str(Data.mPar.RBW/1e6) ' MHz, t_d=' num2str(Data.mPar.td) ' s, Det=Peak'];
plotPkFreqDomainData(handles.axsFreq, x, w, OL, wT, idxf0, wnPk, w0r, tStr, lStr)

% Plot data in contour
if isempty(aa)
    clear hr wPk
    aa = 1;
else
    aa = aa + 1;
end
hr(aa) = teDay/3600;
wPk(:,aa) = w;
if aa > 1
    yMin = fAdj(1); yMax = fAdj(length(fAdj));
    axes(handles.axsContour);
    if aa==a; hA = area([0 hr(2)], [yMax yMax]); else hA = area([0 0], [yMax yMax]); end
    set(hA,'FaceColor',[.70 .70 .70],'LineStyle','none');
    hold on;
    [~, hC] = contourf(hr, fAdj, wPk, V);
    set(hC, 'LineStyle', 'none');
    colorbar;
    caxis([min(V) max(V)]);
    title(['Measured Signal Powers, ' datestr(tVlocal, 1)])
    xlabel('Hour');
    ylabel(['f (' fUnits ')']);
    xlim([0 24]);
    ylim([yMin yMax]);
    set(handles.axsContour, 'Layer', 'top', 'XTick', 0:4:24);
    grid on;
    clear yMin yMax hA hC
    hold off;
end

set(handles.measurementStart, 'Enable', 'off');
set(handles.measurementStop, 'Enable', 'off');
set(handles.txtStatus,'BackgroundColor','yellow');
set(handles.txtStatus,'String','System will shutdown after current measurement cycle');
guidata(hObject, handles);
drawnow


function Band35_stop( src, evt )
stop(timerfindall);
delete(timerfindall);

function Band35_err( src, evt )
disp('Timer Error: 3.5GHz Band' );
            
            
            
            
            % Initialize Data structures
            %     Data = InitDataStruct(band, Sys);
            % Match Loc to Sys header info
            % if strcmp(Loc.Ver,Sys.Ver) == 0 || strcmp(Loc.SensorID,Sys.SensorID) == 0 || strcmp(Loc.SensorKey,Sys.SensorKey) == 0
            %     quest = questdlg('The System and Location Messages do NOT MATCH for the sensor. Would you like to correct this and continue or cancel?','Versioning','Continue','Cancel','Continue');
            %
            %     if isempty(quest)
            %         delete(handles.figure1);
            %     end
            %
            %     switch quest
            %         case 'Continue'
            %             a = Loc.Ver; b = Sys.Ver;
            %             quest2 = questdlg('Which Version Identifier would you prefer to use?', 'Versioning', a , b, a);
            %
            %             switch quest2
            %                 case Loc.Ver
            %                     Sys.Ver = Loc.Ver;
            %                     Sys.SensorID = Loc.SensorID;
            %                     Sys.SensorKey = Loc.SensorKey;
            %                 case Sys.Ver
            %                     Loc.Ver = Sys.Ver;
            %                     Loc.SensorID = Sys.SensorID;
            %                     Loc.SensorKey = Sys.SensorKey;
            %             end
            %
            %         otherwise
            %             return;
            %     end
            %
            % end
            
            %
            %     % Measure peaks above threshold over entire band
            %     [w, x, OL] = SA_FreqSweepMeas(SAdObj, Data.mPar, handles);
            %     wI = w + Sys.Antenna.lCable - Sys.Antenna.g - g;
            %     [fAdj fUnits] = adjFreq(x);
            %     idxf0 = findPeaks(w, wT); % Find band centers
            %
            %     % Plot frequency domain data
            %     lStr = ['RBW=' num2str(Data.mPar.RBW/1e6) ' MHz, t_d=' num2str(Data.mPar.td) ' s, Det=Peak'];
            %     plotPkFreqDomainData(handles.axsFreq, x, w, OL, wT, idxf0, wnPk, w0r, tStr, lStr)
            %
            %     % Plot data in contour
            %     if a==1 || tVlocal(3)~=DayContour
            %         clear hr wPk
            %         aa = 1;
            %         DayContour = tVlocal(3);
            %     else
            %         aa = aa + 1;
            %     end
            %     hr(aa) = teDay/3600;
            %     wPk(:,aa) = w;
            %     if aa > 1
%         yMin = fAdj(1); yMax = fAdj(length(fAdj));
%         axes(handles.axsContour);
%         if aa==a; hA = area([0 hr(2)], [yMax yMax]); else hA = area([0 0], [yMax yMax]); end
%         set(hA,'FaceColor',[.70 .70 .70],'LineStyle','none');
%         hold on;
%         [~, hC] = contourf(hr, fAdj, wPk, V);
%         set(hC, 'LineStyle', 'none');
%         colorbar;
%         caxis([min(V) max(V)]);
%         title(['Measured Signal Powers, ' datestr(tVlocal, 1)])
%         xlabel('Hour');
%         ylabel(['f (' fUnits ')']);
%         xlim([0 24]);
%         ylim([yMin yMax]);
%         set(handles.axsContour, 'Layer', 'top', 'XTick', 0:4:24);
%         grid on;
%         clear yMin yMax hA hC
%         hold off;
%     end
%     
%     % Write JSON Data message
%     Comment = getappdata(handles.figure1, 'Comment');
%     if Out.JSON4MSOD
%         Data.t = t;  % Time stamp cal
%         Data.Processed = 'True';
%         Data.t1 = t1;
%         Data.a = a;
%         Data.OL = OL;
%         Data.wnI = MwnPkI;
%         Data.Comment = Comment;
%         filename = [Out.Prefix zzz2str(FileNum,6) 'DataProc.json'];
%         savejson('', Data, filename);
%         WriteDataBlock2File(filename, wI, Data.DataType);
%         clear filename
%         if a == 1
%             Data.Processed = 'False';
%             filename = [Out.Prefix zzz2str(FileNum,6) 'DataRaw.json'];
%             savejson('', Data, filename);
%             WriteDataBlock2File(filename, w, Data.DataType);
%             clear filename fid
%         end
%     end
%     
%     % Write MAT output file
%     if Out.MAT4DBG; save([Out.Prefix zzz2str(FileNum,6) 'DBG.mat']); end
%     
%     % Update file number, init.mat, and acq counter
%     FileNum = FileNum + 1;
%     Out.StartFileNum = FileNum;
%     
%     handles.SMeasure = Sys; handles.LMeasure = Loc; handles.OMeasure = Out;
%     handles.CMeasure = Comment; handles.WMeasure = IP;
%     
%     WriteInitFile('init.json', Sys, Loc, Out, IP, Comment);
%     a = a + 1;
%     
% 
%     if getappdata(handles.figure1, 'state') == 0
%         set(handles.measurementStop, 'Enable', 'off');
%         set(handles.txtStatus,'BackgroundColor','red');
%         set(handles.txtStatus,'String','Measurement idle');
%         set(handles.measurementStart, 'Enable', 'on');
%         drawnow
%         %SA_Close(SAiObj, SAdObj);
%     end
%     
%     guidata(hObject, handles);
%     
%     
% end

% --------------------------------------------------------------------
function measurementStop_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to measurementStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

setappdata(handles.figure1, 'state', 0); %I can Remove These Now!!

sq = questdlg('Would you like to stop INDIVIDUAL TIMERS or ALL of the TIMERS?','Timer Stop','Individual','All','All');


if isempty(sq)
    return;
end

switch sq
    case 'Individual'
        set(hObject,'String',Changed);
        Current.Prefix = Changed;
        handles.OMeasure = Current;
    case 'All'
        set(hObject,'String',Current.Prefix);
end

guidata(handles.figure1, handles);
% set(handles.measurementStart, 'Enable', 'on');
% set(handles.measurementStop, 'Enable', 'off');
% set(handles.txtStatus,'BackgroundColor','yellow');
% set(handles.txtStatus,'String','System will shutdown after current measurement cycle');
% guidata(hObject, handles);
% drawnow
%SA_Close(SAiObj, SAdObj);


% --- Executes on selection change in popBand.
function popBand_Callback(hObject, eventdata, handles)
% hObject    handle to popBand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popBand contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popBand


band = get(handles.popBand,'Value'); rPar = RadarParameters(band);

switch band
    case 1
        Sys = handles.ASR;
    case 2
        Sys = handles.BoatNav;
    case 3
        Sys = handles.SPN43;
end

set(handles.edtRadarParameters,'String',[rPar.Name ': T_A = ' num2str(rPar.TA) ' s/rot, PI = ' num2str(1000*rPar.PI) ' ms, PW = ' num2str(1e6*rPar.PW) ' us']);
mPar = MeasParameters(band);
set(handles.edtfStart,'String',num2str(mPar.fStart/1e6));
set(handles.edtfStop,'String',num2str(mPar.fStop/1e6));
set(handles.edtNfreqs,'String',num2str(mPar.n));
set(handles.edtRBW,'String',num2str(mPar.RBW/1e6));
set(handles.edtDet,'String',mPar.Det);
set(handles.edttd,'String',num2str(mPar.td));

contents = cellstr(get(handles.popTime,'String'));
A = find(strcmp(Sys.Cal.MeasCycle,contents));

set(handles.edtCalsPerHour,'String',num2str(Sys.Cal.CalsPerHour));
set(handles.popTime,'Value',A);

drawnow

guidata(hObject, handles);



function edtCalsPerHour_Callback(hObject, eventdata, handles)
% hObject    handle to edtCalsPerHour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edtCalsPerHour as text
%        str2double(get(hObject,'String')) returns contents of edtCalsPerHour as a double

band = get(handles.popBand, 'Value'); cph = str2double(get(hObject,'String'));

switch band
    case 1
        Sys = handles.ASR;
        Sys.Cal.CalsPerHour = cph;
        handles.ASR = Sys;
    case 2
        Sys = handles.BoatNav;
        Sys.Cal.CalsPerHour = cph;
        handles.BoatNav = Sys;
    case 3
        Sys = handles.SPN43;
        Sys.Cal.CalsPerHour = cph;
        handles.SPN43 = Sys;
end

guidata(hObject, handles);


% --- Executes on selection change in popTime.
function popTime_Callback(hObject, eventdata, handles)
% hObject    handle to popTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popTime contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popTime

contents = cellstr(get(hObject,'String')); band = get(handles.popBand, 'Value'); 
band2 = get(handles.popTime, 'Value'); cph = contents{band2};

switch band
    case 1
        Sys = handles.ASR;
        Sys.Cal.MeasCycle = cph;
        handles.ASR = Sys;
    case 2
        Sys = handles.BoatNav;
        Sys.Cal.MeasCycle = cph;
        handles.BoatNav = Sys;
    case 3
        Sys = handles.SPN43;
        Sys.Cal.MeasCycle = cph;
        handles.SPN43 = Sys;
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function popTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupDataType.
function popupDataType_Callback(hObject, eventdata, handles)
% hObject    handle to popupDataType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupDataType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupDataType

contents = cellstr(get(hObject,'String')); band = get(handles.popBand, 'Value'); 
band2 = get(handles.popupDataType, 'Value'); cph = contents{band2};

switch band
    case 1
        Sys = handles.ASR;
        Sys.Cal.DataType = cph;
        handles.ASR = Sys;
    case 2
        Sys = handles.BoatNav;
        Sys.Cal.DataType = cph;
        handles.BoatNav = Sys;
    case 3
        Sys = handles.SPN43;
        Sys.Cal.DataType = cph;
        handles.SPN43 = Sys;
end

guidata(hObject, handles);


% --- Executes on selection change in popupByteOrder.
function popupByteOrder_Callback(hObject, eventdata, handles)
% hObject    handle to popupByteOrder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupByteOrder contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupByteOrder

contents = cellstr(get(hObject,'String')); band = get(handles.popBand, 'Value'); 
band2 = get(handles.popupByteOrder, 'Value'); cph = contents{band2};

switch band
    case 1
        Sys = handles.ASR;
        Sys.Cal.ByteOrder = cph;
        handles.ASR = Sys;
    case 2
        Sys = handles.BoatNav;
        Sys.Cal.ByteOrder = cph;
        handles.BoatNav = Sys;
    case 3
        Sys = handles.SPN43;
        Sys.Cal.ByteOrder = cph;
        handles.SPN43 = Sys;
end

guidata(hObject, handles);


% --- Executes on selection change in popupCompress.
function popupCompress_Callback(hObject, eventdata, handles)
% hObject    handle to popupCompress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupCompress contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupCompress

contents = cellstr(get(hObject,'String')); band = get(handles.popBand, 'Value'); 
band2 = get(handles.popupCompress, 'Value'); cph = contents{band2};

switch band
    case 1
        Sys = handles.ASR;
        Sys.Cal.popupCompress = cph;
        handles.ASR = Sys;
    case 2
        Sys = handles.BoatNav;
        Sys.Cal.popupCompress = cph;
        handles.BoatNav = Sys;
    case 3
        Sys = handles.SPN43;
        Sys.Cal.popupCompress = cph;
        handles.SPN43 = Sys;
end

guidata(hObject, handles);



function edtPrefix_Callback(hObject, eventdata, handles)
% hObject    handle to edtPrefix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edtPrefix as text
%        str2double(get(hObject,'String')) returns contents of edtPrefix as a double

Current = handles.OMeasure; Changed = get(hObject,'String');
qd = questdlg(sprintf('You have just changed the Filename Prefix from %s to %s. Is this correct?',Current.Prefix,Changed),'Value Change','Yes','No','Yes');

if isempty(qd)
    return;
end

switch qd
    case 'Yes'
        set(hObject,'String',Changed);
        Current.Prefix = Changed;
        handles.OMeasure = Current;
    otherwise
        set(hObject,'String',Current.Prefix);
end

guidata(handles.figure1, handles);



function edtVerMSOD_Callback(hObject, eventdata, handles)
% hObject    handle to edtVerMSOD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edtVerMSOD as text
%        str2double(get(hObject,'String')) returns contents of edtVerMSOD as a double

Current = handles.LMeasure; Changed = get(hObject,'String');
qd = questdlg('Changing this Value Modifies All Messages. Are you sure you want to CONTINUE?','Value Change','Yes','No','Yes');

if isempty(qd)
    return;
end

switch qd
    case 'Yes'
        set(hObject,'String',Changed);
        Current.Ver = Changed;
        handles.LMeasure = Current;
    otherwise
        set(hObject,'String',Current.Ver);
end

guidata(handles.figure1, handles);

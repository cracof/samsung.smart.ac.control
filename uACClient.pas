unit uACClient;

interface

uses System.SysUtils, Vcl.ExtCtrls, System.Generics.Collections, System.Threading, System.Classes,
     IdTCPClient, IdSSLOpenSSL, XMLIntf, XMLDoc;

type
  TNotifyLevel = (nlError, nlWarning, nlInfo, nlDebug);

  TOperationMode = (omAuto, omCool, omDry, omWind, omHeat);
  TConvenientMode = (cmOff, cmQuiet, cmSleep, cmSmart, cmSoftCool, cmTurboMode, cmWindMode1, cmWindMode2, cmWindMode3);
  TWindLevel = (wlAuto, wlLow, wlMid, wlHigh);
  
  TSamsungACException = class(Exception);
  TOnNotifyMessaging = procedure (notifyLevel: TNotifyLevel; const method, textMsg: string) of object;
  TOnDeviceStatus = procedure (AAttributesList: TDictionary<string,string>) of object;
  TOnTokenProcess = procedure (const AStatus, AToken: string; AErrorNo: Word = 0) of object;
  TOnAfterDeviceControl = procedure (const AStatus, ACommandId: string) of object;

  TAirConditioner = class
  private
    FHost: string;
    FMac: string;
    FDescroption: string;
    FPort: integer;
    FToken: string;

    TimerTCP: TTimer;
    FTcpClient: TIdTCPClient;
    FIdSSLIOHandlerSocketOpenSSL: TIdSSLIOHandlerSocketOpenSSL;
    fRxQueue: TQueue<String>;
    procRead: ITask;
    FOnNotifyMessaging : TOnNotifyMessaging;
    FOnDeviceStatus: TOnDeviceStatus;
    FOnRebootRequired: TOnTokenProcess;
    FOnAfterDeviceControl: TOnAfterDeviceControl;
    xmlResponse: IXMLDocument;
    FAttributesDict: TDictionary<string,string>;
    FOperationModeDict: TDictionary<TOperationMode, string>;
    FConvenientModeDict: TDictionary<TConvenientMode, string>;
    FWindLevelDict: TDictionary<TWindLevel, string>;

    procedure hndOnTimer(Sender: TObject);
    procedure hndOnTCPConnect(Sender: TObject);
    procedure hndOnTCPDisconnect(Sender: TObject);
    procedure prepareTaskForTCPClient;
    procedure prepareDictionaries;
    
    procedure RetrieveCommand(const cmd: string);
    procedure ExecuteCommand(const cmd: string);
    procedure SendCommand(const cmd: string);
    procedure NotifyMessaging(notifyLevel: TNotifyLevel; const method, textMsg: string);
    procedure NotifyDeviceStatus(attributesList: TDictionary<string,string>);
    procedure NotifyTokenProcess(const AStatus, AToken: string; AErrorNo: Word = 0);
    procedure NotifyAfterDeviceControl(const AStatus, ACommandId: string);
    procedure ClerBuffers;
    procedure SaveToken(const token: string);
    procedure deviceControl(const cmd, value: string);
    function generateId: integer;
    procedure Login;
    procedure parseXMLResponse(const xml: string);

  public
    constructor Create(const AHost, AMac, ADescription: string); overload;
    constructor Create(const AHost, AMac, ADescription, AToken: string); overload;
    destructor Destroy; override;

    function Connect: Boolean;
    procedure PowerOn;
    procedure PowerOff;
    procedure DeviceStatus;
    procedure SetTemperature(temperature: byte);
    procedure OperationMode(mode: TOperationMode);
    procedure SPI(Active: Boolean);
    procedure ConvenientMode(mode: TConvenientMode);
    procedure WindLevel(level: TWindLevel);
    procedure Sleep(minutes: Word);

    property OnNotifyLevel: TOnNotifyMessaging read FOnNotifyMessaging write FOnNotifyMessaging;
    property OnDeviceStatus: TOnDeviceStatus read FOnDeviceStatus write FOnDeviceStatus;
    property OnTokenProcess: TOnTokenProcess read FOnRebootRequired write FOnRebootRequired;
    property OnAfterDeviceControl: TOnAfterDeviceControl read FOnAfterDeviceControl write FOnAfterDeviceControl;

  end;

implementation

uses
  System.Variants;

resourcestring
  xmlMarker = '<?xml version="1.0" encoding="utf-8" ?>';

{ TAirConditioner }

function TAirConditioner.Connect: Boolean;
begin
  Result := False;
  try
    if not FTcpClient.Connected then
        FTcpClient.Connect;
  except
    on e:exception do
    begin
      FTcpClient.Disconnect;
      NotifyMessaging(nlError, 'TAirConditioner.Connect', e.Message);
    end;
  end;
  Result := FTcpClient.Connected;
end;

procedure TAirConditioner.ConvenientMode(mode: TConvenientMode);
var
  smodeNew, smodeCurr: string;
begin
  if FConvenientModeDict.TryGetValue(mode, smodeNew) then
    if FAttributesDict.TryGetValue('AC_FUN_COMODE', smodeCurr) and not smodeCurr.Equals(smodeNew) then
      deviceControl('AC_FUN_COMODE', smodeNew);
end;

constructor TAirConditioner.Create(const AHost, AMac, ADescription, AToken: string);
begin
  Create(AHost, AMac, ADescription);
  FToken := AToken;
end;

constructor TAirConditioner.Create(const AHost, AMac, ADescription: string);
begin
  inherited Create();
  FHost := AHost;
  FMac := AMac;
  FPort := 2878;
  FDescroption := ADescription;
  fRxQueue := TQueue<string>.Create;
  xmlResponse := TXMLDocument.Create(nil);
  FAttributesDict := TDictionary<string,string>.Create();
  FOperationModeDict := TDictionary<TOperationMode, string>.Create();
  FConvenientModeDict := TDictionary<TConvenientMode, string>.Create();
  FWindLevelDict := TDictionary<TWindLevel, string>.Create();


  FIdSSLIOHandlerSocketOpenSSL := TIdSSLIOHandlerSocketOpenSSL.Create;

  TimerTCP := TTimer.Create(nil);
  TimerTCP.Enabled := False;
  TimerTCP.Interval := 100;
  TimerTCP.OnTimer := hndOnTimer;

  FTcpClient := TIdTCPClient.Create();
  FTcpClient.IOHandler := FIdSSLIOHandlerSocketOpenSSL;
  FTcpClient.ConnectTimeout := 5000;
  FTcpClient.Port := FPort;
  FTcpClient.Host := FHost;
  FTcpClient.OnConnected := hndOnTCPConnect;
  FTcpClient.OnDisconnected := hndOnTCPDisconnect;
  prepareTaskForTCPClient;
  prepareDictionaries;

end;

destructor TAirConditioner.Destroy;
begin
  ClerBuffers();

  if FTcpClient.Connected then
    FTcpClient.Disconnect;

  xmlResponse.Active := False;
  xmlResponse := nil;

  FWindLevelDict.Free;
  FOperationModeDict.Free;
  FConvenientModeDict.Free;
  FAttributesDict.Free;
  fRxQueue.Free;
  FTcpClient.Free;
  FIdSSLIOHandlerSocketOpenSSL.Free;
  TimerTCP.Free;

  inherited Destroy;
end;

procedure TAirConditioner.ClerBuffers;
begin
  if Assigned(procRead) then
  begin
    procRead.Cancel;
    repeat
      sleep(10)
    until procRead = nil;
  end;
  TimerTCP.Enabled := False;
  fRxQueue.Clear;
end;

procedure TAirConditioner.ExecuteCommand(const cmd: string);
begin
  if cmd.StartsWith(xmlMarker) then
    parseXMLResponse(cmd.Replace(xmlMarker, EmptyStr));
end;

procedure TAirConditioner.hndOnTCPConnect(Sender: TObject);
begin
  NotifyMessaging(nlDebug, 'TCP Client', 'TCP connected to ' + FHost);
  TimerTCP.Enabled := True;
  fRxQueue.TrimExcess;
  procRead.Start;
end;

procedure TAirConditioner.hndOnTCPDisconnect(Sender: TObject);
begin
  NotifyMessaging(nlDebug, 'TCP Client', 'TPC disconnected');
end;

procedure TAirConditioner.hndOnTimer(Sender: TObject);
begin
  if (fRxQueue.Count > 0) then
    ExecuteCommand(fRxQueue.Extract);
end;

procedure TAirConditioner.Login;
begin
  SendCommand(Format('<Request Type="AuthToken"><User Token="%s" /></Request>', [FToken]));
  NotifyMessaging(nlDebug, 'Login succesfull', 'token: ' + FToken);
end;

procedure TAirConditioner.NotifyAfterDeviceControl(const AStatus, ACommandId: string);
begin
  if Assigned(OnAfterDeviceControl) then
    OnAfterDeviceControl(AStatus, ACommandId);
end;

procedure TAirConditioner.NotifyDeviceStatus(attributesList: TDictionary<string,string>);
begin
  if Assigned(OnDeviceStatus) then
    OnDeviceStatus(attributesList);
end;

procedure TAirConditioner.NotifyMessaging(notifyLevel: TNotifyLevel; const method, textMsg: string);
begin
  if Assigned(OnNotifyLevel) then
    OnNotifyLevel(notifyLevel, method, textMsg);
end;

procedure TAirConditioner.NotifyTokenProcess(const AStatus, AToken: string; AErrorNo: Word = 0);
begin
  if Assigned(OnTokenProcess) then
    OnTokenProcess(AStatus, AToken, AErrorNo);
end;

procedure TAirConditioner.parseXMLResponse(const xml: string);
var
  s, &type, status: string;
  rootNode, helpNode, atrNode: IXMLNode;
  list: TDictionary<string,string>;
  i: integer;
begin
{
// X after connect: <Update Type="InvalidateAccount"/>
// X token request 1: <Response Type="GetToken" Status="Ready"/>
// X token request 2: <Update Type="GetToken" Status="Completed" Token=""/>

// status: <Update Type="Status"><Status DUID="7825AD127FE40000" GroupID="AC" ModelID="AC"><Attr ID="AC_FUN_TEMPNOW" Value="23" /></Status></Update>
// X errors: <Response Satus="Fail" Type="Authenticate" ErrorCode="301" />

// X total status: <Response Type="DeviceState" Status="Okay"><DeviceState><Device DUID="7825AD127FE4" GroupID="AC" ModelID="AC" ><Attr ID="AC_FUN_ENABLE" Type="RW" Value="Enable"/><Attr ID="AC_FUN_POWER" Type="RW" Value="On"/><Attr ID="AC_FUN_SUPPORTED" Type="R" Value="0"/><Attr ID="AC_FUN_OPMODE" Type="RW" Value="Heat"/><Attr ID="AC_FUN_TEMPSET" Type="RW" Value="20"/><Attr ID="AC_FUN_COMODE" Type="RW" Value="Off"/><Attr ID="AC_FUN_ERROR" Type="RW" Value="00000000"/><Attr ID="AC_FUN_TEMPNOW" Type="R" Value="23"/><Attr ID="AC_FUN_SLEEP" Type="RW" Value="0"/><Attr ID="AC_FUN_WINDLEVEL" Type="RW" Value="Low"/>
//<Attr ID="AC_FUN_DIRECTION" Type="RW" Value="Fixed"/><Attr ID="AC_ADD_AUTOCLEAN" Type="RW" Value="Off"/><Attr ID="AC_ADD_APMODE_END" Type="W" Value="0"/><Attr ID="AC_ADD_STARTWPS" Type="RW" Value="Default"/><Attr ID="AC_ADD_SPI" Type="RW" Value="Off"/><Attr ID="AC_SG_WIFI" Type="W" Value="Connected"/><Attr ID="AC_SG_INTERNET" Type="W" Value="Connected"/><Attr ID="AC_ADD2_VERSION" Type="RW" Value="0"/><Attr ID="AC_SG_MACHIGH" Type="W" Value="0"/><Attr ID="AC_SG_MACMID" Type="W" Value="0"/><Attr ID="AC_SG_MACLOW" Type="W" Value="0"/><Attr ID="AC_SG_VENDER01" Type="W" Value="0"/><Attr ID="AC_SG_VENDER02" Type="W" Value="0"/><Attr ID="AC_SG_VENDER03" Type="W" Value="0"/></Device></DeviceState></Response>

// X <Response Type="DeviceControl" Status="Okay" DUID="7825AD127FE4" CommandID="cmd5459"/>
// X <Response Type="AuthToken" Status="Okay" StartFrom="2017-10-28/14:31:11"/>
}
  list := nil;
  xmlResponse.LoadFromXML(xml);
  try
    try
      rootNode := xmlResponse.DocumentElement;
      s := xmlResponse.DocumentElement.NodeName;

      if Assigned(rootNode) then
      begin

        if rootNode.NodeName.Equals('Response') then
        begin
          &type := VarToStr(rootNode.Attributes['Type']);
          status := VarToStr(rootNode.Attributes['Status']);

          //response for reboot after token request
          if &type.Equals('GetToken') and status.Equals('Ready') then
            NotifyTokenProcess(status, EmptyStr)

          //response for device status
          else if &type.Equals('DeviceState') and Assigned(rootNode.ChildNodes.Nodes['DeviceState'])
          and Assigned(rootNode.ChildNodes.Nodes['DeviceState'].ChildNodes.Nodes['Device']) then
          begin
            helpNode := rootNode.ChildNodes.Nodes['DeviceState'].ChildNodes.Nodes['Device'];
            list := TDictionary<string,string>.Create;
            atrNode := helpNode.ChildNodes.First;
            while Assigned(atrNode) do
            begin
              FAttributesDict.AddOrSetValue(atrNode.Attributes['ID'], atrNode.Attributes['Value']);
              if atrNode.HasAttribute('ID') and atrNode.HasAttribute('Value') then
                list.AddOrSetValue(atrNode.Attributes['ID'], atrNode.Attributes['Value']);
              atrNode := atrNode.NextSibling;
            end;
            NotifyDeviceStatus(list);
          end

          //authenticate error
          else if &type.Equals('Authenticate') and status.Equals('Fail') then
            NotifyTokenProcess(status, EmptyStr, VarToStr(rootNode.Attributes['ErrorCode']).ToInteger)

          // succesfull login
          else if &type.Equals('AuthToken') and status.Equals('Okay') then
          begin
            DeviceStatus();
            NotifyTokenProcess(status, EmptyStr)
          end

          // after device control
          else if &type.Equals('DeviceControl') and status.Equals('Okay') then
            NotifyAfterDeviceControl(status, VarToStr(rootNode.Attributes['CommandID']));

        end else if rootNode.NodeName.Equals('Update') then
        begin
          &type := VarToStr(rootNode.Attributes['Type']);
          status := VarToStr(rootNode.Attributes['Status']);

          // after connect - login or new token request
          if &type.Equals('InvalidateAccount') then
          begin
            if FToken.IsEmpty then
              SendCommand('<Request Type="GetToken" />')
            else Login;
          end
          // after new token
          else if &Type.Equals('GetToken') and Status.Equals('Completed') then
            NotifyTokenProcess(status, VarToStr(rootNode.Attributes['Token']))

          // ac notify self status
          else if &Type.Equals('Status') and Assigned(rootNode.ChildNodes.Nodes['Status']) then
          begin
            helpNode := rootNode.ChildNodes.Nodes['Status'];
            list := TDictionary<string,string>.Create;
            atrNode := helpNode.ChildNodes.First;
            while Assigned(atrNode) do
            begin
              FAttributesDict.AddOrSetValue(atrNode.Attributes['ID'], atrNode.Attributes['Value']);
              if atrNode.HasAttribute('ID') and atrNode.HasAttribute('Value') then
                list.AddOrSetValue(atrNode.Attributes['ID'], atrNode.Attributes['Value']);
              atrNode := atrNode.NextSibling;
            end;
            NotifyDeviceStatus(list);
          end;

        end else
          NotifyMessaging(nlWarning, 'XML node unrecognized: ', rootNode.NodeName);
      end;

    finally
      list.Free;
      helpNode := nil;
      rootNode := nil;
    end;
  except
    on e:exception do
      NotifyMessaging(nlError, 'TAirConditioner.parseXMLResponse', e.Message);
  end;

end;

procedure TAirConditioner.PowerOff;
var
  state: string;
begin
  if FAttributesDict.TryGetValue('AC_FUN_POWER', state) and state.Equals('On') then
    deviceControl('AC_FUN_POWER', 'Off');
end;

procedure TAirConditioner.PowerOn;
var
  state: string;
begin
  if FAttributesDict.TryGetValue('AC_FUN_POWER', state) and state.Equals('Off') then
    deviceControl('AC_FUN_POWER', 'On');
end;

procedure TAirConditioner.prepareDictionaries;
begin
  with FOperationModeDict do
  begin
    Add(omAuto, 'Auto');
    Add(omCool, 'Cool');
    Add(omDry, 'Dry');
    Add(omWind, 'Wind');
    Add(omHeat, 'Heat');
  end;

  with FConvenientModeDict do
  begin
    Add(cmOff, 'Off');
    Add(cmQuiet, 'Quiet');
    Add(cmSleep, 'Sleep');
    Add(cmSmart, 'Smart');
    Add(cmSoftCool, 'SoftCool');
    Add(cmTurboMode, 'TurboMode');
    Add(cmWindMode1, 'WindMode1');  
    Add(cmWindMode2, 'WindMode2');
    Add(cmWindMode3, 'WindMode3');
  end;

  with FWindLevelDict do
  begin
    Add(wlAuto, 'Auto');
    Add(wlLow, 'Low');
    Add(wlMid, 'Mid');
    Add(wlHigh, 'High');
  end;
end;

procedure TAirConditioner.prepareTaskForTCPClient;
begin
  procRead := TTask.Create(procedure
    begin
      repeat
        with FTcpClient do
        begin
          try
            procRead.CheckCanceled; // makes EOperationCancelled
            //procRead.Wait(100);
            if IOHandler.InputBufferIsEmpty then
            begin
              IOHandler.CheckForDataOnSource(0);
              IOHandler.CheckForDisconnect;
              if IOHandler.InputBufferIsEmpty then continue;
            end;
            TThread.Synchronize (nil,
              procedure
              begin
                RetrieveCommand(FTcpClient.IOHandler.ReadLn);
              end);
          except
            on e: EOperationCancelled do
            begin
              IOHandler.CloseGracefully;
              IOHandler.Close;
              procRead := nil;
              exit;
            end;
            on e: exception do
              NotifyMessaging(nlError, 'TAirConditioner.prepareTaskForTCPClient', e.Message);
          end;
        end;
      until not FTcpClient.Connected;
    end);
end;

procedure TAirConditioner.RetrieveCommand(const cmd: string);
begin
  if Assigned(FOnNotifyMessaging) then
    FOnNotifyMessaging(nlDebug, 'Received command', cmd);
  if cmd.StartsWith(xmlMarker) then
    fRxQueue.Enqueue(cmd);
end;

procedure TAirConditioner.SaveToken(const token: string);
begin
  NotifyMessaging(nlInfo, 'Received new token', token);
  FToken := token;
end;

procedure TAirConditioner.SendCommand(const cmd: string);
begin
  try
    if (Length(cmd) > 0) and FTcpClient.Connected then
    begin
      NotifyMessaging(nlDebug, 'Sending request...', cmd);
      FTcpClient.IOHandler.WriteLn(cmd, nil);
    end;
  except
    on e:exception do
    begin
      ClerBuffers();
      FTcpClient.Disconnect;
      NotifyMessaging(nlError, 'TAirConditioner.SendCommand', e.Message);
    end;
  end;
end;

procedure TAirConditioner.OperationMode(mode: TOperationMode);
var
  smodeNew, smodeCurr: string;
begin
  if FOperationModeDict.TryGetValue(mode, smodeNew) then
    if FAttributesDict.TryGetValue('AC_FUN_OPMODE', smodeCurr) and not smodeCurr.Equals(smodeNew) then
      deviceControl('AC_FUN_OPMODE', smodeNew);
end;

procedure TAirConditioner.SPI(Active: Boolean);
var
 currState, newState: string;
begin
  if Active then newState := 'On'
    else newState := 'Off';

  if FAttributesDict.TryGetValue('AC_ADD_SPI', currState) and not currState.Equals(newState) then
    deviceControl('AC_ADD_SPI', newState);
end;

procedure TAirConditioner.WindLevel(level: TWindLevel);
var
  smodeNew, smodeCurr: string;
begin
  if FWindLevelDict.TryGetValue(level, smodeNew) then
    if FAttributesDict.TryGetValue('AC_FUN_WINDLEVEL', smodeCurr) and not smodeCurr.Equals(smodeNew) then
      deviceControl('AC_FUN_WINDLEVEL', smodeNew);
end;

procedure TAirConditioner.SetTemperature(temperature: byte);
var
  s: string;
begin
  if temperature in [16..30] then
    deviceControl('AC_FUN_TEMPSET', temperature.ToString)
  else
  begin
    s := Format('Allowed temperature is between %d and %d', [16, 30]);
    NotifyMessaging(nlError, 'Bad command', s);
    raise TSamsungACException.Create(s);
  end;
end;

procedure TAirConditioner.Sleep(minutes: Word);
begin
  deviceControl('AC_FUN_SLEEP', minutes.ToString);
end;

function TAirConditioner.generateId: integer;
begin
  Result := Random(10000);
end;

procedure TAirConditioner.deviceControl(const cmd, value: string);
var
  s: string;
begin
  s := Format('<Request Type="DeviceControl">'
    + '<Control CommandID="cmd%d" DUID="%s">'
    + '<Attr ID="%s" Value="%s" /></Control></Request>',
    [generateId, FMac, cmd, value]);
  SendCommand(s);
end;

procedure TAirConditioner.DeviceStatus;
begin
  SendCommand('<Request Type="DeviceState" DUID="' + FMac + '"></Request>');
end;

end.

unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdGlobal,
  Vcl.ExtCtrls, IdUDPServer, IdSocketHandle, uACClient, Vcl.WinXCtrls, IdComponent, IdBaseComponent, IdUDPBase,
  Vcl.Samples.Spin, XMLIntf, XMLDoc, System.Generics.Collections, uSSDPClient;

type
  TfrmMain = class(TForm)
    Memo1: TMemo;
    GroupBox1: TGroupBox;
    edIP: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    edMac: TEdit;
    btnConnect: TButton;
    btnSSDP: TButton;
    edDescr: TEdit;
    Label4: TLabel;
    gbDevice: TGroupBox;
    tgSwitch: TToggleSwitch;
    Label3: TLabel;
    seTemp: TSpinEdit;
    Label5: TLabel;
    lbTempNow: TLabel;
    cbxWiFi: TCheckBox;
    cbxInternet: TCheckBox;
    lbTempSet: TLabel;
    ActivityIndicator1: TActivityIndicator;
    lbIndicator: TLabel;
    Panel1: TPanel;
    Label6: TLabel;
    rbFMAuto: TRadioButton;
    rbFMCool: TRadioButton;
    rbFMDry: TRadioButton;
    rbFMWind: TRadioButton;
    rbFMHeat: TRadioButton;
    cbxSPI: TCheckBox;
    Panel2: TPanel;
    Label7: TLabel;
    rbCMOff: TRadioButton;
    rbCMQuiet: TRadioButton;
    rbCMSleep: TRadioButton;
    rbCMSmart: TRadioButton;
    rbCMSoftCool: TRadioButton;
    rbCMTurboMode: TRadioButton;
    rbCMWindMode1: TRadioButton;
    rbCMWindMode2: TRadioButton;
    rbCMWindMode3: TRadioButton;
    btnStatus: TButton;
    Panel3: TPanel;
    Label8: TLabel;
    rbWLAuto: TRadioButton;
    rbWLLow: TRadioButton;
    rbWLMid: TRadioButton;
    rbWLHigh: TRadioButton;
    Button1: TButton;
    lbError: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSSDPClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnStatusClick(Sender: TObject);
    procedure tgSwitchClick(Sender: TObject);
    procedure rbFMAutoClick(Sender: TObject);
    procedure rbFMCoolClick(Sender: TObject);
    procedure rbFMDryClick(Sender: TObject);
    procedure rbFMWindClick(Sender: TObject);
    procedure rbFMHeatClick(Sender: TObject);
    procedure seTempExit(Sender: TObject);
    procedure cbxSPIClick(Sender: TObject);
    procedure rbCMOffClick(Sender: TObject);
    procedure rbCMQuietClick(Sender: TObject);
    procedure rbCMSleepClick(Sender: TObject);
    procedure rbCMSmartClick(Sender: TObject);
    procedure rbCMSoftCoolClick(Sender: TObject);
    procedure rbCMTurboModeClick(Sender: TObject);
    procedure rbCMWindMode1Click(Sender: TObject);
    procedure rbCMWindMode2Click(Sender: TObject);
    procedure rbCMWindMode3Click(Sender: TObject);
    procedure rbWLAutoClick(Sender: TObject);
    procedure rbWLLowClick(Sender: TObject);
    procedure rbWLMidClick(Sender: TObject);
    procedure rbWLHighClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);

  private
    { Private declarations }
    samsung: TAirConditioner;
    ssdpFinder: TSSDPClient;

    FToken: string;

    procedure hndOnsamsungLog(notifyLevel: TNotifyLevel; const method, textMsg: string);
    procedure hndOnDeviceStatus (AAttributesList: TDictionary<string,string>);
    procedure hndOnAfterDeviceControl(const AStatus, ACommandId: string);
    procedure hndOnTokenProcess(const AStatus, AToken: string; AErrorNo: Word = 0);
    procedure hndOnSSDPFound(const AHost, AMac, ADescr: string);
    procedure hndOnSSDPError(const AErrorMessage: string);
    procedure createAcObject(const AHost, AMac, ADescription, AToken: string);
    procedure loadFromIni;
    procedure saveToIni;
    procedure indicator(const info: string);

  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

const
  INI_FILENAME = 'ac_data.ini';

implementation

{$R *.dfm}

uses
  System.RegularExpressions,
  System.IniFiles;

procedure TfrmMain.btnConnectClick(Sender: TObject);
begin
  if String(edIP.Text).IsEmpty or String(edMac.Text).IsEmpty then
    ShowMessage('Enter hostname and mac adress')
  else
    createAcObject(edIP.Text, edMac.Text, edDescr.Text, FToken);
end;

procedure TfrmMain.btnSSDPClick(Sender: TObject);
begin
  if not Assigned(ssdpFinder) then
  begin
    ssdpFinder := TSSDPClient.create();
    ssdpFinder.OnFoundDevice := hndOnSSDPFound;
    ssdpFinder.OnError := hndOnSSDPError;
  end;

  if ssdpFinder.StartSearch then
  begin
    hndOnsamsungLog(nlInfo, 'SSDP', 'Searching...');
    indicator('SSDP search ...');
    btnSSDP.Enabled := False;
  end
  else hndOnSSDPError('Already!!!');
end;

procedure TfrmMain.btnStatusClick(Sender: TObject);
begin
  samsung.DeviceStatus;
end;

procedure TfrmMain.Button1Click(Sender: TObject);
begin
  samsung.Sleep(10);
end;

procedure TfrmMain.rbCMOffClick(Sender: TObject);
begin
  samsung.ConvenientMode(cmOff);
end;

procedure TfrmMain.rbCMQuietClick(Sender: TObject);
begin
  samsung.ConvenientMode(cmQuiet);
end;

procedure TfrmMain.rbCMSleepClick(Sender: TObject);
begin
  samsung.ConvenientMode(cmSleep);
end;

procedure TfrmMain.rbCMSmartClick(Sender: TObject);
begin
  samsung.ConvenientMode(cmSmart);
end;

procedure TfrmMain.rbCMSoftCoolClick(Sender: TObject);
begin
  samsung.ConvenientMode(cmSoftCool);
end;

procedure TfrmMain.rbCMTurboModeClick(Sender: TObject);
begin
  samsung.ConvenientMode(cmTurboMode);
end;

procedure TfrmMain.rbFMAutoClick(Sender: TObject);
begin
  samsung.OperationMode(omAuto);
end;

procedure TfrmMain.rbFMCoolClick(Sender: TObject);
begin
  samsung.OperationMode(omCool);
end;

procedure TfrmMain.rbFMDryClick(Sender: TObject);
begin
  samsung.OperationMode(omDry);
end;

procedure TfrmMain.rbFMHeatClick(Sender: TObject);
begin
  samsung.OperationMode(omHeat);
end;

procedure TfrmMain.rbFMWindClick(Sender: TObject);
begin
  samsung.OperationMode(omWind);
end;

procedure TfrmMain.rbWLAutoClick(Sender: TObject);
begin
  samsung.WindLevel(wlAuto);
end;

procedure TfrmMain.rbWLHighClick(Sender: TObject);
begin
  samsung.WindLevel(wlHigh);
end;

procedure TfrmMain.rbWLLowClick(Sender: TObject);
begin
  samsung.WindLevel(wlLow);
end;

procedure TfrmMain.rbWLMidClick(Sender: TObject);
begin
  samsung.WindLevel(wlMid);
end;

procedure TfrmMain.rbCMWindMode1Click(Sender: TObject);
begin
  samsung.ConvenientMode(cmWindMode1);
end;

procedure TfrmMain.rbCMWindMode2Click(Sender: TObject);
begin
  samsung.ConvenientMode(cmWindMode2);
end;

procedure TfrmMain.rbCMWindMode3Click(Sender: TObject);
begin
  samsung.ConvenientMode(cmWindMode3);
end;

procedure TfrmMain.cbxSPIClick(Sender: TObject);
begin
  samsung.SPI(cbxSPI.Checked);
end;

procedure TfrmMain.createAcObject(const AHost, AMac, ADescription, AToken: string);
begin
  if Assigned(samsung) then
    samsung.Free;

  if FToken.IsEmpty then
    samsung := TAirConditioner.Create(AHost, AMac, ADescription)
  else samsung := TAirConditioner.Create(AHost, AMac, ADescription, AToken);

  samsung.OnNotifyLevel := hndOnsamsungLog;
  samsung.OnDeviceStatus := hndOnDeviceStatus;
  samsung.OnAfterDeviceControl := hndOnAfterDeviceControl;
  samsung.OnTokenProcess := hndOnTokenProcess;

  if samsung.Connect then
  begin
    btnSSDP.Enabled := False;
    btnConnect.Enabled := false;
    if not String(edDescr.Text).IsEmpty then
      gbDevice.Caption := Format('%s (%s) ', [edDescr.Text, edIp.Text])
    else gbDevice.Caption := Format('%s', [edIp.Text]);
    gbDevice.Enabled := True;
  end;
  
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  saveToIni;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  loadFromIni();
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  samsung.Free;
end;

procedure TfrmMain.indicator(const info: string);
begin
  lbIndicator.Caption := info;
  lbIndicator.Visible := not info.IsEmpty;
  ActivityIndicator1.Visible := not info.IsEmpty;
  ActivityIndicator1.Animate := not info.IsEmpty;
end;

procedure TfrmMain.loadFromIni;
var
  ini: TIniFile;
begin
  if FileExists(ExtractFilePath(ParamStr(0)) + INI_FILENAME) then
  begin
    ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + INI_FILENAME);
    try
      edIP.Text := ini.ReadString('1', 'host', EmptyStr);
      edMac.Text := ini.ReadString('1', 'mac', EmptyStr);
      edDescr.Text := ini.ReadString('1', 'descr', EmptyStr);
      FToken := ini.ReadString('1', 'token', EmptyStr);
    finally
      ini.Free;
    end;
  end;
end;

procedure TfrmMain.hndOnAfterDeviceControl(const AStatus, ACommandId: string);
begin
  hndOnsamsungLog(nlInfo, 'After device control: ', AStatus + ' ' + ACommandId);
end;

procedure TfrmMain.hndOnDeviceStatus(AAttributesList: TDictionary<string,string>);
var
  opMode, convMode, windLevel: string;
begin
  //hndOnsamsungLog(nlDebug, 'Device status:', AAttributesList.Ke);
  //AC_FUN_ENABLE=Enable,AC_FUN_POWER=On,AC_FUN_SUPPORTED=0,AC_FUN_OPMODE=Heat,AC_FUN_TEMPSET=22,AC_FUN_COMODE=Off,
  //AC_FUN_ERROR=00000000,AC_FUN_TEMPNOW=25,AC_FUN_SLEEP=0,AC_FUN_WINDLEVEL=Mid,AC_FUN_DIRECTION=Fixed,
  //AC_ADD_AUTOCLEAN=Off,AC_ADD_SPI=Off,
  
  //AC_SG_WIFI=Connected,AC_SG_INTERNET=Connected,AC_ADD_APMODE_END=0,AC_ADD_STARTWPS=Default
  //AC_ADD2_VERSION=0,AC_SG_MACHIGH=0,AC_SG_MACMID=0,AC_SG_MACLOW=0,AC_SG_VENDER01=0,AC_SG_VENDER02=0,AC_SG_VENDER03=0


  if AAttributesList.ContainsKey('AC_FUN_POWER') then
    if  AAttributesList.Items['AC_FUN_POWER'].Equals('On') then
      tgSwitch.State := tssOn
    else tgSwitch.State := tssOff;

  if AAttributesList.ContainsKey('AC_FUN_TEMPNOW') then
    lbTempNow.Caption := Format('current: %s °C', [AAttributesList.Items['AC_FUN_TEMPNOW']]);

  if AAttributesList.ContainsKey('AC_FUN_TEMPSET') then
  begin
    lbTempSet.Caption := Format('set: %s °C', [AAttributesList.Items['AC_FUN_TEMPSET']]);
    seTemp.Value := AAttributesList.Items['AC_FUN_TEMPSET'].ToInteger;
  end;

  if AAttributesList.ContainsKey('AC_ADD_SPI') then
    if AAttributesList.Items['AC_ADD_SPI'].Equals('On') then
      cbxSPI.Checked := True
    else cbxSPI.Checked := False;

  if AAttributesList.ContainsKey('AC_FUN_OPMODE') then
  begin
    opMode := AAttributesList.Items['AC_FUN_OPMODE'];
    if opMode.Equals('Auto') then
      rbFMAuto.Checked := True
    else if opMode.Equals('Cool') then
      rbFMCool.Checked := True
    else if opMode.Equals('Dry') then
      rbFMDry.Checked := True
    else if opMode.Equals('Wind') then
      rbFMWind.Checked := True
    else if opMode.Equals('Heat') then
      rbFMHeat.Checked := True;
  end;

  if AAttributesList.ContainsKey('AC_SG_WIFI') then
    if AAttributesList.Items['AC_SG_WIFI'].Equals('Connected') then
      cbxWiFi.Checked := True
    else cbxWiFi.Checked := False;

  if AAttributesList.ContainsKey('AC_SG_INTERNET') then
    if AAttributesList.Items['AC_SG_INTERNET'].Equals('Connected') then
      cbxInternet.Checked := True
    else cbxInternet.Checked := False;

  if AAttributesList.ContainsKey('AC_FUN_COMODE') then
  begin
    convMode := AAttributesList.Items['AC_FUN_COMODE'];
    if convMode.Equals('Off') then
      rbCMOff.Checked := True
    else if convMode.Equals('Quiet') then
      rbCMQuiet.Checked := True
    else if convMode.Equals('Sleep') then
      rbCMSleep.Checked := True
    else if convMode.Equals('Smart') then
      rbCMSmart.Checked := True
    else if convMode.Equals('SoftCool') then
      rbCMSoftCool.Checked := True
    else if convMode.Equals('TurboMode') then
      rbCMTurboMode.Checked := True
    else if convMode.Equals('WindMode1') then
      rbCMWindMode1.Checked  := True
    else if convMode.Equals('WindMode2') then
      rbCMWindMode2.Checked := True
    else if convMode.Equals('WindMode3') then
      rbCMWindMode3.Checked := True
  end;

  if AAttributesList.ContainsKey('AC_FUN_WINDLEVEL') then
  begin
    windLevel := AAttributesList.Items['AC_FUN_WINDLEVEL'];
    if windLevel.Equals('Auto') then
      rbWLAuto.Checked := True
    else if windLevel.Equals('Low') then
      rbWLLow.Checked := True
    else if windLevel.Equals('Mid') then
      rbWLMid.Checked := True
    else if windLevel.Equals('High') then
      rbWLHigh.Checked := True;
  end;

  if AAttributesList.ContainsKey('AC_FUN_ERROR') and not AAttributesList.Items['AC_FUN_ERROR'].Equals('00000000') then
  begin
    lbError.Caption := AAttributesList.Items['AC_FUN_ERROR'];
    lbError.Visible := True;
  end
  else lbError.Visible := False;

end;

procedure TfrmMain.hndOnsamsungLog(notifyLevel: TNotifyLevel; const method, textMsg: string);
var
  lvl: string;
begin
  case notifyLevel of
    nlError: lvl := 'ERROR';
    nlWarning: lvl := 'WARNING';
    nlInfo: lvl := 'INFO';
    nlDebug: lvl := '#DEBUG';
  end;
  // fast turn off messaging: lvl := '#DEBUG'
  if not lvl.StartsWith('#') then
    Memo1.Lines.Add(Format('%s: %s -> %s %s',[FormatDateTime('hh:nn:ss', Time), lvl, method, textMsg]));
end;

procedure TfrmMain.hndOnSSDPError(const AErrorMessage: string);
begin
  hndOnsamsungLog(nlError, 'SSDP', AErrorMessage);
  indicator(EmptyStr);
  btnSSDP.Enabled := True;
end;

procedure TfrmMain.hndOnSSDPFound(const AHost, AMac, ADescr: string);
begin
  hndOnsamsungLog(nlInfo, 'SSDP Found', AHost);
  edIP.Text := AHost;
  edMac.Text := AMac;
  edDescr.Text := ADescr;
  indicator(EmptyStr);
  btnSSDP.Enabled := True;
  FreeAndNil(ssdpFinder);
end;

procedure TfrmMain.hndOnTokenProcess(const AStatus, AToken: string; AErrorNo: Word);
begin
  hndOnsamsungLog(nlInfo, 'Token Process', AStatus + ' ' + AToken + ' ' + AErrorNo.ToString);
  if AStatus.Equals('Ready') then
    hndOnsamsungLog(nlInfo, 'Token Process', 'Reboot device in 20 sec')
  else if AStatus.Equals('Completed') then
  begin
    hndOnsamsungLog(nlInfo, 'Token Process', 'Recieved new token ' + AToken);
    if not AToken.IsEmpty then
      FToken := AToken;
  end;

end;

procedure TfrmMain.saveToIni;
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + INI_FILENAME);
  try
    try
      ini.WriteString('1', 'host', edIP.Text);
      ini.WriteString('1', 'mac', edMac.Text);
      ini.WriteString('1', 'descr', edDescr.Text);
      ini.WriteString('1', 'token', FToken);
    finally
      ini.Free;
    end;
  except
    on e:exception do
      ShowMessage('Unable save settings to file: ' + e.Message);
  end;
end;

procedure TfrmMain.seTempExit(Sender: TObject);
begin
  ///todo: not OnExit, debounce will be better
  samsung.SetTemperature(seTemp.Value);
end;

procedure TfrmMain.tgSwitchClick(Sender: TObject);
begin
  if tgSwitch.State = tssOn then
    samsung.PowerOn
  else if tgSwitch.State = tssOff then
    samsung.PowerOff;
end;

end.

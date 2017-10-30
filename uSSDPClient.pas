unit uSSDPClient;

interface

uses System.Classes, System.SysUtils, IdUDPServer, IdSocketHandle, IdGlobal,
     System.Threading, System.DateUtils;

type
  TOnFoundDevice = procedure (const AHost, AMac, ADescr: string) of object;
  TOnError = procedure (const AErrorMessage: string) of object;

  TSSDPClient = class
  private
    FUDPServer: TIdUDPServer;
    FSearching: Boolean;
    FOnFoundFevice: TOnFoundDevice;
    FOnError: TOnError;
    FWatchDog: ITask;

    function ssdpNotifyPacket: string;
    procedure hndUDPServerUDPRead(AThread: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure NotifyOnFoundDevice(const AHost, AMac, ADescr: string);
    procedure NotifyOnError(const AErrorMessage: string);

  public
    constructor Create;
    function StartSearch: Boolean;
    property OnFoundDevice: TOnFoundDevice read FOnFoundFevice write FOnFoundFevice;
    property OnError: TOnError read FOnError write FOnError;
  end;

implementation

{ TSSDPClient }

constructor TSSDPClient.Create;
var
  socket: TIdSocketHandle;
begin
  inherited;
  FSearching := False;

  FUDPServer := TIdUDPServer.Create(nil);
  FUDPServer.Bindings.Clear;
  FUDPServer.BroadcastEnabled := true;
  FUDPServer.ThreadedEvent := True;
  FUDPServer.Bindings.DefaultPort := 1900;
  FUDPServer.OnUDPRead := hndUDPServerUDPRead;

  socket := FUDPServer.Bindings.Add;
  socket.IP := '0.0.0.0';
  socket.IPVersion := Id_IPv4;
  socket.Port := 1900;

end;

function TSSDPClient.StartSearch: Boolean;
begin
  if not FSearching then
  begin
    FSearching := True;
    FUDPServer.Active := true;

    // watchdog for search timeout
    FWatchDog := TTask.Create(procedure
    var
      endTime: TDateTime;
    begin
      endTime := AddMSecToTime(Now, 20000);
      repeat
        sleep(1);
        if FWatchDog.Status = TTaskStatus.Canceled then
          exit;
      until (Now > endTime);
      TThread.Queue(nil, procedure
      begin
        FUDPServer.Active := False;
        FSearching  := false;
        NotifyOnError('TimeOut');
      end);
    end);
    FWatchDog.Start;

    FUDPServer.Binding.Broadcast(ssdpNotifyPacket, 1900, '255.255.255.255');
    Result := True;
  end
  else  Result := False;
end;

function TSSDPClient.ssdpNotifyPacket: string;
begin
  result  :=
  'NOTIFY * HTTP/1.1' + #13#10 +
  'LOCATION: fe80::16dd:a9ff:fea3:9793%wlan0' + #13#10 +
  'HOST: 239.255.255.250:1900' + #13#10 +
  'CACHE-CONTROL: max-age=20' + #13#10 +
  'SERVER: AIR CONDITIONER' + #13#10 +
  'MAC_ADDR: 02:00:00:00:00:00' + #13#10 +
  'SPEC_VER: MSpec-1.00' + #13#10 +
  'SERVICE_NAME: ControlServer-MLib' + #13#10 +
  'MESSAGE_TYPE: CONTROLLER_START' + #13#10;
end;

procedure TSSDPClient.hndUDPServerUDPRead(AThread: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
var
  data, ip, mac, descr: string;
  list: TStringList;
begin
  data := BytesToString(AData);
  list := TStringList.Create;
  list.Delimiter := '@';
  try
    list.DelimitedText := data.Replace(#13#10, list.Delimiter).Replace(': ', '=');
    if list.Values['SERVICE_NAME'].Equals('ControlServer-MLib')
      and list.Values['MESSAGE_TYPE'].Equals('DEVICEDESCRIPTION') then
    begin
      ip := list.Values['LOCATION'].Replace('http://', EmptyStr);
      mac := list.Values['MAC_ADDR'];
      descr := list.Values['SERVER'].Replace('SSDP,', EmptyStr);

      TThread.Queue(nil, procedure
      begin
        FUDPServer.Active := False;
        FSearching  := false;
        NotifyOnFoundDevice(ip, mac, descr);
      end);
    end;

  finally
    list.Free;
  end;
end;

procedure TSSDPClient.NotifyOnError(const AErrorMessage: string);
begin
  if Assigned(OnError) then
    OnError(AErrorMessage);
end;

procedure TSSDPClient.NotifyOnFoundDevice(const AHost, AMac, ADescr: string);
begin
  FWatchDog.Cancel;
  if Assigned(OnFoundDevice) then
    OnFoundDevice(AHost, AMac, ADescr);
end;

end.

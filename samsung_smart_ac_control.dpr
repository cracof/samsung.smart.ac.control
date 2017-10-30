program samsung_smart_ac_control;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {frmMain},
  uACClient in 'uACClient.pas',
  uSSDPClient in 'uSSDPClient.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Samsung Smart AC Control';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

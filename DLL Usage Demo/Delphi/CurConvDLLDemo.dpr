program CurConvDLLDemo;

uses
  Forms,
  Demo in 'Demo.pas' {Form1},
  VtsCurConvDLLHeader in 'VtsCurConvDLLHeader.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := true;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

program templateprosample;

uses
  Vcl.Forms,
  MainFormU in 'MainFormU.pas' {MainForm},
  RandomTextUtilsU in 'RandomTextUtilsU.pas',
  Vcl.Themes,
  Vcl.Styles,
  TemplatePro.Types in '..\..\TemplatePro.Types.pas',
  TemplatePro in '..\..\TemplatePro.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Glow');
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

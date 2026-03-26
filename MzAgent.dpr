program MzAgent;

uses
  Vcl.Forms,
  MainFrm in 'MainFrm.pas' {MainForm},
  PromptTemplate in 'PromptTemplate.pas',
  Tools in 'Tools.pas',
  ReActAgent in 'ReActAgent.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

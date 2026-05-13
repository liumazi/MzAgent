program MzAgent;

uses
  Vcl.Forms,
  MainFrm in 'MainFrm.pas' {MainForm},
  PromptTemplate in 'PromptTemplate.pas',
  InternalTools in 'InternalTools.pas',
  ReActAgent in 'ReActAgent.pas',
  Configuration in 'Configuration.pas',
  McpStdioClient in 'McpStdioClient.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

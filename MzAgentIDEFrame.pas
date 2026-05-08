unit MzAgentIDEFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Tools, ReActAgent, System.Threading, ToolsAPI;

type
  TMzAgentIDEFrame = class(TFrame)
    TopPanel: TPanel;
    lblProjectDir: TLabel;
    edtProjectDir: TEdit;
    btnRefresh: TButton;
    ChatPanel: TPanel;
    ChatMemo: TRichEdit;
    BottomPanel: TPanel;
    InputPanel: TPanel;
    InputMemo: TMemo;
    SendPanel: TPanel;
    btnSend: TButton;
    StatusBar: TStatusBar;
    procedure btnSendClick(Sender: TObject);
    procedure InputMemoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnRefreshClick(Sender: TObject);
  private
    FAgent: TReActAgent;
    FToolList: TToolList;
    FIsRunning: Boolean;
    procedure AddChatMessage(const Role, Content: string; Color: TColor = clBlack);
    procedure EnableControls(Enabled: Boolean);
    procedure DoAgentRun(const UserInput: string);
    procedure OnAgentLog(const LogType, Message: string);
    procedure OnAgentFinalAnswer(const Answer: string);
    procedure RefreshProjectDir;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

uses
  IOUtils;

{$R *.dfm}

constructor TMzAgentIDEFrame.Create(AOwner: TComponent);
begin
  inherited;

  lblProjectDir.Caption := 'Project Dir';
  btnRefresh.Caption := 'Refresh';
  btnSend.Caption := 'Send';
  StatusBar.SimpleText := 'Ready';

  ChatMemo.Font.Name := 'Microsoft YaHei UI';
  ChatMemo.Font.Charset := GB2312_CHARSET;
  InputMemo.Font.Name := 'Microsoft YaHei UI';
  InputMemo.Font.Charset := GB2312_CHARSET;

  FToolList := TToolList.Create;
  FToolList.Add(TReadFileTool.Create);
  FToolList.Add(TWriteToFileTool.Create);
  FToolList.Add(TRunTerminalCommandTool.Create);

  FIsRunning := False;

  RefreshProjectDir;

  ChatMemo.Clear;
  AddChatMessage('system',
    'Welcome to MzAgent IDE Assistant!' + sLineBreak +
    'Configure API_KEY in ' + TPath.Combine(TPath.GetHomePath, 'MzAgent.ini') +
    ' to get started.', clGray);
end;

destructor TMzAgentIDEFrame.Destroy;
begin
  if Assigned(FAgent) then
    FAgent.Free;
  FToolList.Free;
  inherited;
end;

procedure TMzAgentIDEFrame.RefreshProjectDir;
var
  ModuleServices: IOTAModuleServices;
  Project: IOTAProject;
  I: Integer;
begin
  edtProjectDir.Text := '';
  if Supports(BorlandIDEServices, IOTAModuleServices, ModuleServices) then
  begin
    for I := 0 to ModuleServices.ModuleCount - 1 do
    begin
      if Supports(ModuleServices.Modules[I], IOTAProject, Project) and
         (Project.FileName <> '') then
      begin
        edtProjectDir.Text := ExtractFilePath(Project.FileName);
        Exit;
      end;
    end;
  end;
end;

procedure TMzAgentIDEFrame.btnRefreshClick(Sender: TObject);
begin
  RefreshProjectDir;
  if edtProjectDir.Text <> '' then
    StatusBar.SimpleText := 'Project: ' + edtProjectDir.Text
  else
    StatusBar.SimpleText := 'No project opened';
end;

procedure TMzAgentIDEFrame.AddChatMessage(const Role, Content: string; Color: TColor);
var
  Prefix: string;
begin
  ChatMemo.Lines.BeginUpdate;
  try
    ChatMemo.SelStart := ChatMemo.GetTextLen;
    ChatMemo.SelLength := 0;
    ChatMemo.SelAttributes.Color := Color;

    if Role = 'user' then Prefix := 'You: '
    else if Role = 'assistant' then Prefix := 'Agent: '
    else if Role = 'thought' then Prefix := 'Think: '
    else if Role = 'action' then Prefix := 'Action: '
    else if Role = 'observation' then Prefix := 'Observe: '
    else if Role = 'system' then Prefix := 'System: '
    else if Role = 'error' then Prefix := 'Error: '
    else if Role = 'status' then Prefix := 'Status: '
    else Prefix := Role + ': ';

    ChatMemo.Lines.Add('');
    ChatMemo.Lines.Add(Prefix + Content);
    ChatMemo.Lines.Add('--------------------------------------------------');
  finally
    ChatMemo.Lines.EndUpdate;
    ChatMemo.SelStart := ChatMemo.GetTextLen;
    ChatMemo.Perform(EM_SCROLLCARET, 0, 0);
  end;
end;

procedure TMzAgentIDEFrame.EnableControls(Enabled: Boolean);
begin
  FIsRunning := not Enabled;
  btnSend.Enabled := Enabled;
  btnRefresh.Enabled := Enabled;
  InputMemo.Enabled := Enabled;

  if Enabled then
    StatusBar.SimpleText := 'Ready'
  else
    StatusBar.SimpleText := 'Processing...';
end;

procedure TMzAgentIDEFrame.btnSendClick(Sender: TObject);
var
  UserInput: string;
begin
  if FIsRunning then
    Exit;

  if edtProjectDir.Text = '' then
  begin
    AddChatMessage('system',
      'Please open a project in the IDE first, or click Refresh to detect it.', clRed);
    Exit;
  end;

  UserInput := Trim(InputMemo.Text);
  if UserInput = '' then
    Exit;

  AddChatMessage('user', UserInput, clNavy);
  InputMemo.Clear;

  EnableControls(False);

  TTask.Run(
    procedure
    begin
      try
        DoAgentRun(UserInput);
      except
        on E: Exception do
        begin
          TThread.Synchronize(nil,
            procedure
            begin
              AddChatMessage('error', E.Message, clRed);
              EnableControls(True);
            end);
        end;
      end;
    end);
end;

procedure TMzAgentIDEFrame.DoAgentRun(const UserInput: string);
var
  FinalAnswer: string;
begin
  if Assigned(FAgent) then
    FAgent.Free;

  FAgent := TReActAgent.Create(FToolList, 'deepseek-coder', edtProjectDir.Text);
  try
    FAgent.OnLog := OnAgentLog;
    FAgent.OnFinalAnswer := OnAgentFinalAnswer;

    FinalAnswer := FAgent.Run(UserInput);

    TThread.Synchronize(nil,
      procedure
      begin
        AddChatMessage('assistant', FinalAnswer, clGreen);
        EnableControls(True);
      end);
  except
    on E: Exception do
    begin
      TThread.Synchronize(nil,
        procedure
        begin
          AddChatMessage('error', E.Message, clRed);
          EnableControls(True);
        end);
    end;
  end;
end;

procedure TMzAgentIDEFrame.OnAgentLog(const LogType, Message: string);
var
  Color: TColor;
begin
  TThread.Synchronize(nil,
    procedure
    begin
      if LogType = 'thought' then Color := clPurple
      else if LogType = 'action' then Color := clTeal
      else if LogType = 'observation' then Color := clOlive
      else Color := clBlack;
      AddChatMessage(LogType, Message, Color);
    end);
end;

procedure TMzAgentIDEFrame.OnAgentFinalAnswer(const Answer: string);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      AddChatMessage('assistant', Answer, clGreen);
    end);
end;

procedure TMzAgentIDEFrame.InputMemoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnSendClick(nil);
  end;
end;

end.

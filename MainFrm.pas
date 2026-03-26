unit MainFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Tools, ReActAgent, System.Threading, Vcl.FileCtrl;

type
  TMainForm = class(TForm)
    TopPanel: TPanel;
    lblProjectDir: TLabel;
    edtProjectDir: TEdit;
    btnBrowse: TButton;
    ChatPanel: TPanel;
    ChatMemo: TRichEdit;
    BottomPanel: TPanel;
    InputPanel: TPanel;
    InputMemo: TMemo;
    SendPanel: TPanel;
    btnSend: TButton;
    StatusBar: TStatusBar;
    procedure btnBrowseClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure InputMemoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FAgent: TReActAgent;
    FToolList: TToolList;
    FIsRunning: Boolean;
    procedure AddChatMessage(const Role, Content: string; Color: TColor = clBlack);
    procedure EnableControls(Enabled: Boolean);
    procedure DoAgentRun(const UserInput: string);
    procedure OnAgentLog(const LogType, Message: string);
    procedure OnAgentFinalAnswer(const Answer: string);
    function CheckProjectDir: Boolean;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  lblProjectDir.Caption := '项目目录';
  btnBrowse.Caption := '浏览...';
  btnSend.Caption := '发送';
  StatusBar.SimpleText := '就绪';

  ChatMemo.Font.Name := 'Microsoft YaHei UI';
  ChatMemo.Font.Charset := GB2312_CHARSET;
  InputMemo.Font.Name := 'Microsoft YaHei UI';
  InputMemo.Font.Charset := GB2312_CHARSET;

  FToolList := TToolList.Create;
  FToolList.Add(TReadFileTool.Create);
  FToolList.Add(TWriteToFileTool.Create);
  FToolList.Add(TRunTerminalCommandTool.Create);

  FIsRunning := False;

  ChatMemo.Clear;
  AddChatMessage('system', '欢迎使用 MzAgent！请先选择项目目录，然后输入您的需求。', clGray);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if Assigned(FAgent) then
    FAgent.Free;
  FToolList.Free;
end;

procedure TMainForm.btnBrowseClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtProjectDir.Text;
  if SelectDirectory('选择项目目录', '', Dir) then
  begin
    Dir := Dir + '\';
    edtProjectDir.Text := Dir;
  end;
end;

function TMainForm.CheckProjectDir: Boolean;
begin
  Result := False;
  if edtProjectDir.Text = '' then
  begin
    ShowMessage('请先选择项目目录');
    Exit;
  end;
  if not System.SysUtils.DirectoryExists(edtProjectDir.Text) then
  begin
    ShowMessage('项目目录不存在');
    Exit;
  end;
  Result := True;
end;

procedure TMainForm.AddChatMessage(const Role, Content: string; Color: TColor);
var
  Prefix: string;
begin
  ChatMemo.Lines.BeginUpdate;
  try
    ChatMemo.SelStart := ChatMemo.GetTextLen;
    ChatMemo.SelLength := 0;
    ChatMemo.SelAttributes.Color := Color;

    if Role = 'user' then Prefix := '您: '
    else if Role = 'assistant' then Prefix := 'Agent: '
    else if Role = 'thought' then Prefix := '思考: '
    else if Role = 'action' then Prefix := '动作: '
    else if Role = 'observation' then Prefix := '观察: '
    else if Role = 'system' then Prefix := '系统: '
    else if Role = 'error' then Prefix := '错误: '
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

procedure TMainForm.EnableControls(Enabled: Boolean);
begin
  FIsRunning := not Enabled;
  btnSend.Enabled := Enabled;
  edtProjectDir.Enabled := Enabled;
  btnBrowse.Enabled := Enabled;
  InputMemo.Enabled := Enabled;

  if Enabled then
    StatusBar.SimpleText := '就绪'
  else
    StatusBar.SimpleText := '正在处理...';
end;

procedure TMainForm.btnSendClick(Sender: TObject);
var
  UserInput: string;
begin
  if FIsRunning then
    Exit;

  if not CheckProjectDir then
    Exit;

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

procedure TMainForm.DoAgentRun(const UserInput: string);
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

procedure TMainForm.OnAgentLog(const LogType, Message: string);
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

procedure TMainForm.OnAgentFinalAnswer(const Answer: string);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      AddChatMessage('assistant', Answer, clGreen);
    end);
end;

procedure TMainForm.InputMemoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnSendClick(nil);
  end;
end;

end.

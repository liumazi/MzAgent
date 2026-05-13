unit InternalTools;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  TBaseTool = class abstract
  private
    function GetAbsolutePath(SubPath: string): string;
  protected
    FProjectDirectory: string;
  public
    function GetName: string; virtual; abstract;
    function GetSignature: string; virtual; abstract;
    function GetDescription: string; virtual; abstract;
    function Execute(const Args: TArray<string>): string; virtual; abstract;
    procedure SetProjectDirectory(const Dir: string); virtual;
  end;

  TReadFileTool = class(TBaseTool)
  public
    function GetName: string; override;
    function GetSignature: string; override;
    function GetDescription: string; override;
    function Execute(const Args: TArray<string>): string; override;
  end;

  TWriteToFileTool = class(TBaseTool)
  public
    function GetName: string; override;
    function GetSignature: string; override;
    function GetDescription: string; override;
    function Execute(const Args: TArray<string>): string; override;
  end;

  TRunTerminalCommandTool = class(TBaseTool)
  public
    function GetName: string; override;
    function GetSignature: string; override;
    function GetDescription: string; override;
    function Execute(const Args: TArray<string>): string; override;
  end;

  TToolList = class(TObjectList<TBaseTool>)
  public
    function GetToolByName(const Name: string): TBaseTool;
    function GetToolDescriptions: string;
    procedure SetProjectDirectory(const Dir: string);
  end;

implementation

uses
  Winapi.Windows, Winapi.ShellAPI, IOUtils;

{ TBaseTool }

function TBaseTool.GetAbsolutePath(SubPath: string): string;
begin
  // TODO: 不同模型传回的文件名规则不同
  (*
  if (Length(SubPath) > 2) then
    if (SubPath[1] = '/') then
      Delete(SubPath, 1, 1)
    else
      if SubPath[2] = ':' then
        Delete(SubPath, 1, 3);
  *)
  if SubPath[2] = ':' then
    Result := SubPath
  else
    Result := FProjectDirectory + SubPath;
end;

procedure TBaseTool.SetProjectDirectory(const Dir: string);
begin
  FProjectDirectory := Dir;
end;

{ TReadFileTool }

function TReadFileTool.GetName: string;
begin
  Result := 'read_file';
end;

function TReadFileTool.GetSignature: string;
begin
  Result := '(file_path: str)';
end;

function TReadFileTool.GetDescription: string;
begin
  Result := '用于读取文件内容';
end;

function TReadFileTool.Execute(const Args: TArray<string>): string;
var
  FilePath: string;
  Content: TStringList;
begin
  if Length(Args) < 1 then
  begin
    Result := '错误: read_file 需要一个参数 (file_path)';
    Exit;
  end;

  FilePath := GetAbsolutePath(Args[0]);
  if not FileExists(FilePath) then
  begin
    Result := '错误: 文件不存在 - ' + FilePath;
    Exit;
  end;

  try
    Content := TStringList.Create;
    try
      Content.LoadFromFile(FilePath, TEncoding.UTF8);
      Result := Content.Text;
    finally
      Content.Free;
    end;
  except
    on E: Exception do
      Result := '读取文件错误: ' + E.Message;
  end;
end;

{ TWriteToFileTool }

function TWriteToFileTool.GetName: string;
begin
  Result := 'write_to_file';
end;

function TWriteToFileTool.GetSignature: string;
begin
  Result := '(file_path: str, content: str)';
end;

function TWriteToFileTool.GetDescription: string;
begin
  Result := '将指定内容写入指定文件';
end;

function TWriteToFileTool.Execute(const Args: TArray<string>): string;
var
  FilePath, Content: string;
  ContentList: TStringList;
begin
  if Length(Args) < 2 then
  begin
    Result := '错误: write_to_file 需要两个参数 (file_path, content)';
    Exit;
  end;

  FilePath := GetAbsolutePath(Args[0]);
  Content := Args[1];
  Content := StringReplace(Content, '\n', sLineBreak, [rfReplaceAll]);

  try
    ContentList := TStringList.Create;
    try
      ContentList.Text := Content;
      ContentList.SaveToFile(FilePath, TEncoding.UTF8);
      Result := '写入成功: ' + FilePath;
    finally
      ContentList.Free;
    end;
  except
    on E: Exception do
      Result := '写入文件错误: ' + E.Message;
  end;
end;

{ TRunTerminalCommandTool }

function TRunTerminalCommandTool.GetName: string;
begin
  Result := 'run_terminal_command';
end;

function TRunTerminalCommandTool.GetSignature: string;
begin
  Result := '(command: str)';
end;

function TRunTerminalCommandTool.GetDescription: string;
begin
  Result := '用于执行终端命令';
end;

function TRunTerminalCommandTool.Execute(const Args: TArray<string>): string;
var
  Command: string;
  SEI: TShellExecuteInfo;
  ExitCode: DWORD;
  OutputFile: string;
  OutputContent: TStringList;
begin
  if Length(Args) < 1 then
  begin
    Result := '错误: run_terminal_command 需要一个参数 (command)';
    Exit;
  end;

  Command := Args[0];

  if FProjectDirectory <> '' then
    Command := 'cd /d "' + FProjectDirectory + '" && ' + Command;

  OutputFile := TPath.GetTempFileName;

  try
    FillChar(SEI, SizeOf(SEI), 0);
    SEI.cbSize := SizeOf(SEI);
    SEI.fMask := SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_NO_UI;
    SEI.Wnd := 0;
    SEI.lpVerb := 'open';
    SEI.lpFile := PChar('cmd.exe');
    SEI.lpParameters := PChar('/c ' + Command + ' > "' + OutputFile + '" 2>&1');
    SEI.nShow := SW_HIDE;

    if ShellExecuteEx(@SEI) then
    begin
      WaitForSingleObject(SEI.hProcess, INFINITE);
      GetExitCodeProcess(SEI.hProcess, ExitCode);
      CloseHandle(SEI.hProcess);

      OutputContent := TStringList.Create;
      try
        OutputContent.LoadFromFile(OutputFile); // , TEncoding.UTF8
        if ExitCode = 0 then
          Result := '执行成功' + sLineBreak + OutputContent.Text
        else
          Result := '执行失败 (退出码: ' + IntToStr(ExitCode) + ')' + sLineBreak + OutputContent.Text;
      finally
        OutputContent.Free;
      end;
    end
    else
      Result := '无法执行命令: ' + SysErrorMessage(GetLastError);
  finally
    if FileExists(OutputFile) then
      DeleteFile(PChar(OutputFile));
  end;
end;

{ TToolList }

function TToolList.GetToolByName(const Name: string): TBaseTool;
var
  Tool: TBaseTool;
begin
  Result := nil;
  for Tool in Self do
  begin
    if Tool.GetName = Name then
    begin
      Result := Tool;
      Break;
    end;
  end;
end;

function TToolList.GetToolDescriptions: string;
var
  Tool: TBaseTool;
  Builder: TStringBuilder;
begin
  Builder := TStringBuilder.Create;
  try
    for Tool in Self do
    begin
      Builder.Append('- ');
      Builder.Append(Tool.GetName);
      Builder.Append(Tool.GetSignature);
      Builder.Append(': ');
      Builder.Append(Tool.GetDescription);
      Builder.AppendLine;
    end;
    Result := Builder.ToString.TrimRight([#13, #10]);
  finally
    Builder.Free;
  end;
end;

procedure TToolList.SetProjectDirectory(const Dir: string);
var
  Tool: TBaseTool;
begin
  for Tool in Self do
  begin
    Tool.SetProjectDirectory(Dir);
  end;
end;

end.

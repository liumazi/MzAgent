unit McpStdioClient;

interface

uses
  System.SysUtils, System.JSON, Winapi.Windows;

type
  TMcpToolInfo = record
    Name: string;
    Description: string;
  end;

  TMcpToolInfoArray = TArray<TMcpToolInfo>;

  TMcpStdioClient = class
  private
    FExecutablePath: string;
    FStdInWrite: THandle;
    FStdOutRead: THandle;
    FStdErrWrite: THandle;
    FProcessInfo: TProcessInformation;
    FNextId: Integer;
    FTimeoutMS: Cardinal;
    function NextId: Integer;
    function BuildRequest(const Method: string; Params: TJSONObject; Id: Integer): TJSONObject;
    function WaitForOutput(Deadline: UInt64): Boolean;
    function ReadByte(Deadline: UInt64; out B: Byte): Boolean;
    function ReadPayload(Length: Integer; Deadline: UInt64): string;
    function ReadMessage: TJSONObject;
    function SendRequest(const Method: string; Params: TJSONObject): TJSONObject;
    procedure SendJSON(JSON: TJSONObject);
    procedure SendNotification(const Method: string);
    procedure CloseHandleIfOpen(var Handle: THandle);
    function GetJSONText(JSON: TJSONObject; const Name: string): string;
  public
    constructor Create(const ExecutablePath: string; TimeoutMS: Cardinal = 10000);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    procedure Initialize;
    procedure NotifyInitialized;
    function ListTools: TMcpToolInfoArray;
    function DiscoverTools: TMcpToolInfoArray;
  end;

implementation

uses
  System.Classes, System.Generics.Collections, System.StrUtils;

{ TMcpStdioClient }

constructor TMcpStdioClient.Create(const ExecutablePath: string; TimeoutMS: Cardinal);
begin
  inherited Create;
  FExecutablePath := ExecutablePath;
  FStdInWrite := 0;
  FStdOutRead := 0;
  FStdErrWrite := 0;
  FillChar(FProcessInfo, SizeOf(FProcessInfo), 0);
  FNextId := 1;
  FTimeoutMS := TimeoutMS;
end;

destructor TMcpStdioClient.Destroy;
begin
  Stop;
  inherited;
end;

function TMcpStdioClient.NextId: Integer;
begin
  Result := FNextId;
  Inc(FNextId);
end;

procedure TMcpStdioClient.CloseHandleIfOpen(var Handle: THandle);
begin
  if Handle <> 0 then
  begin
    CloseHandle(Handle);
    Handle := 0;
  end;
end;

procedure TMcpStdioClient.Start;
var
  SecurityAttributes: TSecurityAttributes;
  StdInRead, StdOutWrite: THandle;
  StartupInfo: TStartupInfo;
  CommandLine: string;
begin
  if not FileExists(FExecutablePath) then
    raise Exception.Create('MCP 服务器不存在: ' + FExecutablePath);

  Stop;

  StdInRead := 0;
  StdOutWrite := 0;
  FillChar(SecurityAttributes, SizeOf(SecurityAttributes), 0);
  SecurityAttributes.nLength := SizeOf(SecurityAttributes);
  SecurityAttributes.bInheritHandle := True;

  if not CreatePipe(StdInRead, FStdInWrite, @SecurityAttributes, 0) then
    raise Exception.Create('创建 MCP stdin pipe 失败: ' + SysErrorMessage(GetLastError));
  try
    if not SetHandleInformation(FStdInWrite, HANDLE_FLAG_INHERIT, 0) then
      raise Exception.Create('配置 MCP stdin pipe 失败: ' + SysErrorMessage(GetLastError));

    if not CreatePipe(FStdOutRead, StdOutWrite, @SecurityAttributes, 0) then
      raise Exception.Create('创建 MCP stdout pipe 失败: ' + SysErrorMessage(GetLastError));
    try
      if not SetHandleInformation(FStdOutRead, HANDLE_FLAG_INHERIT, 0) then
        raise Exception.Create('配置 MCP stdout pipe 失败: ' + SysErrorMessage(GetLastError));

      FStdErrWrite := CreateFile('NUL', GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE,
        @SecurityAttributes, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
      if FStdErrWrite = INVALID_HANDLE_VALUE then
        FStdErrWrite := 0;

      FillChar(StartupInfo, SizeOf(StartupInfo), 0);
      StartupInfo.cb := SizeOf(StartupInfo);
      StartupInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
      StartupInfo.wShowWindow := SW_HIDE;
      StartupInfo.hStdInput := StdInRead;
      StartupInfo.hStdOutput := StdOutWrite;
      StartupInfo.hStdError := FStdErrWrite;

      CommandLine := '"' + FExecutablePath + '"';
      if not CreateProcess(PChar(FExecutablePath), PChar(CommandLine), nil, nil, True,
        CREATE_NO_WINDOW, nil, nil, StartupInfo, FProcessInfo) then
        raise Exception.Create('启动 MCP 服务器失败: ' + SysErrorMessage(GetLastError));
    finally
      CloseHandleIfOpen(StdOutWrite);
    end;
  finally
    CloseHandleIfOpen(StdInRead);
  end;
end;

procedure TMcpStdioClient.Stop;
begin
  CloseHandleIfOpen(FStdInWrite);
  CloseHandleIfOpen(FStdOutRead);
  CloseHandleIfOpen(FStdErrWrite);

  if FProcessInfo.hProcess <> 0 then
  begin
    if WaitForSingleObject(FProcessInfo.hProcess, 100) = WAIT_TIMEOUT then
      TerminateProcess(FProcessInfo.hProcess, 0);
    CloseHandle(FProcessInfo.hProcess);
    FProcessInfo.hProcess := 0;
  end;

  if FProcessInfo.hThread <> 0 then
  begin
    CloseHandle(FProcessInfo.hThread);
    FProcessInfo.hThread := 0;
  end;
end;

function TMcpStdioClient.BuildRequest(const Method: string; Params: TJSONObject;
  Id: Integer): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('jsonrpc', '2.0');
  Result.AddPair('id', TJSONNumber.Create(Id));
  Result.AddPair('method', Method);
  if Assigned(Params) then
    Result.AddPair('params', Params);
end;

procedure TMcpStdioClient.SendJSON(JSON: TJSONObject);
var
  Payload, Header: string;
  Bytes: TBytes;
  Written: DWORD;
begin
  Payload := JSON.ToJSON;
  Header := 'Content-Length: ' + IntToStr(Length(TEncoding.UTF8.GetBytes(Payload))) +
    #13#10#13#10;
  Bytes := TEncoding.UTF8.GetBytes(Header + Payload);

  if (Length(Bytes) = 0) or not WriteFile(FStdInWrite, Bytes[0], Length(Bytes), Written, nil) or
    (Written <> DWORD(Length(Bytes))) then
    raise Exception.Create('写入 MCP 请求失败: ' + SysErrorMessage(GetLastError));
end;

procedure TMcpStdioClient.SendNotification(const Method: string);
var
  Notification: TJSONObject;
begin
  Notification := TJSONObject.Create;
  try
    Notification.AddPair('jsonrpc', '2.0');
    Notification.AddPair('method', Method);
    SendJSON(Notification);
  finally
    Notification.Free;
  end;
end;

function TMcpStdioClient.WaitForOutput(Deadline: UInt64): Boolean;
var
  BytesAvailable: DWORD;
begin
  repeat
    BytesAvailable := 0;
    if not PeekNamedPipe(FStdOutRead, nil, 0, nil, @BytesAvailable, nil) then
      raise Exception.Create('读取 MCP 输出失败: ' + SysErrorMessage(GetLastError));

    if BytesAvailable > 0 then
      Exit(True);

    if (FProcessInfo.hProcess <> 0) and (WaitForSingleObject(FProcessInfo.hProcess, 0) <> WAIT_TIMEOUT) then
      raise Exception.Create('MCP 服务器已退出');

    Sleep(10);
  until GetTickCount64 >= Deadline;

  Result := False;
end;

function TMcpStdioClient.ReadByte(Deadline: UInt64; out B: Byte): Boolean;
var
  ReadCount: DWORD;
begin
  Result := False;
  if not WaitForOutput(Deadline) then
    Exit;

  if not ReadFile(FStdOutRead, B, 1, ReadCount, nil) then
    raise Exception.Create('读取 MCP 字节失败: ' + SysErrorMessage(GetLastError));

  Result := ReadCount = 1;
end;

function TMcpStdioClient.ReadPayload(Length: Integer; Deadline: UInt64): string;
var
  Bytes: TBytes;
  Offset: Integer;
  ReadCount: DWORD;
begin
  SetLength(Bytes, Length);
  Offset := 0;
  while Offset < Length do
  begin
    if not WaitForOutput(Deadline) then
      raise Exception.Create('等待 MCP 响应超时');

    ReadCount := 0;
    if not ReadFile(FStdOutRead, Bytes[Offset], Length - Offset, ReadCount, nil) then
      raise Exception.Create('读取 MCP 响应失败: ' + SysErrorMessage(GetLastError));

    if ReadCount = 0 then
      raise Exception.Create('MCP 响应提前结束');

    Inc(Offset, ReadCount);
  end;

  Result := TEncoding.UTF8.GetString(Bytes);
end;

function TMcpStdioClient.ReadMessage: TJSONObject;
var
  Deadline: UInt64;
  HeaderBytes: TBytes;
  B: Byte;
  Header, Line, Payload: string;
  HeaderLines: TArray<string>;
  ContentLength, ColonPos: Integer;
  JSONValue: TJSONValue;
begin
  Deadline := GetTickCount64 + FTimeoutMS;
  SetLength(HeaderBytes, 0);

  repeat
    if not ReadByte(Deadline, B) then
      raise Exception.Create('等待 MCP 响应超时');
    SetLength(HeaderBytes, Length(HeaderBytes) + 1);
    HeaderBytes[High(HeaderBytes)] := B;
    Header := TEncoding.ASCII.GetString(HeaderBytes);
  until EndsText(#13#10#13#10, Header);

  ContentLength := 0;
  HeaderLines := Header.Split([#13#10], TStringSplitOptions.ExcludeEmpty);
  for Line in HeaderLines do
  begin
    ColonPos := Pos(':', Line);
    if ColonPos <= 0 then
      Continue;

    if SameText(Copy(Line, 1, ColonPos - 1).Trim, 'Content-Length') then
      ContentLength := StrToIntDef(Copy(Line, ColonPos + 1, MaxInt).Trim, 0);
  end;

  if ContentLength <= 0 then
    raise Exception.Create('MCP 响应缺少 Content-Length');

  Payload := ReadPayload(ContentLength, Deadline);
  JSONValue := TJSONObject.ParseJSONValue(Payload);
  if not (JSONValue is TJSONObject) then
  begin
    JSONValue.Free;
    raise Exception.Create('MCP 响应不是 JSON 对象');
  end;

  Result := TJSONObject(JSONValue);
end;

function TMcpStdioClient.SendRequest(const Method: string; Params: TJSONObject): TJSONObject;
var
  Id: Integer;
  Request, Response: TJSONObject;
  IdValue, ErrorValue: TJSONValue;
begin
  Id := NextId;
  Request := BuildRequest(Method, Params, Id);
  try
    SendJSON(Request);
  finally
    Request.Free;
  end;

  while True do
  begin
    Response := ReadMessage;
    IdValue := Response.GetValue('id');
    if not Assigned(IdValue) or (IdValue.Value <> IntToStr(Id)) then
    begin
      Response.Free;
      Continue;
    end;

    ErrorValue := Response.GetValue('error');
    if Assigned(ErrorValue) then
    begin
      try
        raise Exception.Create('MCP 请求失败: ' + ErrorValue.ToJSON);
      finally
        Response.Free;
      end;
    end;

    Exit(Response);
  end;
end;

procedure TMcpStdioClient.Initialize;
var
  Params, Capabilities, ClientInfo, Response: TJSONObject;
begin
  Params := TJSONObject.Create;
  Capabilities := TJSONObject.Create;
  ClientInfo := TJSONObject.Create;
  try
    ClientInfo.AddPair('name', 'MzAgent');
    ClientInfo.AddPair('version', '1.0');
    Params.AddPair('protocolVersion', '2024-11-05');
    Params.AddPair('capabilities', Capabilities);
    Params.AddPair('clientInfo', ClientInfo);
    Capabilities := nil;
    ClientInfo := nil;

    Response := SendRequest('initialize', Params);
    try
      // The first phase only needs to prove the server accepted initialize.
    finally
      Response.Free;
    end;
  finally
    Params.Free;
    Capabilities.Free;
    ClientInfo.Free;
  end;
end;

procedure TMcpStdioClient.NotifyInitialized;
begin
  SendNotification('notifications/initialized');
end;

function TMcpStdioClient.GetJSONText(JSON: TJSONObject; const Name: string): string;
var
  Value: TJSONValue;
begin
  Result := '';
  Value := JSON.GetValue(Name);
  if Assigned(Value) then
    Result := Value.Value;
end;

function TMcpStdioClient.ListTools: TMcpToolInfoArray;
var
  Response, ResultObject, ToolObject: TJSONObject;
  ResultValue, ToolsValue: TJSONValue;
  ToolsArray: TJSONArray;
  I: Integer;
begin
  SetLength(Result, 0);
  Response := SendRequest('tools/list', TJSONObject.Create);
  try
    ResultValue := Response.GetValue('result');
    if not (ResultValue is TJSONObject) then
      Exit;

    ResultObject := TJSONObject(ResultValue);
    ToolsValue := ResultObject.GetValue('tools');
    if not (ToolsValue is TJSONArray) then
      Exit;

    ToolsArray := TJSONArray(ToolsValue);
    SetLength(Result, ToolsArray.Count);
    for I := 0 to ToolsArray.Count - 1 do
    begin
      if ToolsArray.Items[I] is TJSONObject then
      begin
        ToolObject := TJSONObject(ToolsArray.Items[I]);
        Result[I].Name := GetJSONText(ToolObject, 'name');
        Result[I].Description := GetJSONText(ToolObject, 'description');
      end;
    end;
  finally
    Response.Free;
  end;
end;

function TMcpStdioClient.DiscoverTools: TMcpToolInfoArray;
begin
  Start;
  try
    Initialize;
    NotifyInitialized;
    Result := ListTools;
  finally
    Stop;
  end;
end;

end.

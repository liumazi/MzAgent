unit ReActAgent;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.RegularExpressions,
  System.Net.HttpClient, System.Net.URLClient, System.JSON, Tools, PromptTemplate;

type
  TChatMessage = record
    Role: string;
    Content: string;
  end;

  TLogEvent = procedure(const LogType, Message: string) of object;
  TFinalAnswerEvent = procedure(const Answer: string) of object;

  TReActAgent = class
  private
    FTools: TToolList;
    FModel: string;
    FProjectDirectory: string;
    FHttpClient: THTTPClient;
    FApiKey: string;
    FMessages: TList<TChatMessage>;
    FOnLog: TLogEvent;
    FOnFinalAnswer: TFinalAnswerEvent;

    function GetApiKey: string;
    function CallModel: string;
    function RenderSystemPrompt: string;
    function GetToolList: string;
    function GetFileList: string;
    function GetOperatingSystemName: string;
    function ParseAction(const ActionStr: string): TPair<string, TArray<string>>;
    function ExtractTagContent(const Content, TagName: string): string;
    procedure AddMessage(const Role, Content: string);
    procedure DoLog(const LogType, Message: string);
  public
    constructor Create(ATools: TToolList; const AModel, AProjectDirectory: string);
    destructor Destroy; override;
    function Run(const UserInput: string): string;

    property OnLog: TLogEvent read FOnLog write FOnLog;
    property OnFinalAnswer: TFinalAnswerEvent read FOnFinalAnswer write FOnFinalAnswer;
  end;

implementation

uses
  IOUtils, Winapi.Windows, System.Types;

{ TReActAgent }

constructor TReActAgent.Create(ATools: TToolList; const AModel, AProjectDirectory: string);
begin
  inherited Create;
  FTools := ATools;
  FModel := AModel;
  FProjectDirectory := AProjectDirectory;
  FHttpClient := THTTPClient.Create;
  FMessages := TList<TChatMessage>.Create;
  FApiKey := GetApiKey;

  FHttpClient.CustomHeaders['Authorization'] := 'Bearer ' + FApiKey;
  FHttpClient.CustomHeaders['Content-Type'] := 'application/json';
end;

destructor TReActAgent.Destroy;
begin
  FMessages.Free;
  FHttpClient.Free;
  inherited;
end;

function TReActAgent.GetApiKey: string;
var
  EnvValue: string;
  DotEnvPath: string;
  Lines: TStringList;
  Line, L: string;
  Parts: TArray<string>;
begin
  Result := '';

  DotEnvPath := TPath.Combine(GetCurrentDir, '.env');
  if FileExists(DotEnvPath) then
  begin
    Lines := TStringList.Create;
    try
      Lines.LoadFromFile(DotEnvPath, TEncoding.UTF8);
      for L in Lines do
      begin
        Line := Trim(L);
        if Line.StartsWith('OPENROUTER_API_KEY') then
        begin
          Parts := Line.Split(['='], 2);
          if Length(Parts) = 2 then
          begin
            Result := Parts[1].Trim;
            if (Result.StartsWith('"') and Result.EndsWith('"')) or
               (Result.StartsWith('''') and Result.EndsWith('''')) then
              Result := Result.Substring(1, Result.Length - 2);
            Break;
          end;
        end;
      end;
    finally
      Lines.Free;
    end;
  end;

  if Result = '' then
  begin
    //if not GetEnvironmentVariable('OPENROUTER_API_KEY', EnvValue) then
    raise Exception.Create('未找到 OPENROUTER_API_KEY 环境变量，请在 .env 文件中设置。');
    //Result := EnvValue;
  end;
end;

procedure TReActAgent.AddMessage(const Role, Content: string);
var
  Msg: TChatMessage;
begin
  Msg.Role := Role;
  Msg.Content := Content;
  FMessages.Add(Msg);
end;

procedure TReActAgent.DoLog(const LogType, Message: string);
begin
  if Assigned(FOnLog) then
    FOnLog(LogType, Message);
end;

function TReActAgent.CallModel: string;
var
  RequestBody: TJSONObject;
  MessagesArray: TJSONArray;
  Msg: TChatMessage;
  MsgObj: TJSONObject;
  Response: IHTTPResponse;
  ResponseJSON: TJSONObject;
  ChoicesArray: TJSONArray;
begin
  DoLog('status', '正在请求模型，请稍等...');

  RequestBody := TJSONObject.Create;
  try
    RequestBody.AddPair('model', FModel);

    MessagesArray := TJSONArray.Create;
    for Msg in FMessages do
    begin
      MsgObj := TJSONObject.Create;
      MsgObj.AddPair('role', Msg.Role);
      MsgObj.AddPair('content', Msg.Content);
      MessagesArray.AddElement(MsgObj);
    end;
    RequestBody.AddPair('messages', MessagesArray);

    Response := FHttpClient.Post('https://openrouter.ai/api/v1/chat/completions',
      TStringStream.Create(RequestBody.ToJSON, TEncoding.UTF8));

    if Response.StatusCode <> 200 then
      raise Exception.Create('API 请求失败: ' + IntToStr(Response.StatusCode) + ' - ' + Response.ContentAsString);

    ResponseJSON := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
    try
      ChoicesArray := ResponseJSON.GetValue('choices') as TJSONArray;
      Result := (ChoicesArray.Items[0] as TJSONObject).GetValue('message').GetValue<string>('content');

      AddMessage('assistant', Result);
    finally
      ResponseJSON.Free;
    end;
  finally
    RequestBody.Free;
  end;
end;

function TReActAgent.GetToolList: string;
begin
  Result := FTools.GetToolDescriptions;
end;

function TReActAgent.GetFileList: string;
var
  Files: TStringDynArray;
  FileName: string;
  Builder: TStringBuilder;
begin
  Builder := TStringBuilder.Create;
  try
    Files := TDirectory.GetFiles(FProjectDirectory);
    for FileName in Files do
    begin
      if Builder.Length > 0 then
        Builder.Append(', ');
      Builder.Append(TPath.Combine(FProjectDirectory, ExtractFileName(FileName)));
    end;
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

function TReActAgent.GetOperatingSystemName: string;
begin
  Result := 'Windows';
end;

function TReActAgent.RenderSystemPrompt: string;
begin
  Result := StringReplace(ReactSystemPromptTemplate, '${tool_list}', GetToolList, [rfReplaceAll]);
  Result := StringReplace(Result, '${operating_system}', GetOperatingSystemName, [rfReplaceAll]);
  Result := StringReplace(Result, '${file_list}', GetFileList, [rfReplaceAll]);
end;

function TReActAgent.ExtractTagContent(const Content, TagName: string): string;
var
  Regex: TRegEx;
  Match: TMatch;
begin
  Result := '';
  Regex := TRegEx.Create('<' + TagName + '>(.*?)</' + TagName + '>', [roSingleLine, roIgnoreCase]);
  Match := Regex.Match(Content);
  if Match.Success then
    Result := Match.Groups[1].Value.Trim;
end;

function TReActAgent.ParseAction(const ActionStr: string): TPair<string, TArray<string>>;
var
  Regex: TRegEx;
  Match: TMatch;
  FuncName, ArgsStr: string;
  Args: TArray<string>;
  CurrentArg: string;
  InString: Boolean;
  StringChar: Char;
  I: Integer;
  ParenDepth: Integer;
  Ch: Char;
begin
  Regex := TRegEx.Create('(\w+)\((.*)\)', [roSingleLine]);
  Match := Regex.Match(ActionStr);

  if not Match.Success then
    raise Exception.Create('Invalid function call syntax: ' + ActionStr);

  FuncName := Match.Groups[1].Value;
  ArgsStr := Match.Groups[2].Value.Trim;

  Args := nil;
  CurrentArg := '';
  InString := False;
  StringChar := #0;
  ParenDepth := 0;
  I := 1;

  while I <= Length(ArgsStr) do
  begin
    Ch := ArgsStr[I];

    if not InString then
    begin
      if (Ch = '"') or (Ch = '''') then
      begin
        InString := True;
        StringChar := Ch;
        CurrentArg := CurrentArg + Ch;
      end
      else if Ch = '(' then
      begin
        Inc(ParenDepth);
        CurrentArg := CurrentArg + Ch;
      end
      else if Ch = ')' then
      begin
        Dec(ParenDepth);
        CurrentArg := CurrentArg + Ch;
      end
      else if (Ch = ',') and (ParenDepth = 0) then
      begin
        SetLength(Args, Length(Args) + 1);
        Args[High(Args)] := CurrentArg.Trim;
        CurrentArg := '';
      end
      else
        CurrentArg := CurrentArg + Ch;
    end
    else
    begin
      CurrentArg := CurrentArg + Ch;
      if (Ch = StringChar) and ((I = 1) or (ArgsStr[I - 1] <> '\')) then
      begin
        InString := False;
        StringChar := #0;
      end;
    end;

    Inc(I);
  end;

  if CurrentArg.Trim <> '' then
  begin
    SetLength(Args, Length(Args) + 1);
    Args[High(Args)] := CurrentArg.Trim;
  end;

  for I := 0 to High(Args) do
  begin
    if (Args[I].StartsWith('"') and Args[I].EndsWith('"')) or
       (Args[I].StartsWith('''') and Args[I].EndsWith('''')) then
    begin
      Args[I] := Args[I].Substring(1, Args[I].Length - 2);
      Args[I] := StringReplace(Args[I], '\"', '"', [rfReplaceAll]);
      Args[I] := StringReplace(Args[I], '\''', '''', [rfReplaceAll]);
      Args[I] := StringReplace(Args[I], '\n', sLineBreak, [rfReplaceAll]);
      Args[I] := StringReplace(Args[I], '\t', #9, [rfReplaceAll]);
      Args[I] := StringReplace(Args[I], '\r', #13, [rfReplaceAll]);
      Args[I] := StringReplace(Args[I], '\\', '\', [rfReplaceAll]);
    end;
  end;

  Result := TPair<string, TArray<string>>.Create(FuncName, Args);
end;

function TReActAgent.Run(const UserInput: string): string;
var
  Content, Thought, Action, ToolName, Observation: string;
  ParsedAction: TPair<string, TArray<string>>;
  Tool: TBaseTool;
  ActionDisplay: string;
  I: Integer;
begin
  AddMessage('system', RenderSystemPrompt);
  AddMessage('user', '<question>' + UserInput + '</question>');

  while True do
  begin
    Content := CallModel;

    Thought := ExtractTagContent(Content, 'thought');
    if Thought <> '' then
      DoLog('thought', Thought);

    if Pos('<final_answer>', Content) > 0 then
    begin
      Result := ExtractTagContent(Content, 'final_answer');
      if Assigned(FOnFinalAnswer) then
        FOnFinalAnswer(Result);
      Exit;
    end;

    Action := ExtractTagContent(Content, 'action');
    if Action = '' then
      raise Exception.Create('模型未输出 <action>');

    ParsedAction := ParseAction(Action);
    ToolName := ParsedAction.Key;

    ActionDisplay := ToolName + '(';
    for I := 0 to High(ParsedAction.Value) do
    begin
      if I > 0 then
        ActionDisplay := ActionDisplay + ', ';
      ActionDisplay := ActionDisplay + ParsedAction.Value[I];
    end;
    ActionDisplay := ActionDisplay + ')';
    DoLog('action', ActionDisplay);

    Tool := FTools.GetToolByName(ToolName);
    if Tool = nil then
      Observation := '错误: 未找到工具 - ' + ToolName
    else
    begin
      try
        Observation := Tool.Execute(ParsedAction.Value);
      except
        on E: Exception do
          Observation := '工具执行错误：' + E.Message;
      end;
    end;

    DoLog('observation', Observation);

    AddMessage('user', '<observation>' + Observation + '</observation>');
  end;
end;

end.

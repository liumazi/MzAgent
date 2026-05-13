unit Configuration;

interface

uses
  System.SysUtils;

type
  TConfiguration = class
  public
    class function FindConfigFile(const ProjectDirectory: string; out ConfigPath, AttemptedPaths: string): Boolean; static;
    class function TryReadValue(const ProjectDirectory, Key: string; out Value, ConfigPath, AttemptedPaths: string): Boolean; static;
  end;

implementation

uses
  System.Classes, System.IOUtils;

{ TConfiguration }

class function TConfiguration.FindConfigFile(const ProjectDirectory: string; out ConfigPath, AttemptedPaths: string): Boolean;
var
  SearchPaths: TArray<string>;
  P: string;
begin
  ConfigPath := '';
  AttemptedPaths := '';

  SearchPaths := TArray<string>.Create(
    TPath.Combine(ProjectDirectory, 'MzAgent.ini'),
    TPath.Combine(GetCurrentDir, 'MzAgent.ini'),
    TPath.Combine(TPath.GetHomePath, 'MzAgent.ini')
  );

  for P in SearchPaths do
  begin
    AttemptedPaths := AttemptedPaths + sLineBreak + '  ' + P;
    if FileExists(P) then
    begin
      ConfigPath := P;
      Exit(True);
    end;
  end;

  Result := False;
end;

class function TConfiguration.TryReadValue(const ProjectDirectory, Key: string; out Value, ConfigPath, AttemptedPaths: string): Boolean;
var
  Lines: TStringList;
  L, Line, ConfigKey, ConfigValue: string;
  EqPos: Integer;
begin
  Value := '';
  Result := False;

  if not FindConfigFile(ProjectDirectory, ConfigPath, AttemptedPaths) then
    Exit;

  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(ConfigPath, TEncoding.UTF8);
    for L in Lines do
    begin
      Line := L.Trim;
      if (Line = '') or Line.StartsWith('#') or Line.StartsWith(';') then
        Continue;

      EqPos := Pos('=', Line);
      if EqPos <= 0 then
        Continue;

      ConfigKey := Copy(Line, 1, EqPos - 1).Trim;
      ConfigValue := Copy(Line, EqPos + 1, MaxInt).Trim;
      if SameText(ConfigKey, Key) then
      begin
        Value := ConfigValue;
        Exit(True);
      end;
    end;
  finally
    Lines.Free;
  end;
end;

end.

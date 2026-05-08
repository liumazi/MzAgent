unit MzAgentIDEDockForm;

interface

uses
  ToolsAPI, Classes, Vcl.Forms, Vcl.ActnList, Vcl.ImgList, System.IniFiles,
  MzAgentIDEFrame;

type
  TMzAgentIDEDockForm = class(TInterfacedObject, INTACustomDockableForm)
  private
    FFrame: TMzAgentIDEFrame;
  public
    function GetCaption: string;
    function GetIdentifier: string;
    function GetFrameClass: TCustomFrameClass;
    procedure FrameCreated(AFrame: TCustomFrame);
    function GetMenuActionList: TCustomActionList;
    function GetMenuImageList: TCustomImageList;
    function GetToolbarActionList: TCustomActionList;
    function GetToolbarImageList: TCustomImageList;
    procedure SaveWindowState(Desktop: TCustomIniFile; const Section: string;
      IsProject: Boolean);
    procedure LoadWindowState(Desktop: TCustomIniFile; const Section: string);
    function GetEditState: TEditState;
    function EditAction(Action: TEditAction): Boolean;
  end;

implementation

function TMzAgentIDEDockForm.GetCaption: string;
begin
  Result := 'MzAgent';
end;

function TMzAgentIDEDockForm.GetIdentifier: string;
begin
  Result := 'MzAgent.DockableForm';
end;

function TMzAgentIDEDockForm.GetFrameClass: TCustomFrameClass;
begin
  Result := TMzAgentIDEFrame;
end;

procedure TMzAgentIDEDockForm.FrameCreated(AFrame: TCustomFrame);
begin
  FFrame := AFrame as TMzAgentIDEFrame;
end;

function TMzAgentIDEDockForm.GetMenuActionList: TCustomActionList;
begin
  Result := nil;
end;

function TMzAgentIDEDockForm.GetMenuImageList: TCustomImageList;
begin
  Result := nil;
end;

function TMzAgentIDEDockForm.GetToolbarActionList: TCustomActionList;
begin
  Result := nil;
end;

function TMzAgentIDEDockForm.GetToolbarImageList: TCustomImageList;
begin
  Result := nil;
end;

procedure TMzAgentIDEDockForm.SaveWindowState(Desktop: TCustomIniFile;
  const Section: string; IsProject: Boolean);
begin
end;

procedure TMzAgentIDEDockForm.LoadWindowState(Desktop: TCustomIniFile;
  const Section: string);
begin
end;

function TMzAgentIDEDockForm.GetEditState: TEditState;
begin
  Result := [];
end;

function TMzAgentIDEDockForm.EditAction(Action: TEditAction): Boolean;
begin
  Result := False;
end;

end.

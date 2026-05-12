unit MzAgentIDEForm;

interface

uses
  ToolsAPI, Classes, DesignIntf, Vcl.Forms, Vcl.ActnList, Vcl.ImgList,
  Vcl.Menus, Vcl.ComCtrls, System.IniFiles, MzAgentIDEFrame;

type
  TMzAgentIDEForm = class(TInterfacedObject, INTACustomDockableForm)
  private
    FFrame: TMzAgentIDEFrame;
  public
    function GetCaption: string;
    function GetIdentifier: string;
    function GetFrameClass: TCustomFrameClass;
    procedure FrameCreated(AFrame: TCustomFrame);
    function GetMenuActionList: TCustomActionList;
    function GetMenuImageList: TCustomImageList;
    procedure CustomizePopupMenu(PopupMenu: TPopupMenu);
    function GetToolBarActionList: TCustomActionList;
    function GetToolBarImageList: TCustomImageList;
    procedure CustomizeToolBar(ToolBar: TToolBar);
    procedure SaveWindowState(Desktop: TCustomIniFile; const Section: string;
      IsProject: Boolean);
    procedure LoadWindowState(Desktop: TCustomIniFile; const Section: string);
    function GetEditState: TEditState;
    function EditAction(Action: TEditAction): Boolean;
  end;

implementation

function TMzAgentIDEForm.GetCaption: string;
begin
  Result := 'MzAgent';
end;

function TMzAgentIDEForm.GetIdentifier: string;
begin
  Result := 'MzAgent.DockableForm';
end;

function TMzAgentIDEForm.GetFrameClass: TCustomFrameClass;
begin
  Result := TMzAgentIDEFrame;
end;

procedure TMzAgentIDEForm.FrameCreated(AFrame: TCustomFrame);
begin
  FFrame := AFrame as TMzAgentIDEFrame;
end;

function TMzAgentIDEForm.GetMenuActionList: TCustomActionList;
begin
  Result := nil;
end;

function TMzAgentIDEForm.GetMenuImageList: TCustomImageList;
begin
  Result := nil;
end;

procedure TMzAgentIDEForm.CustomizePopupMenu(PopupMenu: TPopupMenu);
begin
end;

function TMzAgentIDEForm.GetToolBarActionList: TCustomActionList;
begin
  Result := nil;
end;

function TMzAgentIDEForm.GetToolBarImageList: TCustomImageList;
begin
  Result := nil;
end;

procedure TMzAgentIDEForm.CustomizeToolBar(ToolBar: TToolBar);
begin
end;

procedure TMzAgentIDEForm.SaveWindowState(Desktop: TCustomIniFile;
  const Section: string; IsProject: Boolean);
begin
end;

procedure TMzAgentIDEForm.LoadWindowState(Desktop: TCustomIniFile;
  const Section: string);
begin
end;

function TMzAgentIDEForm.GetEditState: TEditState;
begin
  Result := [];
end;

function TMzAgentIDEForm.EditAction(Action: TEditAction): Boolean;
begin
  Result := False;
end;

end.

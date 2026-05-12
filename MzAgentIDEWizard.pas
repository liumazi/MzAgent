unit MzAgentIDEWizard;

interface

uses
  ToolsAPI, Classes;

type
  TMzAgentIDEWizard = class(TNotifierObject, IOTAWizard, IOTAMenuWizard)
  public
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;
    function GetMenuText: string;
  end;

implementation

uses
  MzAgentIDEDockForm;

function TMzAgentIDEWizard.GetIDString: string;
begin
  Result := 'MzAgent.IDEWizard';
end;

function TMzAgentIDEWizard.GetName: string;
begin
  Result := 'MzAgent AI Assistant';
end;

function TMzAgentIDEWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

function TMzAgentIDEWizard.GetMenuText: string;
begin
  Result := 'MzAgent';
end;

procedure TMzAgentIDEWizard.Execute;
begin
  (BorlandIDEServices as INTAServices).CreateDockableForm(TMzAgentIDEDockForm.Create);
end;

end.

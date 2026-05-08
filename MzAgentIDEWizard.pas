unit MzAgentIDEWizard;

interface

uses
  ToolsAPI, Classes;

type
  TMzAgentIDEWizard = class(TNotifierObject, IOTAWizard, IOTAMenuWizard)
  private
    class var FWizardIndex: Integer;
    class constructor Create;
  public
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;
    function GetMenuText: string;
    class procedure RegisterWizard;
    class procedure UnregisterWizard;
  end;

implementation

uses
  MzAgentIDEDockForm;

class constructor TMzAgentIDEWizard.Create;
begin
  FWizardIndex := -1;
end;

class procedure TMzAgentIDEWizard.RegisterWizard;
var
  WizardServices: IOTAWizardServices;
begin
  if Supports(BorlandIDEServices, IOTAWizardServices, WizardServices) then
    FWizardIndex := WizardServices.AddWizard(TMzAgentIDEWizard.Create);
end;

class procedure TMzAgentIDEWizard.UnregisterWizard;
var
  WizardServices: IOTAWizardServices;
begin
  if (FWizardIndex >= 0) and
     Supports(BorlandIDEServices, IOTAWizardServices, WizardServices) then
  begin
    WizardServices.RemoveWizard(FWizardIndex);
    FWizardIndex := -1;
  end;
end;

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
var
  Services: INTAServices;
begin
  if Supports(BorlandIDEServices, INTAServices, Services) then
    Services.CreateDockableForm(TMzAgentIDEDockForm.Create);
end;

end.

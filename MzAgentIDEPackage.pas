unit MzAgentIDEPackage;

interface

uses
  Winapi.Windows, System.SysUtils, ToolsAPI, MzAgentIDEWizard, MzAgentIDEForm,
  MzAgentIDESplash;

function INITWIZARD0001(const BorlandIDEServices: IBorlandIDEServices;
  RegisterProc: TWizardRegisterProc;
  var Terminate: TWizardTerminateProc): Boolean; stdcall;

implementation

var
  FDockableForm: TMzAgentIDEForm;
  FWizardIndex: Integer = -1;

procedure FinalizeWizard;
var
  Services: INTAServices;
  WizardServices: IOTAWizardServices;
begin
  if Assigned(BorlandIDEServices) then
  begin
    if Assigned(FDockableForm) then
    begin
      Services := BorlandIDEServices as INTAServices;
      Services.UnregisterDockableForm(FDockableForm);
      FDockableForm := nil;
    end;

    if FWizardIndex >= 0 then
    begin
      WizardServices := BorlandIDEServices as IOTAWizardServices;
      WizardServices.RemoveWizard(FWizardIndex);
      FWizardIndex := -1;
    end;
  end;
end;

function INITWIZARD0001(const BorlandIDEServices: IBorlandIDEServices;
  RegisterProc: TWizardRegisterProc;
  var Terminate: TWizardTerminateProc): Boolean;
var
  Services: INTAServices;
  WizardServices: IOTAWizardServices;
  Wizard: IOTAWizard;
begin
  Result := False;
  Terminate := nil;

  if not Assigned(BorlandIDEServices) then
    Exit;

  Services := BorlandIDEServices as INTAServices;
  WizardServices := BorlandIDEServices as IOTAWizardServices;

  FDockableForm := TMzAgentIDEForm.Create;
  Services.RegisterDockableForm(FDockableForm);

  Wizard := TMzAgentIDEWizard.Create;
  FWizardIndex := WizardServices.AddWizard(Wizard);

  RegisterSplashScreen;

  Terminate := FinalizeWizard;
  Result := True;
end;

end.

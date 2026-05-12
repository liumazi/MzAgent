library MzAgentWizard;

{$R *.res}

uses
  ToolsAPI, MzAgentIDEWizard, MzAgentIDEForm;

var
  DockableForm: TMzAgentIDEForm = nil;
  WizardIndex: Integer = -1;

procedure FinalizeWizard;
var
  Services: INTAServices;
  WizardServices: IOTAWizardServices;
begin
  if Assigned(BorlandIDEServices) then
  begin
    if Assigned(DockableForm) then
    begin
      Services := BorlandIDEServices as INTAServices;
      Services.UnregisterDockableForm(DockableForm);
      DockableForm := nil;
    end;

    if WizardIndex >= 0 then
    begin
      WizardServices := BorlandIDEServices as IOTAWizardServices;
      WizardServices.RemoveWizard(WizardIndex);
      WizardIndex := -1;
    end;
  end;
end;

function InitWizard(const BorlandIDEServices: IBorlandIDEServices;
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

  DockableForm := TMzAgentIDEForm.Create;
  Services.RegisterDockableForm(DockableForm);

  Wizard := TMzAgentIDEWizard.Create;
  WizardIndex := WizardServices.AddWizard(Wizard);

  if Assigned(SplashScreenServices) then
    SplashScreenServices.AddPluginBitmap('MzAgent Wizard 0.1', 0);

  Terminate := FinalizeWizard;
  Result := True;
end;

exports
  InitWizard name 'INITWIZARD0001';

begin
end.

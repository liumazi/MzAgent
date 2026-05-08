unit MzAgentIDEPackage;

interface

procedure Register;

implementation

uses
  Winapi.Windows, System.SysUtils, ToolsAPI, MzAgentIDEWizard, MzAgentIDEDockForm;

var
  FDockableForm: TMzAgentIDEDockForm;
  FWizardIndex: Integer = -1;

procedure Register;
var
  Services: INTAServices;
  WizardServices: IOTAWizardServices;
begin
  OutputDebugString('Register: enter');

  if not Assigned(BorlandIDEServices) then
  begin
    OutputDebugString('Register: BorlandIDEServices nil, exit');
    Exit;
  end;
  OutputDebugString('Register: BorlandIDEServices OK');

  Services := BorlandIDEServices as INTAServices;
  WizardServices := BorlandIDEServices as IOTAWizardServices;
  OutputDebugString('Register: Services obtained');

  if Assigned(FDockableForm) then
  begin
    OutputDebugString('Register: UnregisterDockableForm...');
    Services.UnregisterDockableForm(FDockableForm);
    OutputDebugString('Register: UnregisterDockableForm OK');
    FDockableForm := nil;
  end;

  FDockableForm := TMzAgentIDEDockForm.Create;
  OutputDebugString('Register: RegisterDockableForm...');
  Services.RegisterDockableForm(FDockableForm);
  OutputDebugString('Register: RegisterDockableForm OK');

  if FWizardIndex >= 0 then
  begin
    OutputDebugString('Register: RemoveWizard...');
    WizardServices.RemoveWizard(FWizardIndex);
    OutputDebugString('Register: RemoveWizard OK');
    FWizardIndex := -1;
  end;

  OutputDebugString('Register: AddWizard...');
  FWizardIndex := WizardServices.AddWizard(TMzAgentIDEWizard.Create);
  OutputDebugString(PChar('Register: AddWizard OK, index=' + IntToStr(FWizardIndex)));

  OutputDebugString('Register: exit');
end;

end.

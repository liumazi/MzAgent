unit MzAgentIDEPackage;

interface

procedure Register;

implementation

uses
  ToolsAPI, MzAgentIDEWizard, MzAgentIDEDockForm;

procedure Register;
begin
  (BorlandIDEServices as INTAServices).RegisterDockableForm(
    TMzAgentIDEDockForm.Create);
  RegisterPackageWizard(TMzAgentIDEWizard.Create);
end;

end.

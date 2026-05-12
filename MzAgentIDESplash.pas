unit MzAgentIDESplash;

interface

uses
  ToolsAPI;

procedure RegisterSplashScreen;

implementation

procedure RegisterSplashScreen;
var
  SplashServices: IOTASplashScreenServices;
begin
  //if Assigned(BorlandIDEServices) and Supports(BorlandIDEServices, IOTASplashScreenServices, SplashServices) then
  //  SplashServices.AddPluginBitmap('MzAgent v0.1', 0, False, 'Open Source', '');
  if Assigned(SplashScreenServices) then
  begin
    SplashScreenServices.AddPluginBitmap('MzAgent 0.1', 0);
  end;
end;

end.

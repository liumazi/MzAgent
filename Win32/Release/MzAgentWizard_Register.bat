@echo off
reg add "HKCU\Software\Embarcadero\BDS\23.0\Experts" /v MzAgent /t REG_SZ /d "%~dp0MzAgentWizard.dll" /f
pause

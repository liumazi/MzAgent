@echo off
reg delete "HKCU\Software\Embarcadero\BDS\23.0\Experts" /v MzAgent /f
pause

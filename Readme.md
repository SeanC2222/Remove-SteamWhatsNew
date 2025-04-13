To use whats new:

Pre-Requirements)
1) Close Steam entirely

Steps)
1) Open PowerShell
2) Run `Import-Module .\RemoveWhatsNew.ps1`
3) Run `Remove-SteamWhatsNew` Optional Parameters: `-SetNoVerifyInStartup $false`, `-SteamLocation {Path to Steam directory}`, `-TargetClass {Steam CSS class to target}`, `-TargetFile {Path to Steam css file to backup and modify}`

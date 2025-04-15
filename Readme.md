To use whats new:

Pre-Requirements)
1) Close Steam entirely

Steps)
1) Open PowerShell
2) Run `Import-Module .\RemoveWhatsNew.ps1`
3) Run `Remove-SteamWhatsNew`<br>
Optional Parameters:<br>
    `-SetNoVerifyInStartup $false`,<br> 
    `-SteamLocation {Path to Steam directory}`,<br>
    `-TargetClass {Steam CSS class to target}`,<br>
    `-TargetFile {Path to Steam css file to backup and modify}`

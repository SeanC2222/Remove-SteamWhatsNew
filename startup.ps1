[CmdletBinding()]
param(
    [Parameter()]
    [bool] $SetNoVerifyInStartup = $true,


    [Parameter()]
    [string] $ModuleLocation = "$($env:USERPROFILE)\source\repos\Remove-SteamWhatsNew",

    [Parameter()]
    [string] $ModuleName = "RemoveSteamWhatsNew",

    [Parameter()]
    [string] $SteamLocation = "C:\Program Files (x86)\Steam"
)
try
{
    Write-Host "Checking if Steam is running..."
    $process = Get-Process "steam" 2> $null
    
    if ($null -ne $process)
    {
        Write-Host "Steam is running. Shutting down Steam."
        $process = Start-Process "$SteamLocation\steam.exe" -ArgumentList "-shutdown" -WorkingDirectory $SteamLocation -PassThru
        Wait-Process -Id $process.Id

        $process = Get-Process "steam" 2> $null
        if ($null -ne $process)
        {
            Wait-Process -Id $process.Id
        }
    }
    Write-Host "Steam is shutdown."

    if ($null -eq (Get-Module "$ModuleName"))
    {
        Import-Module "$ModuleLocation\$ModuleName.ps1"
    }

    if (Get-Module $ModuleName)
    {
        Remove-SteamWhatsNew -SetNoVerifyInStartup $true -SteamLocation "$SteamLocation"
    }
    else 
    {
        throw [System.Exception]::new("Remove-SteamWhatsNew can't be found.")
    }
    
    Write-Host "What's new successfully removed."
}
finally 
{
    Write-Host "Starting Steam..."
    Start-Process "$SteamLocation\steam.exe" -ArgumentList "-dev", "-noverifyfiles" -WorkingDirectory $SteamLocation
}




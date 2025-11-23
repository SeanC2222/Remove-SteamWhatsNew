[CmdletBinding()]
param(
    [Parameter()]
    [string] $target = "$($pwd.Path)\startup.ps1",

    [Parameter()]
    [string] $shortcutName = "Steam.lnk",

    [Parameter()]
    [string] $iconPath = "Cornmanthe3rd-Metronome-Other-steam-red.512.ico"
)


if ($null -ne (Get-ChildItem $shortcutName -ErrorAction SilentlyContinue))
{
    $in = Read-Host -Prompt "Replace existing shortcut? (y/n)"

    $replace = $in.ToLower() -match '^y(es)?$'

    if (!$replace)
    {
        exit 0;
    }

    Write-Host "Replacing shortcut."
    Remove-Item $shortcutName
}

$workingDirectory = $pwd.Path
$comObj = New-Object -ComObject WScript.Shell

$path = "$($workingDirectory)\$shortcutName"
$shortcut = $comObj.CreateShortCut($path)

$paths = $env:Path.Split(";")
$pwshPath = $paths | where {$_.Contains("PowerShell")} | select -First 1

$powershell = Get-Item "$pwshPath\powershell.exe" -ErrorAction SilentlyContinue
$pwsh = Get-Item "$pwshPath\pwsh.exe" -ErrorAction SilentlyContinue

$shellPath = if ($null -ne $powershell) { $powershell.FullName } elseif ($null -ne $pwsh) { $pwsh.FullName } else { throw "Couldn't detect PowerShell" }

$shortcut.TargetPath = $shellPath
$shortcut.Arguments = "-File `"$target`""
$shortcut.WorkingDirectory = $workingDirectory

$iconPath = Convert-Path $iconPath
$shortcut.IconLocation = $iconPath

$shortcut.Description = "Shortcut for pinning startup.ps1."

$shortcut.Save()
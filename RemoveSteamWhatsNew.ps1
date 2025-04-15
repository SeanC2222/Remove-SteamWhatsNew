function Remove-SteamWhatsNew
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool] $SetNoVerifyInStartup = $true,

        [Parameter()]
        [string] $SteamLocation = "C:\Program Files (x86)\Steam",

        [Parameter()]
        [string] $TargetClass = "_17uEBe5Ri8TMsnfELvs8-N",

        [Parameter()]
        [string] $TargetFile = "chunk~2dcc5aaf7.css"
    )

    process {

        function SetNoVerifyInStartupShortcut
        {
            $steamStartup = Get-CimInstance Win32_StartupCommand | `
                Select-Object Name, command, Location, User | `
                Where-Object { $_.Name -eq "Steam" }

            if ($steamStartup -eq $null) {
                return;
            }

            if ($steamStartup.Location.StartsWith("H")) # Assume registry defined startup location
            {
                throw "Unknown handling of registry defined Steam startup. Find the location from the registry key by running the following: ``Get-ItemProperty -Path `"Registry::$($steamStartup.Location)`"`` Look for a Steam related path and update the shortcut to have `"-dev -noverifyfiles`" in the TargetPath property."
            }
            else 
            {
                if ($steamStartup.Location -eq "Startup")
                {
                    $fileLocation = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\$($steamStartup.command)"
                }

                if ($steamStartup.Location -eq "Common Startup")
                {
                    $fileLocation = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\$($steamStartup.command)"
                }

                $shell = New-Object -COM WScript.Shell

                $noverifyShortcut = $shell.CreateShortCut($fileLocation)

                $steam = Get-ChildItem "$($noverifyShortcut.WorkingDirectory)\steam.exe" 2> $null

                if ($null -eq $steam)
                {
                    Write-Host "Didn't find steam at shortcut location. Updating shortcut to point at $SteamLocation. If this isn't correct. Re-run with input argument ``-SteamLocation {Steam's Directory path}``"
                    $noverifyShortcut.WorkingDirectory = $SteamLocation
                    $noverifyShortcut.TargetPath = "$SteamLocation\steam.exe"
                }

                $noverifyShortcut.Arguments = "-dev -noverifyfiles" # Ensure arguments are on the startup shortcut

                $descriptionModifier = "- Modified to not verify files on every Steam boot."
                $noverifyShortcut.Description = if ($noverifyShortcut.Description.EndsWith($descriptionModifier)) { $noverifyShortcut.Description } else { "$($noverifyShortcut.Description) $descriptionModifier"}

                $noverifyShortcut.Save()
            }
        }

        $workingDirectory = Get-Location

        try
        {
            # Get target CSS for update
            cd "$SteamLocation\steamui\css"
            $css = Get-Content ".\$TargetFile"
            $allCss = $css -join ''

            # Write joined, unmodified content to a backup file; Can recover by deletingt the target file and renaming this backup without the "~backup"
            Set-Content ".\$TargetFile~backup" $allCss

            Write-Host "Completed backup write."

            # Split on the target, and insert the modified CSS
            $target = "$TargetClass{"
            $splitCss = $allCss -split $target
            $modified_css = "display:none;"
            for($i = 1; $i -lt $splitCss.Length; $i++)
            {
                $splitCss[$i] = if ($splitCss[$i].StartsWith($modified_css)) { $splitCss[$i] } else { $splitCss[$i].Insert(0, $modified_css) }
            }

            # Rebuild all CSS with modified CSS content, then set to original file target
            $allCss = $splitCss -join $target
            Set-Content ".\$TargetFile" $allCss

            Write-Host "Completed modified CSS file write."

            if($SetNoVerifyInStartup)
            {
                SetNoVerifyInStartupShortcut
                Write-Host "Completed Startup modification with noverifyfiles."
            }

            Write-Host "Completed."
        }
        finally
        {
            cd $workingDirectory
        }
    }
}
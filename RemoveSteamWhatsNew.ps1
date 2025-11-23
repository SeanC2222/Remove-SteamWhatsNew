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
# SIG # Begin signature block
# MIIb5AYJKoZIhvcNAQcCoIIb1TCCG9ECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCHlItxs/GxF/aB
# pD17YrzPdM9yR3CXf9F8tVs4bER4mKCCFjYwggL4MIIB4KADAgECAhBw/Gtc8SzY
# g0R+JT16LzepMA0GCSqGSIb3DQEBCwUAMBQxEjAQBgNVBAMMCVNlYW5DMjIyMjAe
# Fw0yNTExMjMwNDM4MjVaFw0yNjExMjMwNDU4MjVaMBQxEjAQBgNVBAMMCVNlYW5D
# MjIyMjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANbZ6k5nKYmKA53f
# q9qZKxZxU79jjzesa9zWpHmyLuTvsBspYSyB+peFKmTF34jnc6GTLStKC6b1x50C
# olHdAr4+hd/N30qMOFsr9ZbzV8LNBAEt5M6elMIosbiYaG+HlWHU8r9QcxM/OaNW
# NFtcxswM15rdhg04YxeoYcQVoWzL800dMKjbvkzSXuUbgsSrlkUshXgQoGUfHTkE
# wS/IwIO5KN1p6opCWtQp+uXowj6KICO4EwLwlAiSjZKcCQ6DKo6Lp1pA8ZT5NcF9
# 1uBJ7g6CH+6Zl1+tIvm5XPFXrdUeQOZgdnIz2dhZQwibEDllXzNfk/zxCgutGFEP
# kxA/L9kCAwEAAaNGMEQwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUF
# BwMDMB0GA1UdDgQWBBTMSTQbnCeOz2ajurXSmmE/Z60L9TANBgkqhkiG9w0BAQsF
# AAOCAQEAGoxXn4B/SrVoLxsxPVx4bo5Axz+phHfCFkV0TN3HihimUobBZqyPTHDZ
# LdzdRPBKL3h7/yJ6NnaoNBaO3VGq4S1aU9JkGlICK727IFkRKpOvsOcBhr2pwBlt
# JDau3pTygMb6JawfbluuRs332rNFUOszl1dHHzsT19URnCHuBXGPvfowcQtwUjmo
# 0tZc9ly3rQpyXScXaFns2Pkhl8NkuJx4NIFzzw8M+5c7l2ep8W/cy2Opz1eIy13L
# /J1knXaDV8jrLvw83aADKx/SGaSKBLcuGuQv8YFSHd0qlGJvJ47IiHx1ayf6YW7u
# 4VA1hBmtCCxdlqCz89tgbcJDpfHKCzCCBY0wggR1oAMCAQICEA6bGI750C3n79tQ
# 4ghAGFowDQYJKoZIhvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERp
# Z2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMb
# RGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTIyMDgwMTAwMDAwMFoXDTMx
# MTEwOTIzNTk1OVowYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IElu
# YzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQg
# VHJ1c3RlZCBSb290IEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# v+aQc2jeu+RdSjwwIjBpM+zCpyUuySE98orYWcLhKac9WKt2ms2uexuEDcQwH/Mb
# pDgW61bGl20dq7J58soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNwwrK6dZlq
# czKU0RBEEC7fgvMHhOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs06wXGXuxb
# Grzryc/NrDRAX7F6Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e5TXnMcva
# k17cjo+A2raRmECQecN4x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtVgkEy19sE
# cypukQF8IUzUvK4bA3VdeGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85tRFYF/ck
# XEaPZPfBaYh2mHY9WV1CdoeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+SkjqePdwA
# 5EUlibaaRBkrfsCUtNJhbesz2cXfSwQAzH0clcOP9yGyshG3u3/y1YxwLEFgqrFj
# GESVGnZifvaAsPvoZKYz0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzlDlJRR3S+
# Jqy2QXXeeqxfjT/JvNNBERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFrb7GrhotP
# wtZFX50g/KEexcCPorF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCATowggE2MA8G
# A1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiuHA9PMB8G
# A1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQEAwIBhjB5
# BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0
# LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDBFBgNVHR8EPjA8MDqgOKA2hjRodHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3Js
# MBEGA1UdIAQKMAgwBgYEVR0gADANBgkqhkiG9w0BAQwFAAOCAQEAcKC/Q1xV5zhf
# oKN0Gz22Ftf3v1cHvZqsoYcs7IVeqRq7IviHGmlUIu2kiHdtvRoU9BNKei8ttzjv
# 9P+Aufih9/Jy3iS8UgPITtAq3votVs/59PesMHqai7Je1M/RQ0SbQyHrlnKhSLSZ
# y51PpwYDE3cnRNTnf+hZqPC/Lwum6fI0POz3A8eHqNJMQBk1RmppVLC4oVaO7KTV
# Peix3P0c2PR3WlxUjG/voVA9/HYJaISfb8rbII01YBwCA8sgsKxYoA5AY8WYIsGy
# WfVVa88nq2x2zm8jLfR+cWojayL/ErhULSd+2DrZ8LaHlv1b0VysGMNNn3O3Aamf
# V6peKOK5lDCCBrQwggScoAMCAQICEA3HrFcF/yGZLkBDIgw6SYYwDQYJKoZIhvcN
# AQELBQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcG
# A1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3Rl
# ZCBSb290IEc0MB4XDTI1MDUwNzAwMDAwMFoXDTM4MDExNDIzNTk1OVowaTELMAkG
# A1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdp
# Q2VydCBUcnVzdGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNIQTI1NiAyMDI1
# IENBMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALR4MdMKmEFyvjxG
# wBysddujRmh0tFEXnU2tjQ2UtZmWgyxU7UNqEY81FzJsQqr5G7A6c+Gh/qm8Xi4a
# PCOo2N8S9SLrC6Kbltqn7SWCWgzbNfiR+2fkHUiljNOqnIVD/gG3SYDEAd4dg2dD
# GpeZGKe+42DFUF0mR/vtLa4+gKPsYfwEu7EEbkC9+0F2w4QJLVSTEG8yAR2CQWIM
# 1iI5PHg62IVwxKSpO0XaF9DPfNBKS7Zazch8NF5vp7eaZ2CVNxpqumzTCNSOxm+S
# AWSuIr21Qomb+zzQWKhxKTVVgtmUPAW35xUUFREmDrMxSNlr/NsJyUXzdtFUUt4a
# S4CEeIY8y9IaaGBpPNXKFifinT7zL2gdFpBP9qh8SdLnEut/GcalNeJQ55IuwnKC
# gs+nrpuQNfVmUB5KlCX3ZA4x5HHKS+rqBvKWxdCyQEEGcbLe1b8Aw4wJkhU1JrPs
# FfxW1gaou30yZ46t4Y9F20HHfIY4/6vHespYMQmUiote8ladjS/nJ0+k6Mvqzfpz
# PDOy5y6gqztiT96Fv/9bH7mQyogxG9QEPHrPV6/7umw052AkyiLA6tQbZl1KhBtT
# asySkuJDpsZGKdlsjg4u70EwgWbVRSX1Wd4+zoFpp4Ra+MlKM2baoD6x0VR4RjSp
# WM8o5a6D8bpfm4CLKczsG7ZrIGNTAgMBAAGjggFdMIIBWTASBgNVHRMBAf8ECDAG
# AQH/AgEAMB0GA1UdDgQWBBTvb1NK6eQGfHrK4pBW9i/USezLTjAfBgNVHSMEGDAW
# gBTs1+OC0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAww
# CgYIKwYBBQUHAwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8v
# b2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDow
# OKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRS
# b290RzQuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkq
# hkiG9w0BAQsFAAOCAgEAF877FoAc/gc9EXZxML2+C8i1NKZ/zdCHxYgaMH9Pw5tc
# BnPw6O6FTGNpoV2V4wzSUGvI9NAzaoQk97frPBtIj+ZLzdp+yXdhOP4hCFATuNT+
# ReOPK0mCefSG+tXqGpYZ3essBS3q8nL2UwM+NMvEuBd/2vmdYxDCvwzJv2sRUoKE
# fJ+nN57mQfQXwcAEGCvRR2qKtntujB71WPYAgwPyWLKu6RnaID/B0ba2H3LUiwDR
# AXx1Neq9ydOal95CHfmTnM4I+ZI2rVQfjXQA1WSjjf4J2a7jLzWGNqNX+DF0SQzH
# U0pTi4dBwp9nEC8EAqoxW6q17r0z0noDjs6+BFo+z7bKSBwZXTRNivYuve3L2oiK
# NqetRHdqfMTCW/NmKLJ9M+MtucVGyOxiDf06VXxyKkOirv6o02OoXN4bFzK0vlNM
# svhlqgF2puE6FndlENSmE+9JGYxOGLS/D284NHNboDGcmWXfwXRy4kbu4QFhOm0x
# JuF2EZAOk5eCkhSxZON3rGlHqhpB/8MluDezooIs8CVnrpHMiD2wL40mm53+/j7t
# FaxYKIqL0Q4ssd8xHZnIn/7GELH3IdvG2XlM9q7WP/UwgOkw/HQtyRN62JK4S1C8
# uw3PdBunvAZapsiI5YKdvlarEvf8EA+8hcpSM9LHJmyrxaFtoza2zNaQ9k+5t1ww
# ggbtMIIE1aADAgECAhAKgO8YS43xBYLRxHanlXRoMA0GCSqGSIb3DQEBCwUAMGkx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4
# RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYg
# MjAyNSBDQTEwHhcNMjUwNjA0MDAwMDAwWhcNMzYwOTAzMjM1OTU5WjBjMQswCQYD
# VQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lD
# ZXJ0IFNIQTI1NiBSU0E0MDk2IFRpbWVzdGFtcCBSZXNwb25kZXIgMjAyNSAxMIIC
# IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0EasLRLGntDqrmBWsytXum9R
# /4ZwCgHfyjfMGUIwYzKomd8U1nH7C8Dr0cVMF3BsfAFI54um8+dnxk36+jx0Tb+k
# +87H9WPxNyFPJIDZHhAqlUPt281mHrBbZHqRK71Em3/hCGC5KyyneqiZ7syvFXJ9
# A72wzHpkBaMUNg7MOLxI6E9RaUueHTQKWXymOtRwJXcrcTTPPT2V1D/+cFllESvi
# H8YjoPFvZSjKs3SKO1QNUdFd2adw44wDcKgH+JRJE5Qg0NP3yiSyi5MxgU6cehGH
# r7zou1znOM8odbkqoK+lJ25LCHBSai25CFyD23DZgPfDrJJJK77epTwMP6eKA0kW
# a3osAe8fcpK40uhktzUd/Yk0xUvhDU6lvJukx7jphx40DQt82yepyekl4i0r8OEp
# s/FNO4ahfvAk12hE5FVs9HVVWcO5J4dVmVzix4A77p3awLbr89A90/nWGjXMGn7F
# QhmSlIUDy9Z2hSgctaepZTd0ILIUbWuhKuAeNIeWrzHKYueMJtItnj2Q+aTyLLKL
# M0MheP/9w6CtjuuVHJOVoIJ/DtpJRE7Ce7vMRHoRon4CWIvuiNN1Lk9Y+xZ66laz
# s2kKFSTnnkrT3pXWETTJkhd76CIDBbTRofOsNyEhzZtCGmnQigpFHti58CSmvEyJ
# cAlDVcKacJ+A9/z7eacCAwEAAaOCAZUwggGRMAwGA1UdEwEB/wQCMAAwHQYDVR0O
# BBYEFOQ7/PIx7f391/ORcWMZUEPPYYzoMB8GA1UdIwQYMBaAFO9vU0rp5AZ8esri
# kFb2L9RJ7MtOMA4GA1UdDwEB/wQEAwIHgDAWBgNVHSUBAf8EDDAKBggrBgEFBQcD
# CDCBlQYIKwYBBQUHAQEEgYgwgYUwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp
# Z2ljZXJ0LmNvbTBdBggrBgEFBQcwAoZRaHR0cDovL2NhY2VydHMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0VHJ1c3RlZEc0VGltZVN0YW1waW5nUlNBNDA5NlNIQTI1NjIw
# MjVDQTEuY3J0MF8GA1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGluZ1JTQTQwOTZTSEEyNTYy
# MDI1Q0ExLmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJ
# KoZIhvcNAQELBQADggIBAGUqrfEcJwS5rmBB7NEIRJ5jQHIh+OT2Ik/bNYulCrVv
# hREafBYF0RkP2AGr181o2YWPoSHz9iZEN/FPsLSTwVQWo2H62yGBvg7ouCODwrx6
# ULj6hYKqdT8wv2UV+Kbz/3ImZlJ7YXwBD9R0oU62PtgxOao872bOySCILdBghQ/Z
# LcdC8cbUUO75ZSpbh1oipOhcUT8lD8QAGB9lctZTTOJM3pHfKBAEcxQFoHlt2s9s
# XoxFizTeHihsQyfFg5fxUFEp7W42fNBVN4ueLaceRf9Cq9ec1v5iQMWTFQa0xNqI
# tH3CPFTG7aEQJmmrJTV3Qhtfparz+BW60OiMEgV5GWoBy4RVPRwqxv7Mk0Sy4QHs
# 7v9y69NBqycz0BZwhB9WOfOu/CIJnzkQTwtSSpGGhLdjnQ4eBpjtP+XB3pQCtv4E
# 5UCSDag6+iX8MmB10nfldPF9SVD7weCC3yXZi/uuhqdwkgVxuiMFzGVFwYbQsiGn
# oa9F5AaAyBjFBtXVLcKtapnMG3VH3EmAp/jsJ3FVF3+d1SVDTmjFjLbNFZUWMXuZ
# yvgLfgyPehwJVxwC+UpX2MSey2ueIu9THFVkT+um1vshETaWyQo8gmBto/m3acaP
# 9QsuLj3FNwFlTxq25+T4QwX9xa6ILs84ZPvmpovq90K8eWyG2N01c4IhSOxqt81n
# MYIFBDCCBQACAQEwKDAUMRIwEAYDVQQDDAlTZWFuQzIyMjICEHD8a1zxLNiDRH4l
# PXovN6kwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKA
# ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgymvzJZ+yDe0bVg6b37dTYIHvUajM
# iCDE60QWSfUG4xEwDQYJKoZIhvcNAQEBBQAEggEAcBF3nrwa66dEQiYKxRW5CG95
# pQT9rCBqOW58vL02abMlR9m/7ogPEwKYgGiJWFvCufhOTo3Nejvvgz9iiaPmvQq2
# 2tqH3jdknkGOpCjeY5EjZUqWr3qbxPueHL+OcOi8WBqGuclJxWXMxUaWyFqFtpal
# 7ODYEdnP+lZNfCFne0hYjsqNREmevuBRnT6ZhkjaBIQYvdJ2BgY0r8Q+UYsMxx6g
# 4yzzHp3AKaVEVdzrxTN7Sjz8I2g/Zsv77s6rOMk3EbwY/fID/NjpDHONviVQyzAC
# ArnVLf2TKOsA2of5MD2SnYCvR8jfQGUsbJxQdCAgpxENfcRjKqpEMH6dFPFmRqGC
# AyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhL
# jfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNTExMjMwNDUyMjlaMC8GCSqGSIb3DQEJ
# BDEiBCDKLwnPUrnF79nwNlLr8ngkXtFt3oMK7JFBIT9tGDnM5jANBgkqhkiG9w0B
# AQEFAASCAgAOIfY66jm28ygyNCI9vzkpVdWnqSywvtlMwmA9C/yN/8eXO0GC0oEp
# dxo9cqWKRjIvx6CcjsIqdXx1FzQnanqckOf27Mz5C9517oHL3lL5XyMSdjYDHLZ9
# hpVTqeoNSS/pGXEEP5uinJzpOfhi3eYZzcK7QfeVPP4KniPCfDJFXZ2OczEg1Gt7
# PA5yNrC5ufUvzj95aqc5FZ2R7PMluD6Xdu4t1L2I3YvByqiJgujd1IeCoDfBQmQ8
# RUkBlFhm9zmcW4kPjqzw0Zq1OJzwfPraCYLY39yAt8mMzxGm8FbRC/kAHuOqMOKy
# JXmJJSg3TOJGNyb26SM42tUsXJTTWo06q/wOkJQMueC5fNEiuD0+vekydTw+5Dzf
# HLUhtCfX8cX/KE9KGZlbrFiI8dXQ8etjTS3Pi7JOw5TCB64MQF0bu/Z7gvHeS2ye
# 76yNhG0BDh+V/BaUAVhvTh/Yv1dknZNVWCHhWYKjJMg5cdhU1kpwSQvd2cm1afQR
# EabrJ9v4HFreqczYqX1gumWqmTmZggrFDLeNegRuBwi/QUkE3XQ1umn/YVSFWMkk
# 8gADS0xD3cTwHim9EBEagMd0IrO+Op+zsjVjKfrYwnIoOLUC7/vQa4uUJsmhDSaJ
# mHbd0keoJ1jjoxUg9L0CFZ+j0GDwVvOZA5t+3cY4kXJ2ax25DDRFSw==
# SIG # End signature block

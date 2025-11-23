# Getting started:

## WARNING:
In general you should not run scripts you don't understand from strangers on the internet. Especially when they involve steps like "grant permissions" before running.
Claims I make you should verify prior to using this, _or any_ tool for that matter, and don't trust software on your system.

## Background
This is a PowerShell solution to trimming out the What's New banner on the Library page that can't be disabled natively in steam. I hate it. You hate it. And it's tiring to make individual items hide. Sorry Steam, you missed on this one.

This solution includs a script that leverages the fact that the UI is an HTML page under the hood that leverages CSS to style the components. By setting a `display: none` property on the appropriate class, you tell the rendering engine to not actually bother rendering that component. Additionally, Steam validates the integrity of its resources prior to booting, so unless you tell it specifically _not_ to, changes made to the CSS will get reversed (Steam performs an "update" to restore the CSS file integrity). So a change needs to be made at the startup of Steam. This solution attempts to modify the shortcut that gets used in common Windows Startup locations, by adding a "-noverifyfiles" argument to the invocation of the exe that tells Steam to _not_ perform this validation and update to preserve your changes. This additionally adds the "-dev" argument which is limited in impact unless you know how to leverage the dev features.

This is the heart of the functionality.  This segment of logic has been packaged as a PowerShell module that can be directly invoked by other interesting solutions. It creates a backup of a file it modifies, and then writes a replacement file that Steam will use.

An additional script has been packaged that is very useful for the case where Steam _actually_ gets real updates (which will revert your changes, requiring you to run the `Remove-SteamWhatsNew` command again). `startup.ps1` can be run and it will handle shutting down any running process of Steam, then executing the `Remove-SteamWhatsNew` command in a standard way (using default values/locations).

Going one step further, there is a `Create-Shortcut.ps1` utility that is for creating an alternate Steam shortcut that you can pin to your taskbar or start menu for ease of use. Once you run this utility, a red steam shortcut will appear that knows how to invoke `startup.ps1` making a very handy entry point for the non-technically inclined.

# Standard Use

## Clone the Repo

Either use `git` to clone this whole repo, or alternatively you can download a `.zip` through GitHub by clicking the "<> Code v" button, then "Download ZIP" at the bottom. Unzip the file.

## Setup PowerShell Environment

NOTE: See warning.

Find PowerShell or PowerShell 7, and run as Administrator (right click, "Run as Administrator").

Set your script execution policy to either `AllSigned` (safer) or `RemoteSigned` (less safe). The default behavior is to not allow script execution to a standard Windows user. You can't run ANY scripts if you don't set a lower bar than the default `Undefined` which gets treated as `Restricted`.

In your Administrator PowerShell shell and paste in:
`Set-ExecutionPolicy AllSigned`
Hit 'Enter'

To allow a level of trust limited to these utilities, we need to run a bootstrapping script to install the trust certificate once. To do this we set our execution policy to Bypass just for the life of this shell process (once it closes, it reverts to the previously set policy).

In your Administrator PowerShell shell and paste in:
`Set-ExecutionPolicy Bypass -Scope Process`
Hit 'Enter'

## Install the Cert

NOTE: See warning. This is a homebrewed utility, and isn't meant to be commercialized so I signed the script with a local cert instead of a commercial one. Trust at your own risk.

Execute the `Install-Cert.ps1` by following the prompt. You should see a "SUCCESS" message when it completes.

To revoke trust, you can run:

```
$cert = Get-ChildItem 'Cert:\CurrentUser\Root' | Where-Object { $_.Subject -eq "CN=SeanC2222" }
$location = "HKCU:\Software\Microsoft\SystemCertificates\Root\Certificates\$($cert.Thumbprint)" # Certificates are stored in the registry

Remove-Item $location
```

OR you can use the User Certificates utility:

1) Windows Key + Q, "User Cert", or Windows Key + R, "certmgr.msc"
2) Expand "Trusted Root Certification Authorities"
3) Find "SeanC2222" in the certificate listings (SECURITY RISK: Don't touch other certs)
4) Click on it, and find the red 'X' along the command bar above the list.
5) Follow the prompts

## (Optional) Create the Shortcut

Now that the certificate is trusted, and you have an execution policy that requires signed scripts, run the `Create-Shortcut.ps1` script through your shell:

Execute the `Create-Shortcut.ps1` script. A new shortcut should appear called `Steam.lnk` (or just `Steam` if extensions are hidden).

At this point, you should be able to just double click on the shortcut to run the `startup.ps1` helper.

## (Optional) Test the Utility (`startup.ps1`)

From any shell with the not-`Restricted` and not-`Undefined` execution policies, execute the `startup.ps1` script.

This should shutdown any running steam process, and invoke the `Remove-SteamWhatsNew` module with default configurations.

# To use Remove-SteamWhatsNew:

Steps)
1) Open PowerShell
2) Run `Import-Module .\RemoveSteamWhatsNew.ps1`
3) Run `Remove-SteamWhatsNew`<br>
Optional Parameters:<br>
    `-SetNoVerifyInStartup $false`, Tries to set the Startup shortcuts to not verify the files if Steam boots on Windows startup<br>
    `-SteamLocation {Path to Steam directory}`, Steam's location if it's a nonstandard install location <br>
    `-TargetClass {Steam CSS class to target}`, Overrides the hardcoded CSS class name<br>
    `-TargetFile {Path to Steam css file to backup and modify}`, Overrides the hardcoded CSS file location

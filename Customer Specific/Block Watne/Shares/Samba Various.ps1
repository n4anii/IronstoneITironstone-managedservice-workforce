<#

    Resources
        Samba PowerShell https://docs.microsoft.com/en-us/powershell/module/smbshare

#>

Test-Path -Path '\\DESKTOP-3CV6GM6\Share'


Get-SmbShare
Get-SmbConnection | Select-Object -First 1 -Property '*'
Get-SmbSession
Disconnect-


Get-SmbMapping
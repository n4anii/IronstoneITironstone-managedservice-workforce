# Assets
$PathsDirDesktop = [string[]]$([string[]]$([string]$([System.Environment]::GetFolderPath('Desktop')),[string]$('{0}\Desktop' -f ($env:USERPROFILE))) | Where-Object -FilterScript {Test-Path -Path $_} | Sort-Object -Unique)
$PathProgram     = [string]('{0}\quickassist.exe' -f ([System.Environment]::SystemDirectory))


# Assets - Dynamic
$Shortcuts = [PSCustomObject[]]$(
    [PSCustomObject]@{
        'Name'         = 'Hurtighjelp.lnk'
        'TargetPath'   = $PathProgram
        'Arguments'    = ''
        'IconLocation' = $PathProgram
    }
)



# Create Shortcuts
$Exists = [bool[]]$(
    foreach ($PathDirDesktop in $PathsDirDesktop) {
        foreach ($Shortcut in $Shortcuts) {
            # Asset
            $PathFileShortcut = [string]$('{0}\{1}.lnk' -f ($PathDirDesktop,$Shortcut.'Name'))

            # Remove existing shortcut with same name
            [bool](Test-Path -Path $PathFileShortcut)
        }
    }
)


# Return result
if ($Exists -notcontains $false) {
    Write-Output -InputObject 'Success'
}
else {
    Write-Error -Message 'Fail' -ErrorAction 'Continue'
    Exit 1
} 

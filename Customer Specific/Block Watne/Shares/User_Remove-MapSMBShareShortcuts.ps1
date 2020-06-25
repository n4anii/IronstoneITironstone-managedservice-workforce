<#
    .SYNOPSIS
        Removes shortcuts and script files for the SMB mapping script.
#>




# Help variable
$Success = [bool] $true
$ErrorActionPreference = 'Stop'




################
Try {
################
# Directories
## Assets
$Paths = [string[]](
    ('{0}\IronstoneIT\Intune\Scripts\SMB' -f ($env:LOCALAPPDATA)),                # Script files
    ('{0}\Tools' -f ([Environment]::GetFolderPath('Desktop'))),                   # v1 of the SMB shortcut script
    ('{0}\Koble til fellesdisker' -f ([Environment]::GetFolderPath('Desktop')))   # v3 of the SMB shortcut script
)
## Remove
foreach ($Path in $Paths) {
    if ([System.IO.Directory]::Exists($Path)) {
        [System.IO.Directory]::Delete($Path,$true)
        if (-not $?) {
            $Success = [bool] $false
        }
    }
}




## v3 of the SMB shortcut script
### Asset
$Path = [string]('{0}' -f ([System.Environment]::GetFolderPath('Desktop')))
$Name = [string]('Koble til ``*´´.lnk')
### Remove if exist
[string[]]$(Get-ChildItem -Path $Path -Filter $Name -Depth 0 -Recurse:$false -File -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'FullName').ForEach{
    $null = [System.IO.File]::Delete($_)
    if (-not $?) {
        $Success = [bool] $false
        break
    }
}
################
}
################




Catch {
    $Success = [bool] $false
}



# Exit
if ($Success) {
    Write-Output -InputObject 'Success'
    Exit 0
}
else {
    Write-Error -Message 'Fail.' -ErrorAction 'Continue'
    Exit 1
}

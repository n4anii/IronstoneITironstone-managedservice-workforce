<#
.SYNOPSIS
Configures trusted sites for Windows / Internet Explorer

.DESCRIPTION


.AUTHOR
Olav R. Birkeland


.CHANGELOG
180119
- Initial Release


.RESOURCES
- How to Associate file 
  https://gallery.technet.microsoft.com/scriptcenter/How-to-associate-file-3898f323

#>



#region Variables
# Settings
[bool] $DebugWinTemp = $false
[bool] $DebugConsole = $true
[bool] $ReadOnly = $true
If ($DebugWinTemp) {[String] $Global:DebugStr=[String]::Empty}

# Script specific variables
[String] $WhatToConfig = 'Metier - Set Default Programs for File Extensions'
#endregion Variables



#region Functions
    #region Write-DebugIfOn
    Function Write-DebugIfOn {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $In
        )
        If ($DebugConsole) {
            Write-Output -InputObject $In
        }
        If ($DebugWinTemp) {
            $Global:DebugStr += ($In + "`r`n")
        }
    }
    #endregion Write-DebugIfOn


    #region Associate-FileExtensions
    Function Associate-FileExtensions {
        Param (
            [Parameter(Mandatory=$true)]
            [String[]] $FileExtensions,
            [Parameter(Mandatory=$true)]
            [String] $OpenAppPath
        ) 
        if (-not (Test-Path $OpenAppPath)) {
	       Write-DebugIfOn -In ($OpenAppPath + ' does not exist.')
        }   
        foreach ($extension in $FileExtensions) {
            $FileType = (cmd /c ('assoc {0}' -f ($extension)))
            $FileType = $FileType.Split("=")[-1] 
            cmd /c "ftype $FileType=""$OpenAppPath"" ""%1"""
        }
    }
    #endregion Associate-FileExtensions

#endregion Functions



#region Initialize
[String] $Script:CompName = $env:COMPUTERNAME
[System.Management.ManagementObject] $Script:WMIInfo = Get-WmiObject -Class win32_operatingsystem
[String] $Script:WindowsEdition = $Script:WMIInfo.Caption
[String] $Script:WindowsVersion = $Script:WMIInfo.Version
If ($DebugWinTemp -or $DebugConsole) {   
    Write-DebugIfOn -In '### Environment Info'
    Write-DebugIfOn -In ('Script settings: DebugConsole = ' + $DebugConsole + ' | DebugWinTemp = ' + $DebugWinTemp + ' ' + ' | ReadOnly = ' + $ReadOnly)
    Write-DebugIfOn -In ('Host (' + $Script:CompName + ') runs: ' + $Script:WindowsEdition + ' v' + $Script:WindowsVersion)
}
#endregion Initialize



#region Main
    Write-DebugIfOn -In ("`r`n" + '### ' + $WhatToConfig)
    Associate-FileExtensions -FileExtensions @('.pdf','.pdx') -OpenAppPath 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe'

#endregion Main



#region Debug
If ($DebugWinTemp) {
    If ([String]::IsNullOrEmpty($DebugStr)) {
        $DebugStr = 'Everything failed'
    }

    # Write Output
    $DebugPath = 'C:\Windows\Temp\'
    $CurDate = Get-Date -Uformat '%y%m%d'
    $CurTime = Get-Date -Format 'HHmmss'
    $DebugFileName = ('Debug Powershell ' + $WhatToConfig + ' ' + $CurDate + $CurTime + '.txt')

    $DebugStr | Out-File -FilePath ($DebugPath + $DebugFileName) -Encoding 'utf8'
    If (!($?)) {
        $DebugStr | Out-File -FilePath ($env:TEMP + '\' + $DebugFileName) -Encoding 'utf8'
    }
}
#endregion Debug
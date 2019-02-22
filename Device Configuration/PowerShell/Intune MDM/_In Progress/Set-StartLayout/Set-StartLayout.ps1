<#
.SYNOPSIS
    <Short, what it does>


.DESCRIPTION
    <Long, what it does>


.OUTPUTS
    <What it outputs during runtime>


Usage:


Todo:


Resources:
    - https://docs.microsoft.com/en-us/windows/configuration/start-layout-xml-desktop
    - Usefull commands
        Get current apps in start menu
            Get-StartApps | Sort-Object Name > $HOME\Desktop\StartApps.txt
        Get current layout
            Copy-Item -Path C:\Users\$env:USERNAME\AppData\Local\Microsoft\Windows\Shell\DefaultLayouts.xml -Destination $HOME\Desktop\DefaultLayouts.xml



#>



#region Variables
# Settings
[bool] $DebugWinTemp = $false
[bool] $DebugConsole = $true
[bool] $ReadOnly = $true
If ($DebugWinTemp) {[String] $Global:DebugStr=[String]::Empty}

# Script specific variables
[String] $WhatToConfig = 'Set Start menu layout'
[String] $PathStartLayout = ('C:\Users\' + ('{0}' -f $env:USERNAME) + '\AppData\Local\Microsoft\Windows\Shell\')
[String] $PathBackup = ('{0}\Desktop\' -f $Home)
[String] $FileDefaultLayouts = 'DefaultLayouts.xml'
[String] $FileLayoutModification = 'LayoutModification.xml'
[String] $LayoutModification_OnlyControlPanel = ('<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate
    xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
    xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
    xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
    xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"
    Version="1">
  <DefaultLayoutOverride>
    <StartLayoutCollection>
      <defaultlayout:StartLayout GroupCellWidth="6">
        <start:Group Name="">
          <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationID="Microsoft.Windows.ControlPanel" />
        </start:Group>
      </defaultlayout:StartLayout>
    </StartLayoutCollection>
  </DefaultLayoutOverride>
</LayoutModificationTemplate>
')
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


    #region Backup-StartLayout
    Function Backup-StartLayout {
        Write-DebugIfOn -In 'Function Backup-StartLayout'
        Copy-Item -Path ($PathStartLayout + $FileDefaultLayouts) -Destination ($PathBackup + $FileDefaultLayouts)
        If ($?) {
            Write-DebugIfOn -In '  Successfully backed up Start menu layout!'
        }
        Else {
            Write-DebugIfOn -In '  Failed to back up Start menu layout!'
        }
    }
    #endregion Backup-StartLayout


    #region Restore-StartLayout
    Function Restore-StartLayout {
        Write-DebugIfOn -In 'Function Restore-StartLayout'
        If (!($ReadOnly)) {
            Write-DebugIfOn -In '  Trying to restore DefaultLayouts.xml'
            Copy-Item -Path ($PathBackup + $FileDefaultLayouts) -Destination ($PathStartLayout + $FileDefaultLayouts)
            If ($?) {
                Write-DebugIfOn -In '    Success!'
            }
            Else {
                Write-DebugIfOn -In '    Fail!'
            }
        }
        Else {
            Write-DebugIfOn -In '  ReadOnly mode'
        }
    }
    #endregion Restore-StartLayout


    #region Write-LayoutModificationXML
    Function Write-LayoutModificationXML {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $In    
        )
        Write-DebugIfOn -In 'Function Write-LayoutModificationXML'
        If (!($ReadOnly)) {
            Write-DebugIfOn -In '  Trying to write LayoutModification.xml'
            Out-File -FilePath ($PathStartLayout + $FileLayoutModification) -InputObject $In
            If ($?) {
                Write-DebugIfOn '    Success!'
            }
            Else {
                Write-DebugIfOn '    Failed!'
            }
        }
        Else {
            Write-DebugIfOn -In '  ReadOnly mode'
        }
    }
    #endregion Write-LayoutModifiationXML
#endregion Functions



#region Initialize
If ($DebugWinTemp -or $DebugConsole) {
    [String] $ComputerName = $env:COMPUTERNAME
    [String] $WindowsEdition = (Get-WmiObject -Class win32_operatingsystem).Caption
    [String] $WindowsVersion = (Get-WmiObject -Class win32_operatingsystem).Version
    Write-DebugIfOn -In '### Environment Info'
    Write-DebugIfOn -In ('Script settings: DebugConsole = ' + $DebugConsole + ' | DebugWinTemp = ' + $DebugWinTemp + ' ' + ' | ReadOnly = ' + $ReadOnly)
    Write-DebugIfOn -In ('Host runs: ' + $WindowsEdition + ' v' + $WindowsVersion)
}
#endregion Initialize



#region Main
    # Setting start menu layout
    Write-DebugIfOn -In ("`r`n" + '### {0}' -f $WhatToConfig)
    Backup-StartLayout
    Write-LayoutModificationXML -In $LayoutModification_OnlyControlPanel
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
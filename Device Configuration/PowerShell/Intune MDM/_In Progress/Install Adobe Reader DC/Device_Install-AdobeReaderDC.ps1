#region Settings
    # Settings - Language
    [string] $Lang = 'nbNO'
    # Settings - Client vs Server
    [bool] $IsClient = $false
    # Settings - PowerShell
    $DebugPreference = 'SilentlyContinue'
    $ProgressPreference = 'Continue'
    $VerbosePreference = 'Continue'
    $WarningPreference = 'Continue'
    $ErrorActionPreference = 'Stop'
#endregion




#region Program info
    [string] $AdobeReaderDCUpdate = 'ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/1900820080/AcroRdrDCUpd1900820080.msp'
    [PSCustomObject[]] $AdobeReaderDC =  @(
        #Language, DL URL
        @('nbNO','ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/1500720033/AcroRdrDC1500720033_nb_NO.msi'),
        @('svSE','ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/1500720033/AcroRdrDC1500720033_sv_SE.msi'),
        @('enUS','ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/1500720033/AcroRdrDC1500720033_en_US.msi')
    )
#endregion 




#region    Build Variables
    [string] $TimeStamp          = Get-Date -Format 'yyMMddHHmmss'
    [string] $PathDirDL          = ('{0}\Temp\' -f ($env:windir))
    [string] $PathDirLog         = ('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration\' -f ($env:SystemDrive))
    [string] $NameProgram        = 'AdobeReaderDC'
    [string] $PathFileInstall    = ('{0}{1}Install.msi' -f ($PathDirDL,$NameProgram))
    [string] $PathFileUpdate     = ('{0}{1}Update.msp' -f ($PathDirDL,$NameProgram))
    [string] $PathFileLogInstall = ('{0}MSIExec-Install-{1}.log' -f ($PathDirLog,$NameProgram))

    $InstallParametersInstallOnly = 'msiexec.exe /i "{0}" /quiet /norestart /log "{1}"'
    $InstallParametersInstallAndUpdate = 'msiexec.exe /i "{0}" /update "{1}" /quiet /norestart /log "{2}"'
#endregion Build Variables




#region    Download and Install
    try {
        #region    Download Files
            [PSCustomObject[]] $FilesToDownload = @(
                #@('URL','DESTINATION',
                @(($AdobeReaderDC | Where-Object {$_[0] -eq $Lang})[1],$PathFileInstall),
                @($AdobeReaderDCUpdate,$PathFileUpdate)
            )

            foreach ($Item in $FilesToDownload) {
                if ($Item[0].Split(':')[0] -eq 'ftp') {
                    (New-Object System.Net.WebClient).DownloadFile($Item[0],$Item[1])
                }
                else {
                    Start-BitsTransfer -Source $Item[0] -Destination $Item[1]
                }      
            }
        #endregion Download Files


        #region    Install
            # Both at the same time
            cmd /c ($InstallParametersInstallAndUpdate -f ($PathFileInstall,$PathFileUpdate,$PathFileLogInstall))
        #endregion Install
    }
#endregion Download and Install



#region    Clean up
finally {   
        Remove-Item -Path $PathFileInstall -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $PathFileUpdate -Force -ErrorAction SilentlyContinue
}
#endregion Clean Up
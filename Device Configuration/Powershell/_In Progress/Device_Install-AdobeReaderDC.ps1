#region Settings
    [string] $Lang = 'nbNO'
#endregion



#region Program info
    $AdobeReaderDCUpdate = 'ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/1801120036/AcroRdrDCUpd1801120036.msp'
    [PSCustomObject[]] $AdobeReaderDC =  @(
        @('nbNO','ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/1500720033/AcroRdrDC1500720033_nb_NO.msi'),
        @('svSE','ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/1500720033/AcroRdrDC1500720033_sv_SE.msi'),
        @('enUS','ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/1500720033/AcroRdrDC1500720033_en_US.msi')
    )
#endregion 



#region Build Variables
    [string] $TimeStamp          = Get-Date -Format 'yyMMddHHmmss'
    [string] $PathDirDL          = ('{0}\Temp\' -f ($env:windir))
    [string] $PathDirLog         = ('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive))
    [string] $NameProgram        = 'AdobeReaderDC'
    [string] $PathFileInstall    = ('{0}{1}Install.msi' -f ($PathDirDL,$NameProgram))
    [string] $PathFileUpdate     = ('{0}{1}Update.msp' -f ($PathDirDL,$NameProgram))
    [string] $PathFileLogInstall = ('{0}MSIExec-Install-{1}.log' -f ($PathDirLog,$NameProgram))

    $InstallParametersAdobeReaderDCAndUpdate = 'msiexec.exe /i "{0}" /update "{1}" /quiet /norestart /log "{2}"'
#endregion



#region Download Files
    [string] $URLFileInstall = ($AdobeReaderDC | Where-Object {$_[0] -eq $Lang})[1]
    [string] $URLFileUpdate  = $AdobeReaderDCUpdate

    (New-Object System.Net.WebClient).DownloadFile($URLFileInstall,$PathFileInstall)
    (New-Object System.Net.WebClient).DownloadFile($URLFileUpdate,$PathFileUpdate)
#endregion



#region Install
    # Both at the same time
    cmd /c ($InstallParametersAdobeReaderDCAndUpdate -f ($PathFileInstall,$PathFileUpdate,$PathFileLogInstall))
#endregion



#region Clean up
    Remove-Item -Path $PathFileInstall -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $PathFileUpdate -Force -ErrorAction SilentlyContinue
#endregion
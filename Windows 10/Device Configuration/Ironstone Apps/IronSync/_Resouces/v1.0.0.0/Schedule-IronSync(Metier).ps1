#Requires -RunAsAdministrator

#region    Initialize - Settings and Variables
    # Variables - Script
    [string] $NameScript      = 'IronSync'
    [string] $NameFileScript  = ('Schedule-{0}' -f ($NameScript))
    [bool] $BoolScriptSuccess = $true
    # Variables - Log
    [string] $PathDirLog   = ('{0}\Program Files\IronstoneIT\{1}\Logs\' -f ($env:SystemDrive,$NameScript))
    [string] $NameFileLog  = ('{0}-runlog-{1}.log' -f ($NameScript,(Get-Date -Format 'yyMMddhhmmss')))
    [string] $PathFileLog  = ('{0}{1}' -f ($PathDirLog,$NameFileLog))
    # Variables - Environment
    [string] $PathDirSync  = ('{0}\Users\Public\OfficeTemplateMO' -f ($env:SystemDrive))
    # Settings - PowerShell
    $DebugPreference       = 'SilentlyContinue'
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'SilentlyContinue'
    $ProgressPreference    = 'SilentlyContinue'
    $VerbosePreference     = 'Continue'
    $WarningPreference     = 'Continue'
#endregion Initialize - Settings and Variables


try {
#region     Main
    #region    Logging
    if (-not(Test-Path -Path $PathDirLog)) {New-Item -Path $PathDirLog -ItemType 'Directory' -Force}
    Start-Transcript -Path $PathFileLog
    #endregion Logging
    

    #region    AzCopy
        <# Switches
            /Z        = Journal file folder, for AzCopy to resume operation
            /Y        = Surpress all confirmations
            /S        = Specifies recursive mode for copy operations. In recursive mode, AzCopy will copy all blobs or files that match the specified file pattern, including those in subfolders.
            /CheckMD5 = See if destination matches source MD5
            /L        = Specifies a listing operation only; no data is copied.
            /MT       = Sets the downloaded file's last-modified time to be the same as the source blob or file's.
            /XN       = Excludes a newer source resource. The resource will not be copied if the source is the same or newer than destination.
            /XO       = Excludes an older source resource. The resource will not be copied if the source resource is the same or older than destination.
        #>
        [string] $PathFileAzCopy = ('{0}\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' -f ($env:SystemDrive))
        [string] $PathDirAzCopyJournal = ('{0}\Program Files\IronstoneIT\{1}\AzCopyJournal\' -f ($env:SystemDrive,$NameScript))
    #endregion AzCopy


    #region    Using SAS Token
        # Connection Info
        [string] $BlobAccountName    = 'metierclientstorage'
        [string] $BlobAccountURL     = ('https://{0}.blob.core.windows.net' -f ($BlobAccountName))
        [string] $BlobAccountBlobURL = ('{0}/office365-templates' -f ($BlobAccountURL))
        [string] $SASToken           = '?sv=2017-07-29&ss=b&srt=co&sp=rl&se=2019-01-01T21:05:29Z&st=2018-04-11T12:05:29Z&spr=https&sig=K77IKMwiMS7I15DL%2FwtbbPEDDIGARtiWcdJo3U1YGF4%3D'
        # Download
        $null = Start-Process -FilePath $PathFileAzCopy -WindowStyle 'Hidden' -ArgumentList ('/Source:{0} /Dest:{1} /SourceSAS:{2} /Z:"{3}" /Y /S /MT /XO' -f ($BlobAccountBlobURL,$PathDirSync,$SASToken,$PathDirAzCopyJournal)) -Wait
        if ( (-not($?)) -or ((Get-ChildItem -Path $PathDirSync -Force).Length -le 0) ) {
            $BoolScriptSuccess = $false
        }
    #endregion Using SAS Token
#endregion Main
}


finally {
    # Don't keep the log file if success
    Stop-Transcript
    if ($BoolScriptSuccess) {
        Remove-Item -Path $PathFileLog -Force
    }
}
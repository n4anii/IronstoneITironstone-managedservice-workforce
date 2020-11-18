#Requires -RunAsAdministrator

<#
    .DESCRIPTION
        This script will sync down a Azure Storage Account Blob Container to specified folder

    .USAGE
        * You should only need to edit the variables inside "#region Variables - EDIT THESE ONLY"
        * Remember to embed it into the install script as BASE64!
        * Remember to use the same folders in both installer and schedule script!
            * PathDirSync          = Folder to sync the Azure Blob files
            * PathDirAzCopyJournal = AzCopy Journal Files. AzCopy won't function without it
#>


#region    Initialize - Settings and Variables
    # Variables - Script
    [string] $NameScript      = 'IronSync'
    [string] $NameFileScript  = ('Schedule-{0}' -f ($NameScript))
    [bool] $BoolScriptSuccess = $true
    # Variables - Log
    [string] $PathDirLog   = ('{0}\Program Files\IronstoneIT\{1}\Logs\' -f ($env:SystemDrive,$NameScript))
    [string] $NameFileLog  = ('{0}-runlog-{1}.log' -f ($NameScript,(Get-Date -Format 'yyMMddhhmmss')))
    [string] $PathFileLog  = ('{0}{1}' -f ($PathDirLog,$NameFileLog))
    # Settings - PowerShell
    $DebugPreference       = 'SilentlyContinue'
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'SilentlyContinue'
    $ProgressPreference    = 'SilentlyContinue'
    $VerbosePreference     = 'Continue'
    $WarningPreference     = 'Continue'

    #region    Variables - EDIT THESE ONLY
        # Variables - Environment
        [string] $PathDirSync  = ('{0}\Users\Public\OfficeTemplates\' -f ($env:SystemDrive))
        # Variabled - Connection Info
        [string] $StorageAccountName     = 'metierclientstorage'
        [string] $StorageAccountSASToken = '?sv=2017-07-29&ss=b&srt=co&sp=rl&se=2019-01-01T21:05:29Z&st=2018-04-11T12:05:29Z&spr=https&sig=K77IKMwiMS7I15DL%2FwtbbPEDDIGARtiWcdJo3U1YGF4%3D'                     
    #endregion Variables - EDIT THESE ONLY
#endregion Initialize - Settings and Variables


try {
#region     Main
    #region    Logging
        if (-not(Test-Path -Path $PathDirLog)) {New-Item -Path $PathDirLog -ItemType 'Directory' -Force}
        Start-Transcript -Path $PathFileLog
    #endregion Logging
    


    #region    AzCopy - Variables
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
        [string] $StorageAccountURL    = ('https://{0}.blob.core.windows.net' -f ($StorageAccountName))
        [string] $StorageAccountBlobURL= ('{0}/office365-templates' -f ($StorageAccountURL))
        [string] $PathFileAzCopy       = ('{0}\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' -f ($env:SystemDrive))
        [string] $PathDirAzCopyJournal = ('{0}\Program Files\IronstoneIT\{1}\AzCopyJournal\' -f ($env:SystemDrive,$NameScript))
    #endregion AzCopy - Variables



    #region    Check if neccessary paths exist
        Write-Output -InputObject ('# Checking for neccessary paths and files')
        [string[]] $PathsToCheck = @($PathDirSync,$PathFileAzCopy,$PathDirAzCopyJournal)
        foreach ($Path in $PathsToCheck) {
            if (Test-Path -Path $Path) {
                Write-Output -InputObject ('   Success - {0} does exist.' -f ($Path))
            }
            else {
                Write-Output -InputObject ('   Error - {0} does NOT exists. Can not continue without it' -f ($Path))
                $BoolScriptSuccess = $false
            }
        }
        If (-not($BoolScriptSuccess)) {Break}
    #endregion Check if neccessary paths exist
        



    #region    AzCopy - Sync down using SAS Token       
        # Download
        $null = Start-Process -FilePath $PathFileAzCopy -WindowStyle 'Hidden' -ArgumentList ('/Source:{0} /Dest:{1} /SourceSAS:{2} /Z:"{3}" /Y /S /MT /XO' -f ($StorageAccountBlobURL,$PathDirSync,$StorageAccountSASToken,$PathDirAzCopyJournal)) -Wait
        if ( (-not($?)) -or ((Get-ChildItem -Path $PathDirSync -File -Force).Length -le 0) ) {
            Write-Output -InputObject ('ERROR - No files found in directory "{0}" after AzCopy finished.' -f ($PathDirSync))
            $BoolScriptSuccess = $false
        }
    #endregion AzCopy - Sync down using SAS Token
#endregion Main
}



finally {
    # Stop Transcript
    Stop-Transcript
    # Don't keep the log file if success
    if ($BoolScriptSuccess) {Remove-Item -Path $PathFileLog -Force}
}
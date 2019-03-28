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
    #region    Inserted Static Variables
        # IronSync
        $NameScript             = [string]$('###VARIABLESTATIC01###')
        # Azure Storage Account Connection Info
        $StorageAccountName     = [string]$('###VARIABLESTATIC02###')
        $StorageAccountBlobName = [string]$('###VARIABLESTATIC03###')
        $StorageAccountSASToken = [string]$('###VARIABLESTATIC04###')
    #endregion Inserted Static Variables

    #region    Dynamic Variables 1
        # IronSync
        $NameScriptNoun         = [string]$($NameScript.Split('-')[-1].Replace('.ps1',''))
    #endregion Dynamic Variables 1

    #region    Inserted Dynamic Variables
        # IronSync
        $PathDirIronSync        = "###VARIABLEDYNAMIC01###"
        $PathDirLog             = "###VARIABLEDYNAMIC02###"
        # Folder for Synced Files
        $PathDirSync            = "###VARIABLEDYNAMIC03###"
        # AzCopy
        $PathFileAzCopy         = "###VARIABLEDYNAMIC04###"
        $PathDirAzCopyJournal   = "###VARIABLEDYNAMIC05###"
    #endregion Inserted Dynamic Variables
    
    
    #region    Dynamic Variables 2
        # IronSync - Log
        $NameFileLog            = [string]$('{0}-runlog-{1}.log' -f ($NameScriptNoun,[datetime]::Now.ToString('yyMMdd-HHmmss')))
        $PathFileLog            = [string]$('{0}\{1}' -f ($PathDirLog,$NameFileLog))
        # Azure Storage Account Connection Info
        $StorageAccountBlobURL  = [string]$('https://{0}.blob.core.windows.net/{1}' -f ($StorageAccountName,$StorageAccountBlobName))
    #endregion Dynamic Variables 2


    #region    Help Variables
        $BoolScriptSuccess      = [bool]$($true)
    #endregion Help Variables
  
     
    #region    Settings - PowerShell
        $DebugPreference        = 'SilentlyContinue'
        $ErrorActionPreference  = 'Stop'
        $InformationPreference  = 'SilentlyContinue'
        $ProgressPreference     = 'SilentlyContinue'
        $VerbosePreference      = 'Continue'
        $WarningPreference      = 'Continue'
    #endregion Settings - PowerShell
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
    #endregion AzCopy - Variables



    #region    Check if neccessary paths exist
        Write-Output -InputObject ('# Checking for neccessary paths and files')
        $PathsToCheck = [string[]]@($PathDirSync,$PathFileAzCopy,$PathDirAzCopyJournal)
        foreach ($Path in $PathsToCheck) {
            if (Test-Path -Path $Path) {
                Write-Output -InputObject ('   Success - {0} does exist.' -f ($Path))
            }
            else {
                Write-Output -InputObject ('   Error - {0} does NOT exists. Can not continue without it' -f ($Path))
                $BoolScriptSuccess = $false
            }
        }
        if (-not($BoolScriptSuccess)) {Break}
    #endregion Check if neccessary paths exist
        



    #region    AzCopy - Sync down using SAS Token       
        # If Files In Use - Exit and set $BoolScriptSuccess to $false to keep log
        if (@(Get-ChildItem -Path $PathDirSync -Recurse -Force -File | Where-Object {$_.Name -Like '~$*' -and $_.Mode -eq '-a-h--'}).Count -ge 1) {
            Write-Output -InputObject ('Files are in use, AzCopy would have failed. Exiting.')
            $BoolScriptSuccess = $false
        }
        else {
            # Syncronize files down from Azure Storage Account Blob
            $AzCopyExitCode = [int16]$(0)
            Try {
                Write-Output -InputObject ('#### Start AzCopy Output ####')
                & cmd /c ('"{4}" /Source:{0} /Dest:"{1}" /SourceSAS:"{2}" /Z:"{3}" /Y /S /MT /XO' -f ($StorageAccountBlobURL,$PathDirSync,$StorageAccountSASToken,$PathDirAzCopyJournal,$PathFileAzCopy))
                $AzCopyExitCode = $LASTEXITCODE
            }
            Catch{$AzCopyExitCode=-1}
            Finally{Write-Output -InputObject ('#### End AzCopy Output ####')}
            Write-Output -InputObject ('AzCopy Exit Code: {0}.' -f ($AzCopyExitCode))


            # If Fail - Write Output and set $BoolScriptSuccess to keep log
            if ([int16]$($LASTEXITCODE) -eq [int16](-1)) {
                Write-Output -InputObject ('ERROR   - Last Exit Code Does Not Smell Like Success: {0}.' -f ($AzCopyExitCode.ToString()))
                $BoolScriptSuccess = $false
            }
            elseif (@(Get-ChildItem -Path $PathDirSync -File -Force).Length -le 0) {
                Write-Output -InputObject ('ERROR   - No files found in directory "{0}" after AzCopy finished.' -f ($PathDirSync))
                $BoolScriptSuccess = $false
            }
            else {
                Write-Output -InputObject ('SUCCESS - Healthy Exit Code and More Than 1 Files Found In Sync Path.')
            }
        }
    #endregion AzCopy - Sync down using SAS Token
#endregion Main
}

catch {
    $BoolScriptSuccess = $false
}

finally {
    # Stop Transcript
    Stop-Transcript
    # Don't keep the log file if success
    if ($BoolScriptSuccess) {Remove-Item -Path $PathFileLog -Force}
}
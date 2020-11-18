#Requires -RunAsAdministrator

<#
    .SYNAPSIS
        This script will sync down a Azure Storage Account Blob Container to specified folder

    .DESCRIPTION
        This script will sync down a Azure Storage Account Blob Container to specified folder

    .NOTES
        Author:   Olav Roennestad Birkeland @ Ironstone IT
        Modified: 200520
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
        $PathFileAzCopy10       = "###VARIABLEDYNAMIC06###"
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



#region Try
#################################
Try {
#################################


# Logging
## Create log dir if not exist
if (-not(Test-Path -Path $PathDirLog)) {
    New-Item -Path $PathDirLog -ItemType 'Directory' -Force
}
## Start logging
$null = Start-Transcript -Path $PathFileLog -Force

    


# Prerequisites & Tests
## Check what AzCopy version is available - Prefer v10, fallback to v8.1.0
Write-Output -InputObject ('# Check what AzCopy version is available - Prefer v10, fallback to v8.1.0')
$UseAzCopy10 = [bool][System.IO.File]::Exists($PathFileAzCopy10)
if ($UseAzCopy10) {
    $PathFileAzCopy = $PathFileAzCopy10
}

## Check if neccessary paths exist
Write-Output -InputObject ('# Check if neccessary paths exist')
$PathsToCheck = [string[]]$($PathDirSync,$PathFileAzCopy,$(if(-not$UseAzCopy10){$PathDirAzCopyJournal}))
foreach ($Path in $PathsToCheck) {
    if (Test-Path -Path $Path) {
        Write-Output -InputObject ('{0}SUCCESS - "{1}" does exist.' -f ("`t",$Path))
    }
    else {
        Write-Output -InputObject ('{0}ERROR   - "{1}" does NOT exists. Can not continue without it' -f ("`t",$Path))
        $BoolScriptSuccess = $false
    }
}
if (-not($BoolScriptSuccess)) {
    Break
}


## Check if running already
Write-Output -InputObject ('# Check if running already')
if (
    [array](
        Get-Process -Name 'AzCopy' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Path' | ForEach-Object -Process {
            $_.Replace(('\{0}' -f ($_.Split('\')[-1]),''))
        } | Sort-Object -Unique
    ) -contains [string]$(if($PathFileAzCopy[-1] -eq '\'){$PathFileAzCopy.Substring(0,$PathFileAzCopy.'Length'-1)}else{$PathFileAzCopy})
) {
    Write-Output -InputObject ('{0}ERROR   - AzCopy is already running.' -f ("`t",$Path))
    $BoolScriptSuccess = $false
}
if (-not($BoolScriptSuccess)) {
    Break
}
        
## Check if AzCopy.exe v8.1.0 journal leftovers are left from previous runs
if (-not $UseAzCopy10) {
    Write-Output -InputObject ('# Check if AzCopy journal leftovers from previous runs')
    ### Get AzCopy journal files
    $JournalFiles = [array](Get-ChildItem -Path $PathDirAzCopyJournal -File -Recurse:$false)
    ### If any found, delete them if more than 1 day old. Else: Error.
    if ($JournalFiles.'Count' -ge 1) {
        Write-Output -InputObject 'Found AzCopy journal files.'
        if ([bool[]]$($JournalFiles.ForEach{$_.'LastWriteTime' -le [datetime]::Now.AddDays(-1)}) -contains $false) {
            Write-Output -InputObject 'AzCopy journal files are not older than 24h. Will not delete.'
            $BoolScriptSuccess = $false
        }
        else {
            # Attempt to delete
            $DeleteJournalFilesSuccess = [bool[]]$(
                $JournalFiles.ForEach{
                    Try{
                        $null=Remove-Item -Path $_.'FullName' -Recurse:$false -ErrorAction 'SilentlyContinue'
                        [bool]($? -and -not [bool](Test-Path -Path $_.'FullName'))
                    }
                    Catch{
                        [bool]($false)
                    }
                }
            )
            if ($DeleteJournalFilesSuccess -contains $false) {
                Write-Output -InputObject ('{0}ERROR   - Failed to delete some of the journal files.' -f ("`t"))
                $BoolScriptSuccess = $false
            }
        }
    }
    if (-not($BoolScriptSuccess)) {
        Break
    }
}

## Check Internet Connectivity
Write-Output -InputObject ('# Check Internet Connectivity')
if ([bool]$($null = Resolve-DnsName -Name 'blob.core.windows.net' -ErrorAction 'SilentlyContinue';$?)) {
    Write-Output -InputObject ('{0}SUCCESS - Could resolve "blob.core.windows.net".' -f ("`t"))
}
else {
    Write-Output -InputObject ('{0}ERROR   - Could not resolve "blob.core.windows.net".' -f ("`t"))
    Write-Output -InputObject ('{0}{0}Either no internet connectivity, or Azure Storage is down.' -f ("`t"))
    $BoolScriptSuccess = $false
}
if (-not($BoolScriptSuccess)) {
    Break
}




# Sync with AzCopy
<#
    Switches v10.x.x
        azcopy sync <source> <destination> [flags]
        --cap-mbps=<n>            = Cap bandwidth in megabits per second
        --check-md5=<option>      = How strict to check downloaded content checksum. Default = FailIfDifferent.
        --recursive=<true/false>  = Recurse
        --output-type=<json/text> = Whether output from azcopy.exe should be formatted as JSON or string (default)        

    Switches v8.1.0
        /Z        = Journal file folder, for AzCopy to resume operation
        /Y        = Surpress all confirmations
        /S        = Specifies recursive mode for copy operations. In recursive mode, AzCopy will copy all blobs or files that match the specified file pattern, including those in subfolders.
        /CheckMD5 = See if destination matches source MD5
        /L        = Specifies a listing operation only; no data is copied.
        /MT       = Sets the downloaded file's last-modified time to be the same as the source blob or file's.
        /XN       = Excludes a newer source resource. The resource will not be copied if the source is the same or newer than destination.
        /XO       = Excludes an older source resource. The resource will not be copied if the source resource is the same or older than destination.
#>

            
# If Files In Use - Exit and set $BoolScriptSuccess to $false to keep log
if (@(Get-ChildItem -Path $PathDirSync -Recurse -Force -File | Where-Object -FilterScript {$_.'Name' -Like '~$*' -and $_.'Mode' -eq '-a-h--'}).'Count' -ge 1) {
    Write-Output -InputObject ('Files are in use, AzCopy would have failed. Exiting.')
    $BoolScriptSuccess = $false
}
else {
    # Build argument    
    $Arguments = [string[]]$(
        if ($UseAzCopy10) {            
            ('"{0}"' -f ($PathFileAzCopy10)),                                  # AzCopy.exe v10.x.x path
            ('sync'),                                                          # Sync flag
            ('"{0}{1}"' -f ($StorageAccountBlobURL,$StorageAccountSASToken)),  # Source URL with SAS token
            ('"{0}"' -f ($PathDirSync)),                                       # Destination
            ('--cap-mbps=0'),                                                  # Do not cap bandwidth (0 = no cap)
            ('--check-md5=FailIfDifferent'),                                   # Check MD5 sum, fail if different
            ('--delete-destination=true'),                                     # Delete files from destination not in source anymore
            ('--output-type=text'),                                            # Output from azcopy.exe
            ('--recursive=true')                                               # Recurse
        }
        else {
            ('"{0}"' -f ($PathFileAzCopy)),                                    # AzCopy v8.1.0 path
            ('/Source:"{0}"' -f ($StorageAccountBlobURL)),                     # Source
            ('/Dest:"{0}"' -f ($PathDirSync)),                                 # Destination
            ('/SourceSAS:"{0}"' -f ($StorageAccountSASToken)),                 # SAS key
            ('/Z:"{0}"' -f ($PathDirAzCopyJournal)),                           # AzCopy journal directory
            ('/Y'),                                                            # Surpress all confirmations
            ('/S'),                                                            # Specifies recursive mode for copy operations
            ('/MT'),                                                           # Sets the downloaded file's last-modified time to be the same as the source blob or file's
            ('/XO')                                                            # Excludes an older source resource
        }
    )

    # Syncronize files down from Azure Storage Account Blob
    $AzCopyExitCode = [byte] 0
    Try {
        Write-Output -InputObject ('#### Start AzCopy Output ####')
        Write-Verbose -Message ('& cmd /c {0}' -f ($Arguments -join ' '))
        & 'cmd' '/c' ($Arguments -join ' ')
        $AzCopyExitCode = $LASTEXITCODE
    }
    Catch {
        $AzCopyExitCode    = 1
        $BoolScriptSuccess = $false
    }
    Finally {
        Write-Output -InputObject ('#### End AzCopy Output ####')
    }
    Write-Output -InputObject ('AzCopy Exit Code: {0}.' -f ($AzCopyExitCode))


    # If Fail - Write Output and set $BoolScriptSuccess to keep log
    if ($AzCopyExitCode -ne 0) {
        Write-Output -InputObject ('ERROR   - Last Exit Code Does Not Smell Like Success: {0}.' -f ($AzCopyExitCode.ToString()))
        $BoolScriptSuccess = $false
    }
    elseif ($([array](Get-ChildItem -Path $PathDirSync -File -Force -Recurse)).'Count' -le 0) {
        Write-Output -InputObject ('ERROR   - No files found in directory "{0}" after AzCopy finished.' -f ($PathDirSync))
        $BoolScriptSuccess = $false
    }
    else {
        Write-Output -InputObject ('SUCCESS - Healthy Exit Code and 1 or more files files found in sync path.')
    }
}




#################################
}
#################################
#endregion Try



# Catch
Catch {
    $BoolScriptSuccess = $false
}



# Finally
Finally {
    # Stop Transcript
    $null = Stop-Transcript
    # Don't keep the log file if success
    if ($BoolScriptSuccess) {
        Remove-Item -Path $PathFileLog -Force
    }
}

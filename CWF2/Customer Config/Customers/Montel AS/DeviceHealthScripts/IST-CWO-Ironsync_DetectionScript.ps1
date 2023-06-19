<#Requires -RunAsAdministrator#>

<#
    .SYNAPSIS
        This script will sync down a Azure Storage Account Files to specified folders

    .DESCRIPTION
        This script will sync down a Azure Storage Account File to specified folders
        The fileshare need to be named "ironsync" and contain a "ironsync.csv" that contains the source/destination mappings
        The format of the "ironsync.csv" is as follows, adding a /* after the source folder tells the script to only copy the files inside the folder.
        Source,Destination
        PowerPoint templates,env:APPDATA\Microsoft\Templates
        Word templates,env:APPDATA\Microsoft\Templates
        Teams backgrounds/*,env:APPDATA\Microsoft\Teams\Backgrounds\Uploads

    .NOTES
        Author:   Peter Korsmo @ Ironstone IT
        Modified: 200520
#>


#region    Initialize - Settings and Variables
#region    Inserted Static Variables
# IronSync
$NameScript = [string]$('IronSync.ps1')
# Azure Storage Account Connection Info
$StorageAccountName = [string]$('montelfiles')
$StorageAccountSASToken = [string]$('?sv=2021-06-08&ss=f&srt=sco&sp=rl&se=2032-06-10T21:08:24Z&st=2022-10-06T13:08:24Z&spr=https&sig=Wp6Wtg2rNJCCfwU89zYm97HPqQR%2BYwH8aDRxxdt9Gxg%3D')
#endregion Inserted Static Variables

#region    Dynamic Variables 1
# IronSync
$ScriptNameNoun = [string]$($NameScript.Split('-')[-1].Replace('.ps1', ''))
#endregion Dynamic Variables 1

#region    Inserted Dynamic Variables
# IronSync
$PathDirIronSync = [string]$('{0}\IronstoneIT\{1}' -f ($env:ProgramW6432, $ScriptNameNoun))
$PathDirLog = [string]$('{0}\Logs' -f ($PathDirIronSync))
# AzCopy
$PathFileAzCopy = [string]$('{0}\IronstoneIT\Binaries\AzCopy\azcopy.exe' -f ($env:ProgramData))
#endregion Inserted Dynamic Variables
    
    
#region    Dynamic Variables 2
# IronSync - Log
$NameFileLog = [string]$('{0}-runlog-{1}.log' -f ($ScriptNameNoun, [datetime]::Now.ToString('yyMMdd-HHmmss')))
$PathFileLog = [string]$('{0}\{1}' -f ($PathDirLog, $NameFileLog))
# Azure Storage Account Connection Info
$StorageAccountFileURL = [string]$('https://{0}.file.core.windows.net/ironsync' -f ($StorageAccountName))
#endregion Dynamic Variables 2


#region    Help Variables
$BoolScriptSuccess = [bool]$($true)
#endregion Help Variables
  
     
#region    Settings - PowerShell
$DebugPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'Continue'
$WarningPreference = 'Continue'
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
    ## Check what AzCopy version is available - if no version is available or it is outdated download newest version
    Write-Output -InputObject ('# Check if/what AzCopy version is available - download newest version if nescessary')
    
    #azcopy will return the version as a string if it's the newst version, if not we will get an array of strings
    if (-not(Test-Path $PathFileAzCopy) -or ((C:\ProgramData\IronstoneIT\Binaries\AzCopy\azcopy.exe --version).Gettype().Name -ne "String")) {
        $DLPath = "$env:windir\Temp\"
        $zip = $DLPath + "azcopy.zip"
        #clean up earlier versions in temp directory
        Get-Item -Path $DLPath* | Where-Object -Property Name -Like azcopy* | Remove-Item -Recurse -Force
        #download newest version from microsoft and extract and copy to IronstonIT binaries
        Invoke-WebRequest -Uri "https://aka.ms/downloadazcopy-v10-windows" -OutFile $zip
        Expand-Archive -Path $zip -DestinationPath $DLPath -Force

        #get directory since it changes with the version that's downloaded and copy binary to Ironstone folder
        $azdir = Get-Item -Path $DLPath* | Where-Object -Property Name -Like azcopy_*
        if(-not(Test-Path -Path "C:\ProgramData\IronstoneIT\Binaries\AzCopy\")){
            New-Item -Path "C:\ProgramData\IronstoneIT\Binaries\AzCopy\" -ItemType Directory
        }
        Copy-Item -Path "$azdir\azcopy.exe" -Destination "C:\ProgramData\IronstoneIT\Binaries\AzCopy\"
    }

    ## Check if running already
    Write-Output -InputObject ('# Check if running already')
    if (
        [array](
            Get-Process -Name 'AzCopy' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Path' | ForEach-Object -Process {
                $_.Replace(('\{0}' -f ($_.Split('\')[-1]), ''))
            } | Sort-Object -Unique
        ) -contains [string]$(if ($PathFileAzCopy[-1] -eq '\') { $PathFileAzCopy.Substring(0, $PathFileAzCopy.'Length' - 1) }else { $PathFileAzCopy })
    ) {
        Write-Output -InputObject ('{0}ERROR   - AzCopy is already running.' -f ("`t", $Path))
        $BoolScriptSuccess = $false
    }
    if (-not($BoolScriptSuccess)) {
        Break
    }
        

    ## Check Internet Connectivity
    Write-Output -InputObject ('# Check Internet Connectivity')
    if ([bool]$($null = Resolve-DnsName -Name 'blob.core.windows.net' -ErrorAction 'SilentlyContinue'; $?)) {
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





    # Build argument    
    $Arguments = [string[]]$(          
            ('"{0}"' -f ($PathFileAzCopy)), # AzCopy.exe v10.x.x path
            ('copy'), # copy flag
            ('"{0}{1}{2}"' -f ($StorageAccountFileURL, "/ironsync.csv", $StorageAccountSASToken)) # Source URL with SAS token 
            ('"{0}{1}"' -f ($PathDirIronSync), "\ironsync.csv") #destination file
            ("--overwrite ifSourceNewer") #since copying the file to an empty destination may fail with sync, use copy with overwrite only if source is newer
    )

    # Get folders in ironsync fileshare
    $AzCopyExitCode = [byte] 0
    Try {
        Write-Output -InputObject ('#### Get ironsync.csv to know wich folders to sync ####')
        Write-Verbose -Message ('& cmd /c {0}' -f ($Arguments -join ' '))
        & 'cmd' '/c' ($Arguments -join ' ')
        $AzCopyExitCode = $LASTEXITCODE
    }
    Catch {
        $AzCopyExitCode = 1
        $BoolScriptSuccess = $false
    }
    Finally {
        Write-Output -InputObject ('#### End AzCopy Output ####')
    }
    Write-Output -InputObject ('AzCopy Exit Code: {0}.' -f ($AzCopyExitCode))




    # If Fail - Write Output and set $BoolScriptSuccess to keep log, exit script if it failed
    if ($AzCopyExitCode -ne 0) {
        Write-Output -InputObject ('ERROR   - Unable to get list of directories from AZ file share: {0}.' -f ($AzCopyExitCode.ToString()))
        $BoolScriptSuccess = $false
        $null = Stop-Transcript
        Break
    }
    else {
        Write-Output -InputObject ('SUCCESS - Healthy Exit Code and 1 or more files files found in sync path.')
    }

    #if it is created paths in the azure fileshare
    if (Test-Path -Path ("{0}{1}" -f ($PathDirIronSync), "\ironsync.csv")) {
        #Load the Ironsync csv with source and destination paths
        $SyncPaths = Import-Csv -Path ("{0}{1}" -f ($PathDirIronSync), "\ironsync.csv")
        foreach ($path in $SyncPaths) {
            Write-Output $path
            if ($path.Destination -like "env*") {
                Write-Output "Destination is a environment variable"
                #convert env variable to actual path
                $path.Destination = (Get-Item (($path.Destination -split "\\", 2)[0])).Value + '\' + ($path.Destination -split "\\", 2)[1]

                $Arguments = [string[]]$(          
                    ('"{0}"' -f ($PathFileAzCopy)), # AzCopy.exe v10.x.x path
                    ('copy'), # copy flag
                    ('"{0}{1}{2}{3}"' -f ($StorageAccountFileURL, "/", $path.Source, $StorageAccountSASToken)) # Source URL with SAS token 
                    ('"{0}"' -f ($path.Destination)) #destination path
                    ("--overwrite ifSourceNewer") #since copying the file to an empty destination may fail with sync, use copy with overwrite only if source is newer
                    ("--recursive")
                )

                & 'cmd' '/c' ($Arguments -join ' ')
            }
            else {
                Write-Output "Destination is a regular path"

                $Arguments = [string[]]$(          
                    ('"{0}"' -f ($PathFileAzCopy)), # AzCopy.exe v10.x.x path
                    ('copy'), # copy flag
                    ('"{0}{1}{2}{3}"' -f ($StorageAccountFileURL, "/", $path.Source, $StorageAccountSASToken)) # Source URL with SAS token 
                    ('"{0}"' -f ($path.Destination)) #destination path
                    ("--overwrite ifSourceNewer") #since copying the file to an empty destination may fail with sync, use copy with overwrite only if source is newer
                    ("--recursive")
                )

                & 'cmd' '/c' ($Arguments -join ' ')
            }
        }
    }
    else {
        Write-Output "ironsync.csv does not exist"
        $BoolScriptSuccess = $false
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
        Exit 0
    }
    Exit 1
}
    

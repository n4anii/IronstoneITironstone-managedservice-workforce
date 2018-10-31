<#

.SYNOPSIS


.DESCRIPTION


.NOTES
You need to run this script in the DEVICE context in Intune.

#>


# Script Variables
[bool]   $DeviceContext = $true
[string] $NameScript    = 'Install-IronSync(OfficeTemplates_Metier)'

# Settings - PowerShell - Output Preferences
$DebugPreference       = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$VerbosePreference     = 'SilentlyContinue'
$WarningPreference     = 'Continue'


#region    Don't Touch This
# Settings - PowerShell - Interaction
$ConfirmPreference     = 'None'
$ProgressPreference    = 'SilentlyContinue'

# Settings - PowerShell - Behaviour
$ErrorActionPreference = 'Continue'

# Dynamic Variables - Process & Environment
[string] $NameScriptFull      = ('{0}_{1}' -f ($(if($DeviceContext){'Device'}else{'User'}),$NameScript))
[string] $NameScriptVerb      = $NameScript.Split('-')[0]
[string] $NameScriptNoun      = $NameScript.Split('-')[-1]
[string] $ProcessArchitecture = $(if([System.Environment]::Is64BitProcess){'64'}else{'32'})
[string] $OSArchitecture      = $(if([System.Environment]::Is64BitOperatingSystem){'64'}else{'32'})

# Dynamic Variables - User
[bool] $BoolIsAdmin        = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
[string] $StrIsAdmin       = $BoolIsAdmin.ToString()
[string] $StrUserName      = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
[string] $SidCurrentUser   = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
[string] $SidSystemUser    = 'S-1-5-18'
[bool] $CurrentUserCorrect = $(
    if($DeviceContext -and $SIDCurrentUser -eq $SIDSystemUser){$true}
    elseif (-not($DeviceContext) -and $SIDCurrentUser -ne $SIDSystemUser){$true}
    else {$false}
)

# Dynamic Logging Variables
$Timestamp    = [DateTime]::Now.ToString('yyMMdd-HHmmssffff')
$PathDirLog   = ('{0}\IronstoneIT\Intune\DeviceConfiguration\' -f ($(if($DeviceContext -and $CurrentUserCorrect){$env:ProgramW6432}else{$env:APPDATA})))
$PathFileLog  = ('{0}{1}-{2}bit-{3}.txt' -f ($PathDirLog,$NameScriptFull,$ProcessArchitecture,$Timestamp))

# Start Transcript
if (-not(Test-Path -Path $PathDirLog)) {New-Item -ItemType 'Directory' -Path $PathDirLog -ErrorAction 'Stop'}
Start-Transcript -Path $PathFileLog

# Output User Info, Exit if not $CurrentUserCorrect
Write-Output -InputObject ('Running as user "{0}". Has admin privileges? {1}. $DeviceContext = {2}. Running as correct user? {3}.' -f ($StrUserName,$StrIsAdmin,$DeviceContext.ToString(),$CurrentUserCorrect.ToString()))
if (-not($CurrentUserCorrect)){Throw 'Not running as correct user!'} 

# Output Process and OS Architecture Info
Write-Output -InputObject ('PowerShell is running as a {0} bit process on a {1} bit OS.' -f ($ProcessArchitecture,$OSArchitecture))


# Wrap in Try/Catch, so we can always end the transcript
Try {    
    # If OS is 64 bit, and PowerShell got launched as x86, relaunch as x64
    if ([System.Environment]::Is64BitOperatingSystem -and -not [System.Environment]::Is64BitProcess) {
        write-Output -InputObject (' * Will restart this PowerShell session as x64.')
        if ($myInvocation.Line) {& ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile $myInvocation.Line}
        else {& ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile -File ('{0}' -f ($myInvocation.InvocationName)) $args}
        exit $LASTEXITCODE
    } 
 
    # End the Initialize Region
    Write-Output -InputObject ('**********************')
#endregion Don't Touch This
################################################
#region    Your Code Here
################################################


        #region    Initialize - Settings and Variables
            #region    Variables - Generic
                # Variables - Script
                [bool] $ReadOnly               = $false
                [bool] $BoolScriptSuccess      = $true
                # Variables - Paths - IronSync
                if ([string]::IsNullOrEmpty($NameScriptNoun)){$BoolScriptSuccess = $false; Throw 'ERROR: $NameScriptNoun is Empty!'; Break}
                [string] $PathDirIronSync      = ('{0}\IronstoneIT\{1}' -f ($env:ProgramW6432,$NameScriptNoun))
                [string] $PathDirIronSyncLog   = ('{0}\Logs' -f ($PathDirIronSync))
                [string] $PathDirAzCopyJournal = ('{0}\AzCopyJournal' -f ($PathDirIronSync))  
                # Settings - PowerShell
                $VerbosePreference     = 'Continue'
            #endregion Variables - Generic      
                       


            #region    Variables - Case Specific              
                # Sync Folder
                [string] $PathDirSync     = ('{0}\Users\Public\OfficeTemplates' -f ($env:SystemDrive))               
                #region     Install Files
                [string] $NameFilePS1     = ('Run-{0}.ps1' -f ($NameScriptNoun))
                [string] $EncodingFilePS1 = ('utf8')
                [System.Management.Automation.ScriptBlock] $ContentFilePS1  = {#Requires -RunAsAdministrator

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
    #region    Static Variables - EDIT THESE ONLY
        [string] $NameScript   = 'Run-IronSync(OfficeTemplates_Metier)'
        # Variables - Environment
        [string] $PathDirSync  = ('{0}\Users\Public\OfficeTemplates' -f ($env:SystemDrive))
        # Variabled - Connection Info
        [string] $StorageAccountName     = 'metierclientstorage'
        [string] $StorageAccountSASToken = '?sv=2017-07-29&ss=b&srt=co&sp=rl&se=2019-01-01T21:05:29Z&st=2018-04-11T12:05:29Z&spr=https&sig=K77IKMwiMS7I15DL%2FwtbbPEDDIGARtiWcdJo3U1YGF4%3D'                     
    #endregion Static Variables - EDIT THESE ONLY
    
    

    #region    Dynamic Variables
        # Variables - Script
        [string] $NameScriptNoun  = $NameScript.Split('-')[-1]
        [string] $NameFileScript  = ('Run-{0}' -f ($NameScriptNoun))
        [bool] $BoolScriptSuccess = $true
        # Variables - Log
        [string] $PathDirLog      = ('{0}\IronstoneIT\{1}\Logs' -f ($env:ProgramW6432,$NameScriptNoun))
        [string] $NameFileLog     = ('{0}-runlog-{1}.log' -f ($NameScriptNoun,[datetime]::Now.ToString('yyMMdd-hhmmss')))
        [string] $PathFileLog     = ('{0}\{1}' -f ($PathDirLog,$NameFileLog))
    #endregion Dynamic Variables
  
    
    
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
        [string] $PathFileAzCopy       = ('{0}\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' -f (${env:ProgramFiles(x86)}))
        [string] $PathDirAzCopyJournal = ('{0}\IronstoneIT\{1}\AzCopyJournal' -f ($env:ProgramW6432,$NameScriptNoun))
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
        if (-not($BoolScriptSuccess)) {Break}
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
                }
                #endregion Install Files                
            #endregion Variables - Case Specific



            #region    Varbiable - Office Templates Edition
                # Registry Values
                [PSCustomObject[]] $RegValues = @(
                    [PSCustomObject[]]@{Path=[string]'HKCU:\Software\Microsoft\Office\16.0\Excel\Options';     Name=[string]'PersonalTemplates';Value=$PathDirSync;Type=[string]'ExpandString'},
                    [PSCustomObject[]]@{Path=[string]'HKCU:\Software\Microsoft\Office\16.0\Word\Options';      Name=[string]'PersonalTemplates';Value=$PathDirSync;Type=[string]'ExpandString'},
                    [PSCustomObject[]]@{Path=[string]'HKCU:\Software\Microsoft\Office\16.0\PowerPoint\Options';Name=[string]'PersonalTemplates';Value=$PathDirSync;Type=[string]'ExpandString'}
                )
            #endregion Variables - Office Templates Edition
            


            #region    Variables - Dynamically Created
                # Paths to create if does not exist
                [string[]] $PathsToCreate = @($PathDirIronSync,$PathDirIronSyncLog,$PathDirAzCopyJournal,$PathDirSync)
                # Paths to remove if exist
                [string[]] $PathsToRemove = @(
                    # Office Templates Path 
                    @(Get-ChildItem -Path ('{0}\Users\Public' -f ($env:SystemDrive)) -Directory -Force -Filter '*OfficeTemplates*' | Select-Object -ExpandProperty 'FullName' | Where-Object {$_ -notlike $PathDirIronSync}) +
                    # IronSync Path(s)
                    @($PathDirIronSync) +
                    @(Get-ChildItem -Path ('{0}\IronstoneIT' -f ($env:ProgramW6432)) -Directory -Force -Filter '*IronSync*OfficeTemplates*' | Select-Object -ExpandProperty 'FullName' | Where-Object {$_ -notlike $PathDirIronSync}) +                                         
                    ('{0}\IronstoneIT\IronSync' -f ($env:ProgramW6432))
                )
            #endregion Variables - Dynamically Created
        #endregion Initialize - Settings and Variables




        #region    Functions
            #region    Write-ReadOnly
            function Write-ReadOnly {Write-Verbose -Message ('ReadOnly = {0}, will not write any changes.' -f ($ReadOnly))}
            #endregion Write-ReadOnly
        #endregion Functions




        #region    Cleanup Previous Install
            # Install folder
            if (Test-Path -Path $PathDirIronSync) {Remove-Item -Path $PathDirIronSync -Recurse -Force}
            # Previous versions leftovers
            foreach ($Path in $PathsToRemove) {if (Test-Path -Path $Path) {Remove-Item -Path $Path -Recurse -Force}}
            # Scheduled Task
            $null = Get-ScheduledTask | Where-Object {$_.Author -like 'Ironstone*' -and ($_.TaskName -like 'IronSync*' -or $_.TaskName -like ('*{0}' -f ($NameScriptNoun)))} | Unregister-ScheduledTask -Confirm:$false
        #endregion Cleanup Previous Install




        #region    Create Template folder & IronSync Folder - For Schedule and log files      
            foreach ($Dir in $PathsToCreate) {
                if (Test-Path -Path $Dir) {
                    Write-Verbose -Message ('Path "{0}" already exist.' -f ($Dir))
                }
                else {
                    Write-Verbose -Message ('Path "{0}" does not already exist.' -f ($Dir))
                    if ($ReadOnly) {Write-ReadOnly}
                    else {
                        $null = New-Item -Path $Dir -ItemType 'Directory' -Force
                        Write-Verbose -Message ('Creating.. Success? {0}' -f ($?))
                    }
                }
            }
        #endregion Create Template folder & IronSync Folder - For Schedule and log files




        #region    Set hidden folder
            Write-Verbose -Message ('Setting folder "{0}" to be ReadOnly and Hidden' -f ($PathDirSync))
            if ($ReadOnly) {Write-ReadOnly}
            else {
                (Get-Item $PathDirSync -Force).Attributes = 'Hidden, ReadOnly, Directory'
                Write-Verbose -Message ('Success? {0}' -f ($?))
            }
        #endregion Set hidden folder




        #region    Set template folder for O365 application
            # Get HKU:\ location for current user in order to write to HKCU from System Context
            [string] $Script:PathDirRootCU = ('Registry::HKEY_USERS\{0}' -f ([System.Security.Principal.NTAccount]::new(@(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value))
            
            #region    Set Registry Values from SYSTEM / DEVICE context
                foreach ($Item in $RegValues) {
                    # Create $Path variable, switch HKCU: with HKU:
                    [string] $Path = $Item.Path
                    if ($Path -like 'HKCU:\*') {$Path = $Path.Replace('HKCU:\',('{0}{1}' -f ($Script:PathDirRootCU,$(if(([string]$Script:PathDirRootCU[-1]) -ne '\'){'\'}))))}
                    $Path = $Path.Replace('\\','\')
                    Write-Verbose -Message ('Path: "{0}".' -f ($Path))

                    # Check if $Path is valid
                    [bool] $SuccessValidPath = $true
                    if ($Path -like 'HKCU:\*') {$SuccessValidPath = $false}
                    elseif ($Path -like 'HKLM:\*' -or $Path -like 'HKU:\') {
                        $SuccessValidPath = -not ($Path -notlike 'HK*:\*' -or $Path -like '*:*:*' -or $Path -like '*\\*' -or $Path.Split(':')[0].Length -gt 4)       
                    }
                    elseif ($Path -like 'Registry::HKEY_USERS\*') {
                        $SuccessValidPath = [bool]($Path -notlike '*\\*')
                    }
                    else {$SuccessValidPath = $false}
                    if (-not($SuccessValidPath)){Throw 'Not a valid path! Will not continue.'}


                    # Check if $Path exist, create it if not
                    if (-not(Test-Path -Path $Path)){
                        $null = New-Item -Path $Path -ItemType 'Directory' -Force
                        Write-Verbose -Message ('   Path did not exist. Successfully created it? {0}.' -f (([bool] $Local:SuccessCreatePath = $?).ToString()))
                        if (-not($Local:SuccessCreatePath)){Continue}
                    }
        
                    # Set Value / ItemPropery
                    Set-ItemProperty -Path $Path -Name $Item.Name -Value $Item.Value -Type $Item.Type -Force
                    Write-Verbose -Message ('   Name: {0} | Value: {1} | Type: {2} | Success? {3}' -f ($Item.Name,$Item.Value,$Item.Type,$?.ToString()))
                }
            #endregion Set Registry Values from SYSTEM / DEVICE context
        #endregion Set template folder for O365 application




        #region    Install IronSync
            [string] $PathFilePS1 = ('{0}\{1}' -f ($PathDirIronSync,$NameFilePS1))
            Write-Verbose -Message ('Installing IronSync file to "{0}"' -f ($PathFilePS1))
            if ($ReadOnly) {Write-ReadOnly}
            else {                     
                $null = Out-File -FilePath $PathFilePS1 -InputObject $ContentFilePS1.ToString() -Encoding $EncodingFilePS1
                Write-Verbose -Message ('Success? {0}.' -f ($?.ToString()))
            }

        #endregion Install IronSync



        #region    Create Scheduled Task
            [string] $PathFilePowerShell       = '%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe' # Works regardless of 64bit vs 32bit
            [string] $PathFilePS1              = ('{0}\{1}' -f ($PathDirIronSync,$NameFilePS1))
            [string] $NameScheduledTask        = ('Run-{0}' -f ($NameScriptNoun))
            [string] $DescriptionScheduledTask = 'Runs IronSync, which syncs down files from Azure Blob Storage using AzCopy.'
                    
            #region    Create Scheduled Task running PS1 using PowerShell.exe - Every Day at 13
                # Construct Scheduled Task
                $ScheduledTask = New-ScheduledTask                                                    `
                    -Action    (New-ScheduledTaskAction -Execute ('"{0}"' -f ($PathFilePowerShell)) -Argument ('-ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -File "{0}"' -f ($PathFilePS1))) `
                    -Principal (New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -RunLevel 'Highest')                                                                                                                           `
                    -Trigger   (New-ScheduledTaskTrigger -Daily -At ([DateTime]::Today.AddHours(13)))                                                                                                                           `
                    -Settings  (New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::FromMinutes(10)) -Compatibility 4 -StartWhenAvailable)
                $ScheduledTask.Author      = 'Ironstone'
                $ScheduledTask.Description = ('{0}Runs a PowerShell script. {1}Execute: "{2}". {1}Arguments: "{3}".' -f (
                    $(if([string]::IsNullOrEmpty($DescriptionScheduledTask)){''}else{('{0} {1}' -f ($DescriptionScheduledTask,"`r`n"))}),"`r`n",
                    [string]($ScheduledTask | Select-Object -ExpandProperty Actions | Select-Object -ExpandProperty Execute),
                    [string]($ScheduledTask | Select-Object -ExpandProperty Actions | Select-Object -ExpandProperty Arguments)
                ))
                
                # Register Scheduled Task
                $null = Register-ScheduledTask -TaskName $NameScheduledTask -InputObject $ScheduledTask -Force -Verbose:$false -Debug:$false
                
                # Check if success registering Scheduled Task
                [bool] $SuccessCreatingScheduledTask = $?
                Write-Verbose -Message ('Success creating scheduled task "{0}"? "{1}".' -f ($NameScheduledTask,$SuccessCreatingScheduledTask.ToString()))
                
                # Run Scheduled Task if Success Creating It
                if ($SuccessCreatingScheduledTask) {$null = Start-ScheduledTask -TaskName $NameScheduledTask}
            #endregion Create Scheduled Task running PS1 using PowerShell.exe - Every Day at 13
        #endregion Create Scheduled Task


################################################
#endregion Your Code Here
################################################   
#region    Don't touch this
}
Catch {
    # Construct Message
    [string] $ErrorMessage = ('{0} finished with errors:' -f ($NameScriptFull))
    $ErrorMessage += ('{0}{0}Exception:{0}' -f ("`r`n"))
    $ErrorMessage += $_.Exception
    $ErrorMessage += ('{0}{0}Activity:{0}' -f ("`r`n"))
    $ErrorMessage += $_.CategoryInfo.Activity
    $ErrorMessage += ('{0}{0}Error Category:{0}' -f ("`r`n"))
    $ErrorMessage += $_.CategoryInfo.Category
    $ErrorMessage += ('{0}{0}Error Reason:{0}' -f ("`r`n"))
    $ErrorMessage += $_.CategoryInfo.Reason
    # Write Error Message
    Write-Error -Message $ErrorMessage
}
Finally {
    Stop-Transcript
}
#endregion Don't touch this
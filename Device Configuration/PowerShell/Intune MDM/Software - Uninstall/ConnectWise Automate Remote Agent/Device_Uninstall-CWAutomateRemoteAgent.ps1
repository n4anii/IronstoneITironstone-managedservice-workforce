<#
Device_Uninstall-CWAutomateRemoteAgent.ps1

.SYNOPSIS
This script will completely remove everything from
ConnectWise Automate / LabTech.


.DESCRIPTION
This script will completely remove everything from
ConnectWise Automate / LabTech.


.NOTES
You need to run this script in the DEVICE context in Intune.

#>


# Script Variables
[bool]   $DeviceContext = $true
[string] $NameScript    = 'Uninstall-CWAutomateRemoteAgent'


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
    


#region Functions
    #region Download-FileToDir
    Function Download-FileToDir {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string] $NameFileOut, 
            
            [Parameter(Mandatory=$true)]
            [string] $DLURL,
            
            [Parameter(Mandatory=$false)]
            [ValidateScript({Test-Path -Path $_})]
            [string] $PathDirOut = ('{0}\Temp' -f ($env:windir)),
            
            [Parameter(Mandatory=$false)]
            [byte]   $TryXTimes  = 2,

            [Parameter(Mandatory=$false)]
            [byte]   $DLMethod   = 1,

            [Parameter(Mandatory=$false)]
            [byte]   $Increment  = 6,

            [Parameter(Mandatory=$false)]
            [ValidateSet('MACTripleDES','MD5','RIPEMD160','SHA1','SHA256','SHA384','SHA315')]
            [string] $CheckSumAlgorithm, 
            
            [Parameter(Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [string] $CheckSum            
        )

        # Variables - From Input
        [string] $Local:PathDirOut  = $PathDirOut
        [string] $Local:PathFileOut = ('{0}{1}{2}' -f ($Local:PathDirOut,$(if($Local:PathDirOut[-1] -ne '\'){'\'}),$NameFileOut))        
        [bool]   $Local:DoHash      = -not(([string]::IsNullOrEmpty($CheckSum)) -or ([string]::IsNullOrEmpty($CheckSumAlgorithm)))
        [string] $Local:Indent      = (' ' * $Increment)
        # Variables - Runtime
        [byte]   $Local:Attempts    = 1
        [bool]   $Local:Success     = $false
        

        # Delete file if it exists
        Remove-Item -Path $Local:PathFileOut -Force -ErrorAction SilentlyContinue

        # Download
        While (($Local:Attempts -le $TryXTimes) -and (-not($Local:Success))) {
            Write-Verbose -Message ('{0}# ATTEMPT {1}/{2}' -f ($Local:Indent,$Local:Attempts,$TryXTimes))
            
            [bool] $Local:SuccessDL = $false
            [byte] $Local:DLStartAtMethod = $DLMethod


            # DL Method 1: Start-BitsTransfer
            if ($Local:DLStartAtMethod -eq 1) {
                # BitsTransfer does not support FTP
                if ($DLURL -like '*ftp*/*') {
                    Write-Verbose -Message ('{0}BitsTransfer does not support FTP.' -f ($Local:Indent))
                    $Local:DLStartAtMethod += 1
                }
                else {
                    Write-Verbose -Message ('{0}Downloading (Start-BitsTransfer)' -f ($Local:Indent))
                    $Local:StartTime = [DateTime]::Now
                    $null = Start-BitsTransfer -Source $DLURL -Destination $Local:PathFileOut -ErrorAction 'SilentlyContinue'
                    if ($?) {
                        $Local:SuccessDL =  $true
                    }
                    else {
                        $Local:DLStartAtMethod += 1
                        Write-Verbose -Message ('{0}   Failed!' -f ($Local:Indent))                  
                    }
                }
            }


            # DL Method 2: System.Net.WebClient
            if ($Local:DLStartAtMethod -eq 2) {
                Write-Verbose -Message ('{0}Downloading (System.Net.WebClient)' -f ($Local:Indent))
                $Local:StartTime = [DateTime]::Now
                [System.Net.WebClient]::new().DownloadFile($DLURL,$Local:PathFileOut)
                if ($?) {
                    $Local:SuccessDL = $true
                }                                     
                else {
                    $Local:DLStartAtMethod += 1
                    Write-Verbose -Message ('{0}   Failed!' -f ($Local:Indent))
                }
            }
              
                
            # DL Method 3: Invoke-WebRequest
            if ($Local:DLStartAtMethod -eq 3) {    
                Write-Verbose -Message ('{0}Downloading (Invoke-WebRequest)' -f ($Local:Indent))
                $Local:StartTime = [DateTime]::Now
                Invoke-WebRequest -Uri $DLURL -OutFile $Local:PathFileOut
                if ($?) {
                    $Local:SuccessDL = $true
                }
                else {
                    Write-Verbose -Message ('{0}   Failed!' -f ($Local:Indent))
                }
            }

            
            if ($Local:SuccessDL) {
                Write-Verbose -Message ('{0}   Download successful. It took {1} second(s).' -f ((' ' * $Increment),([math]::Round(((Get-Date).Subtract($Local:StartTime).TotalSeconds),2))))
                if ($Local:DoHash) {
                    [string] $Local:FileOutHash = (Get-FileHash -Path $Local:PathFileOut -Algorithm $CheckSumAlgorithm).Hash
                    Write-Verbose -Message ('{0}HASHING {1} ("{2}" -eq "{3}")' -f ($Local:Indent,$CheckSumAlgorithm,$Local:FileOutHash,$CheckSum.ToUpper()))
                    if ($Local:FileOutHash -eq $CheckSum) {
                        Write-Verbose -Message ('{0}   SUCCESS: Hash matches.' -f ($Local:Indent))
                        $Local:Success = $true
                    }
                    else {
                        Write-Verbose -Message ('{0}   FAIL: Hash does NOT match.' -f ($Local:Indent))
                    }
                }
                else {
                    $Local:Success = $true
                }
            }            
            elseif (-not($Local:SuccessDL)) {
                Write-Verbose -Message ('{0}   FAIL: Download failed.' -f ($Local:Indent))
            }
            else {
                Write-Verbose -Message ('{0}   FAIL: Something failed.' -f ($Local:Indent))
            }


            # If fail, increment attempts
            if (-not($Local:Success)) {$Local:Attempts += 1}
        }

        Return ($Local:Success)  
    }
    #endregion Download-FileToDir
#endregion Functions




#region    CW Automate Uninstaller
    #region    Assets
        $VerbosePreference = 'Continue'
        
        # ConnectWise Automate Remote Agent
        [string] $NameProgramCWAutomate                = 'ConnectWise Automate Remote Agent'
        [string] $PathDirCWAutomatePF                  = ('{0}\LabTech Client' -f (${env:ProgramFiles(x86)}))
        [string] $PathDirCWAutomateWindir              = ('{0}\LTSvc' -f ($env:windir))
        [string] $PathDirRegCWAutomate                 = 'HKLM:\SOFTWARE\LabTech'
        [string] $PathDirRegCWAutomateUninstaller      = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{58A3001D-B675-4D67-A5A1-0FA9F08CF7CA}'

        # ConnectWise ScreenConnect Client
        [string] $NameProgramCWScreenConnect           = 'ConnectWise ScreenConnect Client'
        [string] $PathDirCWScreenConnectPF             = Get-ChildItem -Path ('{0}' -f (${env:ProgramFiles(x86)})) | Where-Object -Property 'Name' -Like 'ScreenConnect Client*' | Select-Object -First 1 -ExpandProperty 'FullName'
        [string] $PathDirRegCWScreenConnectUninstaller = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{E1F919FE-2E3F-48A3-B458-4FB820A61436}'
    #endregion Assets
    
    
    #region    Remove ConnectWise Automate Remote Agent
        if ([bool[]]@(foreach($Path in ($PathDirRegCWAutomateUninstaller,$PathDirRegCWAutomate,$PathDirCWAutomatePF,$PathDirCWAutomateWindir)){[bool](Test-Path -Path $Path)}).Contains($true)){
            Write-Verbose -Message ('{0} is installed. Uninstalling.' -f ($NameProgramCWAutomate))

            # Run CW Automate Remote Agent Universal Uninstaller
            [string] $URLCWAutomateUn = 'https://ironstoneit.hostedrmm.com/Labtech/Deployment.aspx?ID=-2'
            [string] $PathDirDownloadCWAutomateUn = ('{0}\Windows\Temp\' -f ($env:SystemDrive))
            [string] $NameFileExeCWAutomateUn = 'Agent_Uninstaller.exe'
            [string] $PathFileExeCWAutomateUn = ('{0}{1}' -f ($PathDirDownloadCWAutomateUn,$NameFileExeCWAutomateUn))
            Download-FileToDir -NameFileOut 'Agent_Uninstaller.exe' -DLURL $URLCWAutomateUn -PathDirOut $PathDirDownloadCWAutomateUn
            Start-Process -FilePath $PathFileExeCWAutomateUn -Wait
            Remove-Item -Path $PathFileExeCWAutomateUn -Force -ErrorAction 'SilentlyContinue'


            # Clean up registry
            if (Test-Path -Path $PathDirRegCWAutomate) {
                Write-Verbose -Message ('Removing leftovers in registry ({0})' -f ($PathDirRegCWAutomate))
                Remove-ItemProperty -Path $PathDirRegCWAutomate -Name '*' -Force
                Remove-Item -Path $PathDirRegCWAutomate -Recurse -Force
            }


            # Clean up paths
            foreach ($Path in @($PathDirCWAutomatePF,$PathDirCWAutomateWindir)){
                if (Test-Path -Path $Path){<#Remove-Item -Path $Path -Recurse -Force#>}
            }
        }
        else {
            Write-Verbose -Message ('{0} is not installed. Skipping.' -f ($NameProgramCWAutomate))
        }
    #endregion Remove ConnectWise Automate Remote Agent


    #region    Remove ConnectWise ScreenConnect Client
        if ([bool](Test-Path -Path $PathDirRegCWScreenConnectUninstaller) -or (-not([string]::IsNullOrEmpty($PathDirCWScreenConnectPF)))){          
            Write-Verbose -Message ('{0} is installed. Uninstalling.' -f ($NameProgramCWScreenConnect))
            
            # Run MSI Uninstaller
            if (Test-Path -Path $PathDirRegCWScreenConnectUninstaller) {
                [string[]] $UninstallString = @((Get-ItemProperty -Path $PathDirRegCWScreenConnectUninstaller | Select-Object -ExpandProperty 'UninstallString').Split(' '))
                if (-not([string]::IsNullOrEmpty($UninstallString))) {
                    Start-Process -FilePath $UninstallString[0] -ArgumentList ('{0} /qn' -f ($UninstallString[1])) -Wait
                }
            }
        }
        else {
            Write-Verbose -Message ('{0} is not installed. Skipping.' -f ($NameProgramCWScreenConnect))
        }
    #endregion Remove ConnectWise ScreenConnect Client
#endregion CW Automate Uninstaller



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
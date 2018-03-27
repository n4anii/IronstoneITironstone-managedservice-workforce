<#

.SYNOPSIS
This script will completely remove everything from
ConnectWise Automate / LabTech.


.DESCRIPTION
This script will completely remove everything from
ConnectWise Automate / LabTech.


.NOTES
You need to run this script in the DEVICE context in Intune.

#>


#Change the app name
$AppName   = 'Device_Uninstall-CWAutomate'
# Settings - Logging
$Timestamp = Get-Date -Format 'HHmmssffff'
$LogDirectory = ('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration' -f ($env:SystemDrive))
$Transcriptname = ('{2}\{0}_{1}.txt' -f ($AppName,$Timestamp,$LogDirectory))
# Settings - PowerShell
$ErrorActionPreference = 'Continue'
$VerbosePreference = 'Continue'
$WarningPreference = 'Continue'


if (-not(Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -ErrorAction Stop
}

Start-Transcript -Path $Transcriptname
#Wrap in a try/catch, so we can always end the transcript
Try {
    # Get the ID and security principal of the current user account
    $myWindowsID = [Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal = New-Object -TypeName System.Security.Principal.WindowsPrincipal -ArgumentList ($myWindowsID)
 
    # Get the security principal for the Administrator role
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
 
    # Check to see if we are currently running "as Administrator"
    if (-not($myWindowsPrincipal.IsInRole($adminRole))) {
        # We are not running "as Administrator" - so relaunch as administrator
   
        # Create a new process object that starts PowerShell
        $newProcess = New-Object -TypeName System.Diagnostics.ProcessStartInfo -ArgumentList 'PowerShell'
   
        # Specify the current script path and name as a parameter
        $newProcess.Arguments = $myInvocation.MyCommand.Definition
   
        # Indicate that the process should be elevated
        $newProcess.Verb = 'runas'
   
        # Start the new process
        [Diagnostics.Process]::Start($newProcess)
   
        # Exit from the current, unelevated, process
        Write-Output -InputObject 'Restart in elevated'
        exit
   
    }

    #64-bit invocation
    if ($env:PROCESSOR_ARCHITEW6432 -eq 'AMD64') {
        write-Output -InputObject "Y'arg Matey, we're off to the 64-bit land....."
        if ($myInvocation.Line) {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
        }
        else {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file ('{0}' -f $myInvocation.InvocationName) $args
        }
        exit $lastexitcode
    }
 
 

    #region    Code Goes Here
    ##############################
    


    #region Functions
        #region Download-FileToDir
        Function Download-FileToDir {
            param(
                [Parameter(Mandatory=$true)]
                [string] $NameFileOut, 
            
                [Parameter(Mandatory=$true)]
                [string] $DLURL,
            
                [ValidateScript({Test-Path -Path $_})]
                [string] $PathDirOut = ('{0}\Temp\' -f ($env:windir)),
            
                [byte]   $TryXTimes  = 2,
                [byte]   $DLMethod   = 1,
                [byte]   $Increment  = 6,

                [ValidateSet('MACTripleDES','MD5','RIPEMD160','SHA1','SHA256','SHA384','SHA315')]
                [string] $CheckSumAlgorithm, 
            
                [string] $CheckSum            
            )

            # Variables - From Input
            [string] $Local:PathDirOut  = $PathDirOut
            [string] $Local:PathFileOut = ('{0}{1}' -f ($Local:PathDirOut,$NameFileOut))        
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
                If ($Local:DLStartAtMethod -eq 1) {
                    # BitsTransfer does not support FTP
                    if ($DLURL -like '*ftp*/*') {
                        Write-Verbose -Message ('{0}BitsTransfer does not support FTP.' -f ($Local:Indent))
                        $Local:DLStartAtMethod += 1
                    }
                    else {
                        Write-Verbose -Message ('{0}Downloading (Start-BitsTransfer)' -f ($Local:Indent))
                        [System.DateTime] $Local:StartTime = Get-Date
                        $null = Start-BitsTransfer -Source $DLURL -Destination $Local:PathFileOut -ErrorAction SilentlyContinue
                        If ($?) {
                            $Local:SuccessDL =  $true
                        }
                        Else {
                            $Local:DLStartAtMethod += 1
                            Write-Verbose -Message ('{0}   Failed!' -f ($Local:Indent))                  
                        }
                    }
                }


                # DL Method 2: System.Net.WebClient
                If ($Local:DLStartAtMethod -eq 2) {
                    Write-Verbose -Message ('{0}Downloading (System.Net.WebClient)' -f ($Local:Indent))
                    [System.DateTime] $Local:StartTime = Get-Date
                    (New-Object System.Net.WebClient).DownloadFile($DLURL,$Local:PathFileOut)
                    If ($?) {
                        $Local:SuccessDL = $true
                    }                                     
                    Else {
                        $Local:DLStartAtMethod += 1
                        Write-Verbose -Message ('{0}   Failed!' -f ($Local:Indent))
                    }
                }
              
                
                # DL Method 3: Invoke-WebRequest
                If ($Local:DLStartAtMethod -eq 3) {    
                    Write-Verbose -Message ('{0}Downloading (Invoke-WebRequest)' -f ($Local:Indent))
                    [System.DateTime] $Local:StartTime = Get-Date
                    Invoke-WebRequest -Uri $DLURL -OutFile $Local:PathFileOut
                    If ($?) {
                        $Local:SuccessDL = $true
                    }
                    Else {
                        Write-Verbose -Message ('{0}   Failed!' -f ($Local:Indent))
                    }
                }

            
                If ($Local:SuccessDL) {
                    Write-Verbose -Message ('{0}   Download successful. It took {1} second(s).' -f ((' ' * $Increment),([math]::Round(((Get-Date).Subtract($Local:StartTime).TotalSeconds),2))))
                    If ($Local:DoHash) {
                        [string] $Local:FileOutHash = (Get-FileHash -Path $Local:PathFileOut -Algorithm $CheckSumAlgorithm).Hash
                        Write-Verbose -Message ('{0}HASHING {1} ("{2}" -eq "{3}")' -f ($Local:Indent,$CheckSumAlgorithm,$Local:FileOutHash,$CheckSum.ToUpper()))
                        If ($Local:FileOutHash -eq $CheckSum) {
                            Write-Verbose -Message ('{0}   SUCCESS: Hash matches.' -f ($Local:Indent))
                            $Local:Success = $true
                        }
                        Else {
                            Write-Verbose -Message ('{0}   FAIL: Hash does NOT match.' -f ($Local:Indent))
                        }
                    }
                    Else {
                        $Local:Success = $true
                    }
                }            
                ElseIf (-not($Local:SuccessDL)) {
                    Write-Verbose -Message ('{0}   FAIL: Download failed.' -f ($Local:Indent))
                }
                Else {
                    Write-Verbose -Message ('{0}   FAIL: Something failed.' -f ($Local:Indent))
                }


                # If fail, increment attempts
                If (-not($Local:Success)) {$Local:Attempts += 1}
            }

            Return ($Local:Success)  
        }
        #endregion Download-FileToDir
    #endregion Functions

    

    #region    Settings
        # Settings - PowerShell
        $DebugPreference = 'SilentlyContinue'
        $ErrorActionPreferene = 'Continue'
        $VerbosePreference = 'Continue'
        $WarningPreference = 'Continue'
    #endregion Settings



    #region    CW Automate Uninstaller
    [string] $NameProgramUninstall = 'ConnectWise Automate'
    [string] $PathDirRegAutomate = 'HKLM:\SOFTWARE\LabTech'
    [string] $PathDirRegAutomateUninstaller = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{58A3001D-B675-4D67-A5A1-0FA9F08CF7CA}'
    If (Test-Path -Path $PathDirRegAutomateUninstaller) {
        Write-Verbose -Message ('{0} is installed. Uninstalling.' -f ($NameProgramUninstall))

        [string] $URLCWAutomateUn = 'https://ironstoneit.hostedrmm.com/Labtech/Deployment.aspx?ID=-2'
        [string] $PathDirDownloadCWAutomateUn = ('{0}\Windows\Temp\' -f ($env:SystemDrive))
        [string] $NameFileExeCWAutomateUn = 'Agent_Uninstaller.exe'
        [string] $PathFileExeCWAutomateUn = ('{0}{1}' -f ($PathDirDownloadCWAutomateUn,$NameFileExeCWAutomateUn))
        Download-FileToDir -NameFileOut 'Agent_Uninstaller.exe' -DLURL $URLCWAutomateUn -PathDirOut $PathDirDownloadCWAutomateUn
        Start-Process -FilePath $PathFileExeCWAutomateUn -Wait
        Remove-Item -Path $PathFileExeCWAutomateUn -Force -ErrorAction SilentlyContinue

        If (Test-Path -Path $PathDirRegAutomate) {
            Write-Verbose -Message ('Removing leftovers in registry ({0})' -f ($PathDirRegAutomate))
            Remove-ItemProperty -Path $PathDirRegAutomate -Name '*' -Force
            Remove-Item -Path $PathDirRegAutomate -Recurse -Force
        }
    }
    Else {
        Write-Verbose -Message ('{0} is not installed. Skipping.' -f ($NameProgramUninstall))
    }
    #endregion CW Automate Uninstaller



    ##############################
    #endregion Code Goes Here
 
 
    
}
Catch {
    # Construct Message
    $ErrorMessage = ('Unable to {0}.' -f ($AppName))
    $ErrorMessage += " `n"
    $ErrorMessage += 'Exception: '
    $ErrorMessage += $_.Exception
    $ErrorMessage += " `n"
    $ErrorMessage += 'Activity: '
    $ErrorMessage += $_.CategoryInfo.Activity
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error Category: '
    $ErrorMessage += $_.CategoryInfo.Category
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error Reason: '
    $ErrorMessage += $_.CategoryInfo.Reason
    Write-Error -Message $ErrorMessage
}
Finally {
    Stop-Transcript
}
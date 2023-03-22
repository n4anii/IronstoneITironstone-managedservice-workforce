<#

.SYNOPSIS
Installs eRoom

.DESCRIPTION
Installs eRoom

.NOTES
You need to run this script in the DEVICE context in Intune.

#>


#Change the app name
$AppName = 'Device_Install_eRoom'
$Timestamp = Get-Date -Format 'HHmmssffff'
$LogDirectory = ('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration' -f $env:SystemDrive)
$Transcriptname = ('{2}\{0}_{1}.txt' -f $AppName, $Timestamp, $LogDirectory)
$ErrorActionPreference = 'continue'

if (!(Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -ErrorAction Stop
}

Start-Transcript -Path $Transcriptname
#Wrap in a try/catch, so we can always end the transcript
Try {
    # Get the ID and security principal of the current user account
    $myWindowsID = [Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal = new-object -TypeName System.Security.Principal.WindowsPrincipal -ArgumentList ($myWindowsID)
 
    # Get the security principal for the Administrator role
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
 
    # Check to see if we are currently running "as Administrator"
    if (!($myWindowsPrincipal.IsInRole($adminRole))) {
        # We are not running "as Administrator" - so relaunch as administrator
   
        # Create a new process object that starts PowerShell
        $newProcess = new-object -TypeName System.Diagnostics.ProcessStartInfo -ArgumentList 'PowerShell'
   
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
        #region    Settings, Variables
            # PowerShell Settings
            $VerbosePreference = 'Continue'
            $ErrorActionPreference = 'Continue'
            $WarningPreference = 'Continue'
            # Script settings
            [bool] $WriteChanges = $true
        #endregion Settings, Variables
    

        #region Functions
            #region Download-FileToDir
            Function Download-FileToDir {
                param(
                    [Parameter(Mandatory=$true)]
                    [String] $NameFileOut, $DLURL,
                    [Parameter(Mandatory=$false)]
                    [string] $PathDirOut = ('{0}\Temp\' -f ($env:windir)),
                    [string] $CheckSumAlgorithm, $CheckSum,
                    [byte]   $TryXTimes  = 2,
                    [byte]   $Increment  = 6,
                    [byte]   $DLMethod   = 1
                )

                # Variables - From input
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
                            Write-Verbose -Message ('{0}HASHING {1} ("{2}" -eq "{3}")' -f ($Local:Indent,$CheckSumAlgorithm,$Local:FileOutHash,$CheckSum))
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



        #region    Main
            #region    Variables
                [string] $NameProgram       = 'eRoom 7 Plugin'
                [string] $NameFileDownload  = 'ClientSetup_7.50.601.93.P14.exe'                                                                                 # MUST BE UPDATED WITH A NEW RELEASE
                [string] $PathFileDownload  = ('{0}\Temp\{1}' -f ($env:windir,$NameFileDownload))
                [string] $PathDirInstall    = ('{0}\eRoom 7\' -f (${env:ProgramFiles(x86)}))
                [string] $PathFileInstalled = ('{0}ERClient7.exe' -f ($PathDirInstall))
                [string] $PathFileLog       = ('{0}\Install-{1}.log' -f ($LogDirectory,$NameFileDownload))          
                [string] $ArgsFileInstall   = ('/S /v/qn')
                [string] $VersionFileInstall= '7.50.601.93'    # Previous: '7.50.601.93','7.50.601.66','7.50.601.41'                                            # MUST BE UPDATED WITH A NEW RELEASE
                [string] $URLFileDownload   = 'https://support.symetricollaboration.com/hc/no/article_attachments/360000010849/ClientSetup_7.50.601.93.P14.exe' # MUST BE UPDATED WITH A NEW RELEASE
                [string[]] $HashFileInstall = @('Sha1','255ae45f1d299cb2a350ecf68917c7138ac072ab')                                                              # MUST BE UPDATED WITH A NEW RELEASE
            #endregion Variables


            #region    Install
                [bool] $Install = $true
            
                # Check if AlreadyInstalled
                [bool] $AlreadyInstalled = Test-Path -Path $PathDirInstall
                Write-Verbose -Message ('"{0}" already Installed? {1}' -f ($NameProgram,$AlreadyInstalled))
            
                # Check installed version
                If (Test-Path -Path $PathDirInstall) {               
                    [string] $VersionInstalled = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($PathFileInstalled).FileVersion)
                    [bool] $CurrentVersionUpToDate = ([System.Version]$VersionInstalled -ge [System.Version]$VersionFileInstall)
                    Write-Verbose -Message ('Installed Version: {0}, Newest version: {1}. Up to date? {2}' -f ($VersionInstalled,$VersionFileInstall,$CurrentVersionUpToDate))
                    $Install = -not $CurrentVersionUpToDate
                }
            
                # Install if not installed at all, or current version not up to date
                If ($Install) {
                    Write-Verbose -Message ('WriteChanges = {0}' -f ($WriteChanges))
                    Write-Verbose -Message ('Downloading "{0}".' -f ($NameFileDownload))
                    If (Download-FileToDir -NameFileOut $NameFileDownload -DLURL $URLFileDownload -CheckSumAlgorithm $HashFileInstall[0] -CheckSum $HashFileInstall[1] -DLMethod 2 -Increment 3) {                
                        If ($WriteChanges) {
                            Write-Verbose -Message ('Start-Process -FilePath "{0}" -ArgumentList "{1}" -Wait' -f ($PathFileDownload,$ArgsFileInstall))
                            Start-Process -FilePath $PathFileDownload -ArgumentList $ArgsFileInstall -Wait
                            Write-Verbose -Message ('Installer exit successfully ($?)? ' + $?)
                    
                            # Check if program actually got installed
                            Write-Verbose -Message ('Program actually installed (Test-Path)? {0}' -f (Test-Path -Path $PathDirInstall))
                        }
                        Else {
                            Write-Verbose -Message ('Skipped install.')
                        }
                    
                    }
                    Else {
                        Write-Verbose -Message ('Failed to download.')
                    }
                }
            #endregion Install


            #region    Clean Up
            $null = Remove-Item -Path $PathFileDownload -Force -ErrorAction SilentlyContinue
            #endregion Clean Up
        #endregion Main   
    ##############################
    #endregion Code Goes Here
 
 
    
}
Catch {
    # Construct Message
    $ErrorMessage = 'Failed.'
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
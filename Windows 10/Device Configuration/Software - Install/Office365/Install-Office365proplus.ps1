<#

.SYNOPSIS


.DESCRIPTION


.NOTES
You need to run this script in the DEVICE context in Intune.

#>


#Change the app name
$AppName = 'Install-Office365proplus'
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

    #region Functions
    #region Download-FileToDir
    Function Download-FileToDir {
        param(
            [Parameter(Mandatory = $true)]
            [String] $NameFileOut, $DLURL,
            [Parameter(Mandatory = $false)]
            [string] $PathDirOut = ('{0}\Temp\' -f ($env:windir)),
            [string] $CheckSum, $CheckSumAlgorithm,
            [byte]   $TryXTimes = 2,
            [byte]   $Increment = 6,
            [byte]   $DLMethod = 1
        )

        [string] $Local:PathDirOut = $PathDirOut
        [string] $Local:PathFileOut = ('{0}{1}' -f ($Local:PathDirOut, $NameFileOut))
        [string] $Local:OutStr = [string]::Empty
        [bool]   $Local:Success = $false
        [bool]   $Local:DoHash = -not(([string]::IsNullOrEmpty($CheckSum)) -or ([string]::IsNullOrEmpty($CheckSumAlgorithm)))
        [byte]   $Local:Attempts = 1
        [byte]   $Local:DLStartAtMethod = $DLMethod
        [string] $Local:Indent = (' ' * $Increment)

        # Delete file if it exists
        Remove-Item -Path $Local:PathFileOut -Force -ErrorAction SilentlyContinue

        While (($Local:Attempts -le $TryXTimes) -and (-not($Local:Success))) {
            $Local:OutStr += ('{0}# ATTEMPT {1}/{2}{3}' -f ($Local:Indent, $Local:Attempts, $TryXTimes, "`r`n"))
            
            [bool] $Local:SuccessDL = $false
            $Local:DLStartAtMethod = $DLMethod

            # DL Method 1: Start-BitsTransfer
            If ($Local:DLStartAtMethod -eq 1) {
                $Local:OutStr += ('{0}Downloading (Start-BitsTransfer){1}' -f ($Local:Indent, "`r`n"))
                [System.DateTime] $Local:StartTime = Get-Date
                $null = Start-BitsTransfer -Source $DLURL -Destination $Local:PathFileOut -ErrorAction SilentlyContinue
                If ($?) {
                    $Local:SuccessDL = $true
                }
                Else {
                    $Local:DLStartAtMethod += 1
                    $Local:OutStr += ('{0}   Failed!{1}' -f ($Local:Indent, "`r`n"))                  
                }
            }


            # DL Method 2: System.Net.WebClient
            If ($Local:DLStartAtMethod -eq 2) {
                $OutStr += ('{0}Downloading (System.Net.WebClient){1}' -f ($Local:Indent, "`r`n"))
                [System.DateTime] $Local:StartTime = Get-Date
                (New-Object System.Net.WebClient).DownloadFile($DLURL, $Local:PathFileOut)
                If ($?) {
                    $Local:SuccessDL = $true
                }                                     
                Else {
                    $Local:DLStartAtMethod += 1
                    $Local:OutStr += ('{0}   Failed!{1}' -f ($Local:Indent, "`r`n"))
                }
            }
              
                
            # DL Method 3: Invoke-WebRequest
            If ($Local:DLStartAtMethod -eq 3) {    
                $Local:OutStr += ('{0}Downloading (Invoke-WebRequest){1}' -f ($Local:Indent, "`r`n"))
                [System.DateTime] $Local:StartTime = Get-Date
                Invoke-WebRequest -Uri $DLURL -OutFile $Local:PathFileOut
                If ($?) {
                    $Local:SuccessDL = $true
                }
                Else {
                    $Local:OutStr += ('{0}   Failed!{1}' -f ($Local:Indent, "`r`n"))
                }
            }

            
            If ($Local:SuccessDL) {
                $Local:OutStr += ('{0}   Download successful. It took {1} second(s).{2}' -f ((' ' * $Increment), ([math]::Round(((Get-Date).Subtract($Local:StartTime).TotalSeconds), 2)), "`r`n"))
                If ($Local:DoHash) {
                    [string] $Local:FileOutHash = (Get-FileHash -Path $Local:PathFileOut -Algorithm $CheckSumAlgorithm).Hash
                    $Local:OutStr += '{0}HASHING {1} ("{2}" -eq "{3}"){4}' -f ($Local:Indent, $CheckSumAlgorithm, $Local:FileOutHash, $CheckSum, "`r`n")
                    If ($Local:FileOutHash -eq $CheckSum) {
                        $Local:OutStr += '{0}   SUCCESS: Hash matches.{1}' -f ($Local:Indent, "`r`n")
                        $Local:Success = $true
                    }
                    Else {
                        $Local:OutStr += '{0}   FAIL:Hash does NOT match.{1}' -f ($Local:Indent, "`r`n")
                    }
                }
                Else {
                    $Local:Success = $true
                }
            }            
            ElseIf (-not($Local:SuccessDL)) {
                $Local:OutStr += ('{0}   FAIL: Download failed{1}' -f ($Local:Indent, "`r`n"))
            }
            Else {
                $Local:OutStr += ('{0}   FAIL: Something failed{1}' -f ($Local:Indent, "`r`n"))
            }


            # If fail, increment attempts
            If (-not($Local:Success)) {$Local:Attempts += 1}
        }

        Return ($Local:Success, $Local:OutStr)  
    }
    #endregion Download-FileToDir
    #endregion Functions


    # VARIABLES
    [string]$WorkingDirectory = ('{0}\Program Files\IronstoneIT\Office365\InstallationFiles\' -f $env:SystemDrive)
    $WorkingDirectoryPathExists = Test-Path -Path $WorkingDirectory -ErrorAction SilentlyContinue
    if ($WorkingDirectoryPathExists) {
        Write-Output ('Directory [{0}] already exists.' -f $WorkingDirectory)
    }
    else {
        Write-Output ('Creating directory [{0}].' -f $WorkingDirectory)
        New-Item -Path $WorkingDirectory -ItemType Directory
    }

    # Download files
    Write-Output 'Downloading Install-OfficeClickToRun.ps1'
    Download-FileToDir -NameFileOut 'Install-OfficeClickToRun.ps1' -DLURL 'https://metierclientstorage.blob.core.windows.net/office365/Install-OfficeClickToRun.ps1' -PathDirOut $WorkingDirectory  -TryXTimes 2
    Write-Output 'Office2016Setup.exe'
    Download-FileToDir -NameFileOut 'Office2016Setup.exe' -DLURL 'https://metierclientstorage.blob.core.windows.net/office365/Office2016Setup.exe' -PathDirOut $WorkingDirectory  -TryXTimes 2
    Write-Output 'Downloading configuration file'
    Download-FileToDir -NameFileOut 'configuration.xml' -DLURL 'https://metierclientstorage.blob.core.windows.net/office365/configuration.xml' -PathDirOut $WorkingDirectory  -TryXTimes 2
 
    #Dot-Source the root destination
    Write-Output 'Joining paths and dot sourcing'
    $path = Join-Path -Path $WorkingDirectory -ChildPath Install-OfficeClickToRun.ps1
    . $path
 
     Write-Output 'Installing office'
    Install-OfficeClickToRun -TargetFilePath ('{0}configuration.xml ' -f $WorkingDirectory)
 
    
}
Catch {
    # Construct Message
    $ErrorMessage = 'Unable to install OfficeClickToRun.'
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

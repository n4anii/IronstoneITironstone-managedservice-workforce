<#

.SYNOPSIS


.DESCRIPTION


.NOTES
You need to run this script in the DEVICE context in Intune.

#>


#Change the app name
$AppName = 'Device_Install-HPIDTAudioDriver'
$Timestamp = Get-Date -Format 'HHmmssffff'
$LogDirectory = ('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration' -f $env:SystemDrive)
$Transcriptname = ('{2}\{0}_{1}.txt' -f $AppName, $Timestamp, $LogDirectory)
$ErrorActionPreference = 'Continue'

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
 ####################################################
 
 
#region Functions
    #region Download-FileToWinTemp
    Function Download-FileToWinTemp {
        param(
            [Parameter(Mandatory=$true)]
            [String] $NameFileDL, $DLURL,
            [Parameter(Mandatory=$false)]
            [byte] $Increment = 6,
            [byte] $DLMethod  = 1
        )

        [string] $Local:PathDirDL  = ('{0}\Temp\' -f ($env:windir))
        [string] $Local:PathFileDL = ('{0}{1}' -f ($PathDirDL,$NameFileDL))
        [string] $Local:OutStr     = [string]::Empty
        [bool]   $Local:Success    = $false

        # Delete file if it exists
        Remove-Item -Path $Local:PathFileDL -Force -ErrorAction SilentlyContinue


        # DL Method 1: Start-BitsTransfer
        If ($DLMethod -eq 1) {
            $Local:OutStr += ('{0}Downloading (Start-BitsTransfer){1}' -f ((' ' * $Increment),"`r`n"))
            [System.DateTime] $Local:StartTime = Get-Date
            $null = Start-BitsTransfer -Source $DLURL -Destination $Local:PathFileDL -ErrorAction SilentlyContinue
            If ($?) {
                $Local:Success =  $true
            }
            Else {
                $DLMethod += 1
                $Local:OutStr += ('{0}   Failed!{1}' -f ((' ' * $Increment),"`r`n"))                  
            }
        }


        # DL Method 2: System.Net.WebClient
        If ($DLMethod -eq 2) {
            $OutStr += ('{0}Downloading (System.Net.WebClient){1}' -f ((' ' * $Increment),"`r`n"))
            [System.DateTime] $Local:StartTime = Get-Date
            (New-Object System.Net.WebClient).DownloadFile($DLURL,$Local:PathFileDL)
            If ($?) {
                $Local:Success = $true
            }                                     
            Else {
                $DLMethod += 1
                $Local:OutStr += ('{0}   Failed!{1}' -f ((' ' * $Increment),"`r`n"))
            }
        }
              
                
        # DL Method 3: Invoke-WebRequest
        If ($DLMethod -eq 3) {    
            $Local:OutStr += ('{0}Downloading (Invoke-WebRequest){1}' -f ((' ' * $Increment),"`r`n"))
            [System.DateTime] $Local:StartTime = Get-Date
            Invoke-WebRequest -Uri $DLURL -OutFile $Local:PathFileDL
            If ($?) {
                $Local:Success = $true
            }
            Else {
                $Local:OutStr += ('{0}   Failed!{1}' -f ((' ' * $Increment),"`r`n"))
            }
        }


        If ($Local:Success) {
            $Local:OutStr += ('{0}   Download successful. It took {1} second(s)' -f ((' ' * $Increment),(Get-Date).Subtract($Local:StartTime).TotalSeconds))
        }

        Return ($Local:Success,$Local:OutStr)  
    }
    #endregion Download-FileToWinTemp


    #region Check-IfProgramIsInstalled
    Function Check-IfProgramIsInstalled {
        Param(
            [Parameter(Mandatory=$true)]
            [string] $NameProg, $PathProgramInstallDir
        )
        
        ### Variables
        [bool] $Local:Success = $false
        

        ### Check that neither of the parameters is NullOrEmpty
        If ([string]::IsNullOrEmpty($NameProg) -or [string]::IsNullOrEmpty($PathProgramInstallDir)) {
            return $false
        }


        ### 1st method: Check if install dir exists
        If (Test-Path -Path $PathProgramInstallDir -ErrorAction SilentlyContinue) {
            $Local:Success = $true
        }


        ### 2nd method: Check if Win32_Product extists
        <#If (-not($Local:Success)) {
            # Only cache programs once per script run
            If (-not($Script:Win32Programs)) {
                $Script:Win32Programs = Get-WmiObject -Class Win32_Product
            }
            $Local:Program = $Script:Win32Programs | Where-Object {$_.Name -like ('*{0}*' -f ($NameProg))}
            If ((Measure-Object -InputObject $Local:Program).Count -gt 0) {
                $Local:Success = $true
            }
        }#>
       

        # Return execution result
        Return $Local:Success
    }
    #endregion Check-IfProgramIsInstalled


    #region 7zip
        #region Set-7zPath
        Function Set-7zPath {
        
            # Help variables
            [bool] $Local:Success = $false
            $Local:Path7zip = [string]::Empty
            $Local:PathsToTry = @('C:\Program Files\7-Zip\7z.exe','C:\Program Files (x86)\7-Zip\7z.exe')

            # Find 7-zip
            foreach ($Path in $Local:PathsToTry) {
                If (Test-Path -Path $Path -ErrorAction SilentlyContinue) {
                    $Local:Path7zip = $Path
                    $Local:Success = $true
                    Break
                }
            }

            ## If success
            If ($Local:Success) {
                [string] $Script:Path7zip = $Local:Path7zip        
            }

            ## Return status
            [bool]   $Script:7zipPresent = $Local:Success
            return $Local:Success
        }
        #endregion Set-7zPath


        #region Extract-7zip
        Function Extract-7zip {
            Param(
            [Parameter(Mandatory=$true)]
            [string] $PathItemIn,$PathDirOut,$PathItemOut
            )
        
            # Help variables
            $Local:Success = $false
        

            # Check that we indeed have 7-zip available
            If (-not($Script:Path7zip)) {
                If (-not(Set-7zPath)) {
                    return $Local:Success
                }
            }


            # Check that input file exists
            If (-not(Test-Path -Path $PathItemIn -ErrorAction SilentlyContinue)) {
                return $Local:Success
            }


            # Remove output dir and files if it exists
            If (Test-Path -Path $PathDirOut -ErrorAction SilentlyContinue) {
                Remove-Item -Path $PathDirOut -Recurse -Force
                If (-not($?)) {
                    return $Local:Success
                }
            }


            # Create output dir
            $null = New-Item -Path $PathDirOut -ItemType Directory -Force -ErrorAction SilentlyContinue 
            If (-not($?)) {
                Return $Local:Success
            }


            # Extract the item
            # e = "Extract" | o = "Output directory"
            [string] $Local:Do = ('"{0}" x -y "{1}" -o"{2}"' -f($Script:Path7zip,$Local:PathItemIn,$PathDirOut))
            $null = cmd /c ('{0}' -f ($Local:Do))


            # Check for success
            If ($? -and (Test-Path -Path $PathItemOut -ErrorAction SilentlyContinue)) {
                $Local:Success = $true
            }


            # Return execution result
            return $Local:Success
        }
        #endregion Extract-7zip
    #endregion 7-zip


    #region MachineInfo
        #region Get-MachineInfo
        Function Get-MachineInfo {
            $Script:ComputerName = $env:COMPUTERNAME
            [String] $Script:ComputerManufacturer = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemManufacturer'
            If (-not([String]::IsNullOrEmpty($Script:ComputerManufacturer))) {
                [String] $Script:ComputerFamily = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemFamily'
                [String] $Script:ComputerProductName = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemProductName'
                [String] $Script:WindowsEdition = Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProductName'
                [String] $Script:WindowsVersion = Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ReleaseId'
                [String] $Script:WindowsVersion += (' ({0})' -f (Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentBuild'))
            } 
            Else {
                $Local:EnvInfo = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property Manufacturer,Model,SystemFamily        
                [String] $Script:ComputerManufacturer = $Local:EnvInfo.Manufacturer
                [String] $Script:ComputerFamily = $Local:EnvInfo.SystemFamily
                [String] $Script:ComputerProductName = $Local:EnvInfo.Model
                $Local:OSInfo = Get-WmiObject -Class win32_operatingsystem | Select-Object -Property Caption,Version
                [String] $Script:WindowsEdition = $Local:OSInfo.Caption
                [String] $Script:WindowsVersion = $Local:OSInfo.Version
            }
        }
        #endregion Get-MachineInfo


        #region Query-Registry
        Function Query-Registry {
            Param ([Parameter(Mandatory=$true)] [string] $Dir)
            $Local:Out = [string]::Empty
            [String] $Local:Key = $Dir.Split('{\}')[-1]
            [String] $Local:Dir = $Dir.Replace($Local:Key,'')
            
            $Local:Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Local:Key) -ErrorAction SilentlyContinue
            If ($Exists) {
                $Local:Out = $Local:Exists.$Local:Key
            }
            return $Local:Out
        }
        #endregion Query-Registry
    #endregion MachineInfo
#endregion Functions
 




#region Initialize
    Get-MachineInfo
    Write-Output -InputObject '### Environment Info'
    Write-Output -InputObject ('Machine info: Name = "{0}", Manufacturer = "{1}", Family = "{2}", Model = "{3}"' -f ($Script:ComputerName,$Script:ComputerManufacturer,$Script:ComputerFamily,$Script:ComputerProductName))
    Write-Output -InputObject ('Windows info: Edition = "{0}", Version = "{1}"' -f ($Script:WindowsEdition,$Script:WindowsVersion))
#endregion Initialize





#region Main
    # VARIABLES
    #[string[]] $Local:ComputerModels = @('EliteBook 8?? G1','20HR003GMX')
    [string[]] $Local:ComputerModels = @('EliteBook 8?? G1')
    [bool]     $Local:SuccessMatch = $Local:SuccessDownload = $Local:SuccessExtract = $Local:SuccessInstall = $false



    # CHECK IF _THIS_ COMPUTER IS THE RIGHT ONE
    Write-Output -InputObject '### SEARCHING FOR COMPUTER'
    :loop foreach ($ComputerModel in $Local:ComputerModels) {
        [bool] $Local:DidItMatch = ($Script:ComputerProductName -like ('*{0}*' -f ($ComputerModel)))
        Write-Output -InputObject ('"{0}" like "*{1}*" {2}' -f ($Script:ComputerProductName, $ComputerModel, $Local:DidItMatch.ToString()))
        If ($Local:DidItMatch) {
            Write-Output -InputObject 'Will skip the rest.'
            $Local:SuccessMatch = $true
            Break :loop
        }
        If ($ComputerModel -eq $Local:ComputerModels[-1]) {
            Write-Output -InputObject 'This computer is not supported.'
        }
    }



    # MAKE SURE 7-ZIP IS AVAILABLE
    if ($Local:SuccessMatch) {
        Write-Output -InputObject '### CHECKING IF 7-ZIP IS AVAILABLE'
        If (-not(Set-7zPath)) {
            Write-Output -InputObject '7-Zip is not available. Exit.'
            break
        } 
        Else {
            Write-Output -InputObject '7-Zip is available.'
        }
    }



    # CREATE VARIABLES
    if ($Local:SuccessMatch) {       
        [string] $Script:NameFileDL      = 'sp65631.exe'
        [string] $Script:DLURL           = 'http://ftp.hp.com/pub/softpaq/sp65501-66000/sp65631.exe'
        [string] $Script:PathDirIn       = ('{0}\Temp\' -f ($env:windir))
        [string] $Script:PathItemIn      = ('{0}{1}' -f ($Script:PathDirIn,$Script:NameFileDL))
        [string] $Script:PathDirOut      = ('{0}{1}' -f ($Script:PathDirIn,'IDTAudioDriver\'))
        [string] $Script:PathItemOut     = ('{0}{1}' -f ($Script:PathDirOut,'IDTSetup.exe'))
        [string] $Script:PathDirInstall  = ('{0}\Program Files\IDT\' -f ($env:SystemDrive))
        [string] $Script:PathDirLog      = ('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration' -f $env:SystemDrive)
        [string] $Script:InstallArgs     = ('"{0}" /s' -f ($Script:PathItemOut))
        [string] $Script:InstallArgsAlone= '/s'
        [string] $Script:InstallArgsFd   = ('"{0}" /s /l "{1}\InstallIDTAudioDriver.txt"' -f ($Script:PathItemOut,$Script:PathDirLog))
    



    # CHECK IF INSTALLED ALREADY
        Write-Output -InputObject '### CHECKING IF PROGRAM IS INSTALLED ALREADY'     
        If (Check-IfProgramIsInstalled -NameProg 'IDT' -PathProgramInstallDir $Script:PathDirInstall) {
            Write-Output -InputObject 'Program already installed.'
            $Local:SuccessInstall = $true
        }
        Else {
            Write-Output -InputObject 'Program is not installed. Continue.'
        }
    }
        
        
        
    # DOWNLOAD
    If ($Local:SuccessMatch -and (-not($Local:SuccessInstall))) {
        Write-Output -InputObject '### DOWNLOADING'
        $Script:DownloadFile = Download-FileToWinTemp -NameFileDL $Script:NameFileDL -DLURL $Script:DLURL -DLMethod 2
        Write-Output -InputObject ($Script:DownloadFile[1])
        If ($Script:DownloadFile[0]) {
            Write-Output -InputObject 'Success'
            $Script:SuccessDownload = $true
        }
        Else {
            Write-Output -InputObject 'Fail'
            break
        }
    }              
        
                        

    # EXTRACT
    If ($Local:SuccessDownload) {
        Write-Output -InputObject '### EXTRACTING'
        If (Extract-7zip -PathItemIn $Local:PathItemIn -PathDirOut $Local:PathDirOut -PathItemOut $Local:PathItemOut) {
            Write-Output -InputObject ('Success')
            $Local:SuccessExtract = $true
        }
        Else {
            Write-Output -InputObject ('Fail')
            break
        }
    }
            


    # INSTALL
    If ($Local:SuccessExtract) {
        Write-Output -InputObject '### INSTALLING'
        Write-Output -InputObject $Local:InstallArgs
        #Invoke-Expression -Command:$Local:InstallArgs
        #Start-Process -FilePath $Script:PathItemOut -ArgumentList ('"{0}"' -f $Script:InstallArgsAlone) -NoNewWindow -Wait
        $null = Start-Process -FilePath $Script:PathItemOut -ArgumentList '/S' -NoNewWindow -Wait
        #cmd /c ('{0}' -f ($Local:InstallArgs))        
        If (Check-IfProgramIsInstalled -NameProg 'IDT' -PathProgramInstallDir $Script:PathDirInstall) {
            Write-Output -InputObject 'Success'
            $Local:SuccessInstall = $true
        }
        Else {
            Remove-Item -Path $Script:PathDirInstall -Recurse -Force -ErrorAction SilentlyContinue
            Write-Output -InputObject 'Fail'
        }       
    }
#endregion Main


 
####################################################    
}
Catch {
    # Construct Message
    $ErrorMessage = 'ERROR.'
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
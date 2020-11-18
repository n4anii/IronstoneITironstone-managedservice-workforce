<#

.RESOURCES
    Lenovo System Interface Foundation (LSIF)
        Info:      https://support.lenovo.com/downloads/ds105970
        Installer: https://filedownload.lenovo.com/enm/sift/core/SystemInterfaceFoundation.exe
    
    Lenovo System Update
        Installer: https://support.lenovo.com/downloads/DS012808


    Lenovo Service Bridge - Auto Detect Model on Lenovo Web Pages
        Info:      https://support.lenovo.com/solutions/ht104055
        Installer: https://download.lenovo.com/lsbv4/LSBSetup.exe

    Lenovo Vantage
        Lenovo Vantage Application for Large Enterprise:    https://support.lenovo.com/us/en/solutions/hf003321
#>


#region    Settings
[bool] $ForceInstall = $true
#endregion Settings



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
            [string] $PathDirOut = ('{0}\Temp\' -f ($env:windir)),
            
            [byte]   $TryXTimes  = 2,
            [byte]   $DLMethod   = 1,
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
                    [System.DateTime] $Local:StartTime = Get-Date
                    $null = Start-BitsTransfer -Source $DLURL -Destination $Local:PathFileOut -ErrorAction SilentlyContinue
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
                [System.DateTime] $Local:StartTime = Get-Date
                (New-Object System.Net.WebClient).DownloadFile($DLURL,$Local:PathFileOut)
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
                [System.DateTime] $Local:StartTime = Get-Date
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



#region    Lenovo
    # Continue only if this computer is a Lenovo
    if ((Get-ItemProperty -Path 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS' -Name 'SystemManufacturer' | Select-Object -ExpandProperty 'SystemManufacturer') -notlike 'lenovo') {
        Write-Output -InputObject ('This is not a Lenovo Computer. Skipping.')
    }
    else {
        # Log if $ForceInstall is $true
        if ($ForceInstall){Write-Output -InputObject ('$ForceInstall is $true')}

        # Set and create Lenovo Installers Download Location
        [string] $PathDirDownload = ('{0}\Temp\LenovoInstallers' -f ($env:windir))
        if (-not(Test-Path -Path $PathDirDownload)){$null = New-Item -Path $PathDirDownload -ItemType 'Directory' -Force}
        
        #region    Lenovo System Interface Foundation
            # Lenovo System Interface Foundation - Variables
            [string] $PathDirLSIF           = ('{0}\Lenovo\ImController\PluginHost' -f (${env:ProgramFiles(x86)}))
            [string] $PathFileLSIF          = ('{0}\Lenovo.Modern.ImController.PluginHost.exe' -f ($PathDirLSIF))
            [string] $NameProgLSIF          = 'Lenovo System Interface Foundation'
            [string] $NameFileLSIFInstaller = 'SystemInterfaceFoundation.exe'
            [string] $PathFileLSIFInstaller = ('{0}\{1}' -f ($PathDirDownload,$NameFileLSIFInstaller))
            [string] $URLFileLSIFInstaller  = 'https://filedownload.lenovo.com/enm/sift/core/SystemInterfaceFoundation.exe'
            [string] $ArgFileLSIFInstaller  = '/verysilent /NORESTART /type=installpackageswithreboot'
            # Lenovo System Interface Foundation - Version
            [System.Version] $VersionLSIFAvailable = ('1.1.15.0')
            [System.Version] $VersionLSIFInstalled = (
                ([System.Version[]]@(Get-WindowsDriver -Online | Where-Object {
                $_.OriginalFileName -like ('{0}\System32\DriverStore\FileRepository\imdriver.inf_amd64_*\imdriver.inf' -f ($env:windir))
                } | Select-Object -ExpandProperty 'Version') | Sort-Object | Select-Object -Last 1), 
                [System.Version]'0.0.0.0' -ne $null
            )[0]
            
            # Install if available version is newer than installed version (0.0.0.0 if not installed)    
            Write-Output -InputObject ('{0} Version Installed = {1} | Version Available = {2}' -f ($NameProgLSIF,$VersionLSIFInstalled.ToString(),$VersionLSIFAvailable.ToString()))
            if ((-not($ForceInstall)) -and $VersionLSIFAvailable -le $VersionLSIFInstalled) {
                Write-Output -InputObject ('   Already up to date.' -f ($NameProgLSIF))
            }
            else {
                if (Download-FileToDir -NameFileOut $NameFileLSIFInstaller -DLURL $URLFileLSIFInstaller -PathDirOut $PathDirDownload) {
                    # Get version of downloaded file
                    [System.Version] $VersionLSIFDownloaded = (Get-Item -Path $PathFileLSIFInstaller | Select-Object -ExpandProperty 'VersionInfo' | Select-Object -ExpandProperty 'FileVersion').Trim().Replace(' ','').Replace(',','.')
                    # Only install if downloaded version is newer than installed
                    if ((-not($ForceInstall)) -and $VersionLSIFDownloaded -le $VersionLSIFInstalled) {
                        Write-Output -InputObject ('   Version installed is actually equal or newer to the one downloaded.')
                    }
                    else {                                     
                        Start-Process -FilePath $PathFileLSIFInstaller -ArgumentList $ArgFileLSIFInstaller -WindowStyle 'Hidden' -Wait
                        Write-Output -InputObject ('   "{0}" installed successfully? {1}.' -f ($NameProgLSIF,$?.ToString()))
                    }
                }
            }
        #endregion Lenovo System Interface Foundation


        #region    Lenovo System Update
            # Lenovo System Update - Variables
            [string] $PathDirLSU           = ('{0}\Lenovo\System Update' -f (${env:ProgramFiles(x86)}))
            [string] $PathFileLSU          = ('{0}\tvsu.exe' -f ($PathDirLSU))
            [string] $NameProgLSU          = 'Lenovo System Update'
            [string] $NameFileLSUInstaller = 'LenovoSystemUpdate.exe'
            [string] $PathFileLSUInstaller = ('{0}\{1}' -f ($PathDirDownload,$NameFileLSUInstaller))
            [string] $URLFileLSUInstaller  = (Invoke-WebRequest -Uri 'https://support.lenovo.com/no/en/downloads/ds012808' -Verbose:$false).Content.Split('"') | Where-Object {$_ -like 'https://download.lenovo.com/pccbbs/thinkvantage_en/systemupdate*.exe'}
            [string] $ArgFileLSUInstaller  = '/SP- /VERYSILENT'
            # Lenovo System Update - Versions
            [string] $VersionLSUAvailableString     = $URLFileLSUInstaller.Split('/')[-1].Replace('systemupdate','').Replace('.exe','')
            [System.Version] $VersionLSUAvailable   = ($VersionLSUAvailableString.Substring(0,7) + '.' + $VersionLSUAvailableString.Substring(7,2))           
            [System.Version] $VersionLSUInstalled   = $(if(Test-Path -Path $PathFileLSU){
                [System.Version]((Get-Item -Path $PathFileLSU | Select-Object -ExpandProperty 'VersionInfo' | Select-Object -ExpandProperty 'FileVersion').Trim().Replace(' ','').Replace(',','.'))
            } else {[System.Version]('0.0.0.0')})
            
            # Install if available version is newer than installed version (0.0.0.0 if not installed)
            Write-Output -InputObject ('{0} Version Installed = {1} | Version Available = {2}' -f ($NameProgLSU,$VersionLSUInstalled.ToString(),$VersionLSUAvailable.ToString()))
            if ((-not($ForceInstall)) -and $VersionLSUAvailable -le $VersionLSUInstalled) {
                Write-Output -InputObject ('   Already up to date.' -f ($NameProgLSU))
            }
            else {
                if (Download-FileToDir -NameFileOut $NameFileLSUInstaller -DLURL $URLFileLSUInstaller -PathDirOut $PathDirDownload) {
                    Start-Process -FilePath $PathFileLSUInstaller -ArgumentList $ArgFileLSUInstaller -WindowStyle 'Hidden' -Wait
                    Write-Output -InputObject ('   "{0}" installed successfully? {1}.' -f ($NameProgLSU,$?.ToString()))
                }
            }
        #endregion Lenovo System Update                                               
    }            
#endregion Lenovo
#region Functions
    #region Download-FileToDir
    Function Download-FileToDir {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string] $DLURL,

            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string] $NameFileOut, 
                        
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



#region    Assets
    # Assets - PDFFactory Pro - Customer Specific
    [string] $LicenseKeyPDFFactoryPro = '25H95-FXHA8-QR5SU'
    [string] $NameLicenseUser         = 'MetierOEC'

    # Assets - PDFFactory Pro - Installer
    [string] $WebsitePDFFactoryPro                  = (Invoke-WebRequest -Uri 'https://fineprint.com/pdfp/').Content
    [string] $UriFilePDFFactoryProInstaller         = @(($WebsitePDFFactoryPro).Split('"') | Where-Object {$_ -like 'https://fineprint.com/release/pdf*'})[0]
    [string] $NameFilePDFFactoryProInstaller        = @($UriFilePDFFactoryProInstaller.Split('/'))[-1]
    [string] $PathDirDownloadInstaller              = ('{0}\Temp' -f ($env:windir))
    [string] $PathFilePDFFactoryProInstaller        = ('{0}\{1}' -f ($PathDirDownloadInstaller,$Name))

    # Assets - PDFFactory Pro - Paths
    [string] $PathDirPDFFactoryProUninstaller       = ('{0}\System32\spool\drivers\x64\3' -f ($env:windir))
    [string] $PathFilePDFFactoryProUninstaller      = ('{0}\fppinst6.exe' -f ($PathDirPDFFactoryProUninstaller))
#endregion Assets



#region    Check if installed
    if (Test-Path -Path $PathFilePDFFactoryProUninstaller) {
        $VersionInfo = Get-Item -Path $PathFilePDFFactoryProUninstaller | Select-Object -ExpandProperty VersionInfo
        if ($VersionInfo.FileDescription -like 'pdfFactory') {
            Write-Verbose -Message 'Normal version of PDFFactory is installed. Uninstalling..'
            Start-Process -FilePath $PathFilePDFFactoryProUninstaller -ArgumentList '/uninstall /silent' -Wait
        }
    }
#endregion Check if installed



#region    Download & Install
    if ([bool](Download-FileToDir -DLURL $UriFilePDFFactoryPro -NameFileOut $NameFilePDFFactoryProInstaller -PathDirOut $PathDirDownloadInstaller)) {
        Write-Verbose -Message ('Successfully downloaded {0}.' -f ($NameFilePDFFactoryProInstaller))
    }
    else {
        Write-Verbose -Message ('Failed to download {0}.' -f ($NameFilePDFFactoryProInstaller))
        Start-Process -FilePath $PathFilePDFFactoryProInstaller -ArgumentList '/quiet /safe=1' -NoNewWindow -Wait
    }
#endregion Download & Install



#region    Apply license
    [string[]] $PathsFileSettings = @(Get-Item -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\FinePrint Software\pdfFactory6\IniHash' | Select-Object -ExpandProperty Property)
    [string] $ContentFileSettings = ('[Settings]{0}ComputerName={1}{0}Hash=D536D0D4D2F2697478F530BC053875AA{0}Name={2}{0}SerialNumber={3}' -f ("`r`n",$env:COMPUTERNAME,$NameLicenseUser,$LicenseKeyPDFFactoryPro))
    foreach ($Path in $PathsFileSettings) {
        Out-File -FilePath $Path -InputObject $ContentFileSettings -Encoding utf8 -Force
    }
#endregion Apply license
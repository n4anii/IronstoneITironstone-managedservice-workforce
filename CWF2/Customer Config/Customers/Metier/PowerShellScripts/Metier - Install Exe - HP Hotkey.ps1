<#
.SYNOPSIS


.DESCRIPTION


.AUTHOR
Olav R. Birkeland


.CHANGELOG

.TODO
- Ecrypt files, or use Azure Private Blob storage, so install files can't be used by anyone
    - 7z encrypted: "7z.exe a secure.7z * -pSECRET"
- More generalization
- Add ability to match with multiple computer catergories
    - A category "all" for universal programs, like Chrome, Firefox
#>



#region Variables and Settings
# Settings
[uint16] $Script:DebugLevel = 0
[bool] $DebugWinTemp = $true
[bool] $DebugConsole = $false
[bool] $Script:ReadOnly = $false        # Will simulate run:  Everything but actually installing
[bool] $Script:TestRun = $false         # OVERRIDES READONLY: Will try to download all the files available, in order to discover potential errors. NO INSTALL.
If ($DebugWinTemp) {$Script:DebugStr=[String]::Empty}
If ($Script:DebugLevel -ge 1) {$Script:DeepDebugStr='{0}### Deep Debug{0}' -f ("`r`n")}
[String] $WhatToConfig = 'Metier - Install - HP Hotkey Support'


# Azure Blob Storage
[String[]] $Script:BlobKey = @('hb0NICjWMoeXeZnayw0offyfLOSNU7uM1FRF9iH1H/RkRH8jGdKGwuPh3svF4udy8JkfHa6rDitFdbp+ZDLaew==','DefaultEndpointsProtocol=https;AccountName=metierclientstorage;AccountKey=hb0NICjWMoeXeZnayw0offyfLOSNU7uM1FRF9iH1H/RkRH8jGdKGwuPh3svF4udy8JkfHa6rDitFdbp+ZDLaew==;EndpointSuffix=core.windows.net')


### Tools
# 7-zip
[bool] $Script:7zPresent = $false
[String] $Script:7z = 'C:\Program Files\7-Zip\7z.exe'
If (-not(Test-Path $Script:7z -ErrorAction SilentlyContinue)) {$Script:7z = 'C:\Program Files(x86)\7-Zip\7z.exe'
    If (Test-Path $Script:7z -ErrorAction SilentlyContinue) {$Script:7zPresent = $true}
}
Else {$Script:7zPresent = $true}


### Script specific variables
# PC MODEL GROUPS
[System.Collections.ArrayList] $Script:PCModelGroups = New-Object System.Collections.ArrayList
$null = $Script:PCModelGroups.Add(@('EliteBook 8*70*','ZBook 15','ProBook 6*0 G1','EliteBook 8*0 G1'))
$null = $Script:PCModelGroups.Add(@('ProBook 4*0 G2','EliteBook 8*0 G2'))
$null = $Script:PCModelGroups.Add(@('ZBook Studio G3','EliteBook 8*0 G3','EliteBook 8*8 G3','EliteBook 8*0 G4'))
$null = $Script:PCModelGroups.Add(@('20HR003GMX','20FB0075MX'))

# SHARED PROGRAM INFO
[String] $Local:InstallLocationHPHotkeysSupport = (${env:ProgramFiles(x86)} + '\HP\HP Hotkey Support\')
[String] $Script:InstallFileNameHPHotkeysSupport = 'HP Hotkey Support.msi'
[String] $Local:MSIInstallParameters = ('msiexec.exe /i _ /quiet /norestart /L*V "{0}"' -f ($env:windir + '\temp\msiexec.log'))
[String[]] $Script:ScenarioInfo = @('0|EXE','1|EXE in 7z','2|EXE in ZIP','3|MSI','4|MSI in 7z','5|MSI in ZIP','6|MSI in 7z from Azure Private Blob')

# PROGRAM INFO                     NAME | DL URL | INSTALL LOCATION | INSTALL PARAMETERS | SCENARIO
[System.Collections.ArrayList] $Script:ProgramInfo = New-Object System.Collections.ArrayList
# MSI
<#0#> $null = $Script:ProgramInfo.Add(@('HP Hotkey Support Gen1','https://metierclientstorage.blob.core.windows.net/hp-hotkey-support/HP%20Hotkey%20Support%20-%20G1.msi',$Local:InstallLocationHPHotkeysSupport,$Local:MSIInstallParameters,'3'))
<#1#> $null = $Script:ProgramInfo.Add(@('HP Hotkey Support Gen2','https://metierclientstorage.blob.core.windows.net/hp-hotkey-support/HP%20Hotkey%20Support%20-%20G2.msi',$Local:InstallLocationHPHotkeysSupport,$Local:MSIInstallParameters,'3'))
<#2#> $null = $Script:ProgramInfo.Add(@('HP Hotkey Support Gen3/4','https://metierclientstorage.blob.core.windows.net/hp-hotkey-support/HP%20Hotkey%20Support%20-%20G3%26G4.msi',$Local:InstallLocationHPHotkeysSupport,$Local:MSIInstallParameters,'3'))
# 7z compressed MSI
<#3#> $null = $Script:ProgramInfo.Add(@('HP Hotkey Support Gen1','https://metierclientstorage.blob.core.windows.net/hp-hotkey-support/HP%20Hotkey%20Support%20-%20G1.7z',$Local:InstallLocationHPHotkeysSupport,$Local:MSIInstallParameters,'4'))
<#4#> $null = $Script:ProgramInfo.Add(@('HP Hotkey Support Gen2','https://metierclientstorage.blob.core.windows.net/hp-hotkey-support/HP%20Hotkey%20Support%20-%20G2.7z',$Local:InstallLocationHPHotkeysSupport,$Local:MSIInstallParameters,'4'))
<#5#> $null = $Script:ProgramInfo.Add(@('HP Hotkey Support Gen3/4','https://metierclientstorage.blob.core.windows.net/hp-hotkey-support/HP%20Hotkey%20Support%20-%20G3%26G4.7z',$Local:InstallLocationHPHotkeysSupport,$Local:MSIInstallParameters,'4'))
# EXE
<#6#> $null = $Script:ProgramInfo.Add(@('Lenovo System Update','https://download.lenovo.com/pccbbs/thinkvantage_en/systemupdate5.07.0070.exe','C:\Program Files (x86)\Lenovo\System Update\','/SP- /VERYSILENT','0'))

# LINK 'PC MODEL GROUP' TO 'PROGRAM INFO'
# Index represents PC Model Group (Index of $PCModelGroups)
# The numbers represents which program(s) apply to the group (Index(es) of $ProgramInfo))
[String[]] $Script:LinkModelToPrograms = @('0','1','2','6')

#endregion Variables and Settings



#region Functions
    #region Write-DebugIfOn
    Function Write-DebugIfOn {
        param(
            [Parameter(Mandatory=$true)]
            [String] $In,

            [Parameter(Mandatory=$false)]
            [bool] $DeepDebug = $false
        )
        If (-not($DeepDebug)) {
            If ($DebugConsole) {
                Write-Output -InputObject $In
            }
            If ($DebugWinTemp) {
                $Script:DebugStr += ($In + "`r`n")
            }
        }
        Else {
            $Script:DeepDebugStr += ($In + "`r`n")
        }
    }
    #endregion Write-DebugIfOn


    #region Download-FileToWinTemp
    Function Download-FileToWinTemp {
        param(
            [Parameter(Mandatory=$true)]
            [String] $DLFileName, $DLURL,
            [Parameter(Mandatory=$false)]
            [uint16] $Increment = 6
        )

        [String] $DLPath = ($env:windir + '\Temp\')
        [String] $OutStr = [String]::Empty
        [bool] $DLSuccess = $false

        # First try Start-BitsTransfer
        $OutStr += ('{0}Downloading (Start-BitsTransfer)' -f (' ' * $Increment))
        [System.DateTime] $Local:StartTime = Get-Date
        $null = Start-BitsTransfer -Source $DLURL -Destination ($DLPath + $DLFileName) -ErrorAction SilentlyContinue
        If ($?) {
            $DLSuccess =  $true
        }
        Else {
            $OutStr += ("`r`n" + '        Failed!')                    
            
            # If Start-BitsTransfer fails, try System.Net.WebClient
            $OutStr += ("`r`n" + '{0}Downloading (System.Net.WebClient)' -f (' ' * $Increment))
            [System.DateTime] $Local:StartTime = Get-Date
            (New-Object System.Net.WebClient).DownloadFile($DLURL, ($DLPath + $DLFileName))
            If ($?) {
                $DLSuccess = $true
            }                                     
            Else {
                $OutStr += ("`r`n" + '{0}   Failed!' -f (' ' * $Increment))
                
                # If System.Net.WebClient fails, try Invoke-WebRequest
                $OutStr += ("`r`n" + '{0}Downloading (Invoke-WebRequest)' -f (' ' * $Increment))
                [System.DateTime] $Local:StartTime = Get-Date
                Invoke-WebRequest -Uri $DLURL -OutFile ($DLPath + $DLFileName)
                If ($?) {
                    $DLSuccess = $true
                }
                Else {
                    $OutStr += ("`r`n" + '{0}   Failed!' -f (' ' * $Increment))
                }
            } 
        }

        If ($DLSuccess) {
            $OutStr += ("`r`n" + '{0}   Download successful. It took {1} second(s)' -f ((' ' * $Increment),(Get-Date).Subtract($Local:StartTime).Seconds))
        }

        Return ($DLSuccess,$OutStr)  
    }
    #endregion Download-FileToWinTemp


    #region Install-ExeProg
    Function Install-ExeProg {
        param(
            [Parameter(Mandatory=$true)]
            [String] $ProgName, $InstallDir, $DLFileName, $InstallArgs, $DLURL
        )
        [String] $DLPath = ($env:windir + '\Temp\')

        # Check if installed
        Write-DebugIfOn -In ('  Checking if "' + $ProgName + '" is installed.')
        
        If (Test-Path -Path $Local:InstallDir) {
            If ($Script:TestRun) {
                Write-DebugIfOn -In '     TestRun, will pretend the program is not there'
            }
            Else {
                Write-DebugIfOn -In ('    "' + $ProgName + '" already installed.') 
                Continue
            }
        }
        Else {
            Write-DebugIfOn -In ('    "' + $ProgName + '" not installed. Downloading and installing.')
        }
        
        # If ReadOnly mode     
        If ($Script:ReadOnly -and (-not($Script:TestRun))) {
            Write-DebugIfOn -In ('      ReadOnly mode, did not attempt to install.')
        }

        # If Not ReadOnly
        Else {
            $Dl = Download-FileToWinTemp -DLFileName $DLFileName -DLURL $DLURL
            # Install if download success
            If ($Dl[0]) {
                Write-DebugIfOn $Dl[1]
                Write-DebugIfOn -In ('      Installing with: "' + ($DLPath + $DLFileName) + ' ' + $InstallArgs + '"')
                If (-not($Script:TestRun)) {
                    $null = Start-Process -FilePath ($DLPath + $DLFileName) -ArgumentList $InstallArgs -Wait
                    Write-DebugIfOn -In ('        Installer exit successfully? ' + $?)
                    
                    # Check if program actually got installed
                    Write-DebugIfOn -In ('          Program actually installed? {0}' -f (Test-Path $InstallDir))  
                }
                Else {
                    Write-DebugIfOn -In ('         TestMode, will not install')
                }                      
            }                        

            # Clean up if install file exists
            Write-DebugIfOn -In ('    Cleaning (Removing ' + $DLPath + $DLFileName + ')')
            $null = Remove-Item -Path ($DLPath + $DLFileName)
            Write-DebugIfOn -In ('      Success? ' + $?)
        }
    }
    #endregion Install-ExeProg


    #region Install-MSIProg
    Function Install-MSIProg {
        Param(
            [Parameter(Mandatory=$true)]
            [String] $ProgName, $InstallDir, $DLFileName, $InstallArgs, $DLURL
        )
        $InstallArgs = $InstallArgs.Replace('_',$DLFileName)
    }
    #endregion Install-MSIProg


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
        Param ([Parameter(Mandatory=$true)] [String] $Dir)
        $Local:Out = [String]::Empty
        [String] $Local:Key = $Dir.Split('{\}')[-1]
        [String] $Local:Dir = $Dir.Replace($Local:Key,'')
        
        $Local:Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Local:Key) -ErrorAction SilentlyContinue
        If ($Exists) {
            $Local:Out = $Local:Exists.$Local:Key
        }
        return $Local:Out
    }
    #endregion Query-Registry
#endregion Functions



#region Initialize
If ($DebugWinTemp -or $DebugConsole) {
    Get-MachineInfo
    Write-DebugIfOn -In '### Environment Info'
    Write-DebugIfOn -In ('Script settings: DebugConsole = "{0}", DebugWinTemp = "{1}", ReadOnly = "{2}", TestRun = "{3}"' -f ($DebugConsole,$DebugWinTemp,$Script:ReadOnly,$Script:TestRun))
    Write-DebugIfOn -In ('Machine info: Name = "{0}", Manufacturer = "{1}", Family = "{2}", Model = "{3}"' -f ($Script:ComputerName,$Script:ComputerManufacturer,$Script:ComputerFamily,$Script:ComputerProductName))
    Write-DebugIfOn -In ('Windows info: Edition = "{0}", Version = "{1}"' -f ($Script:WindowsEdition,$Script:WindowsVersion))
}
#endregion Initialize



#region Main
    Write-DebugIfOn -In ("`r`n" + '### ' + $WhatToConfig)
    $Local:ModelFound = $Local:ProgramsFound = $Local:ProgramsInstalled = [bool] $false

    #region Find Model
    Write-DebugIfOn -In ("`r`n" + '# Searching for model')
    If (-not($Script:ComputerName)) {Get-MachineInfo}
    [uint16] $Script:Category = 0
    :loop foreach ($Gen in $Script:PCModelGroups) {
        $Gen | ForEach-Object {
            [String] $Local:X = ('*{0}*' -f ($_))
            [bool] $Local:IsLike = ($Script:ComputerProductName -like $Local:X)
            If ($Script:DebugLevel -ge 1) {
                Write-DebugIfOn -DeepDebug $true -In ('   {0} -like {1} | {2}' -f ($Script:ComputerProductName,$Local:X,$Local:IsLike))
            }
            If ($Local:IsLike) {
                $Local:ModelFound = $true
                Write-DebugIfOn -In ('  Found it! "{0} -like {1}"' -f ($Script:ComputerModel,$Local:X))
                break :loop
            }
        }    
        $Script:Category += 1    
    }

    Write-DebugIfOn -In ('  Model found? {0}' -f ($ModelFound))
    #endregion Find Model


    #region Decide programs
    If ($Script:TestRun -or $Local:ModelFound) {
        Write-DebugIfOn -In ("`r`n" + '# Finding programs to install')   
        If ($Script:TestRun) {
            [System.Collections.ArrayList] $Script:ProgramsToInstall = $Script:ProgramInfo.Clone()
            Write-DebugIfOn -In ('  TestRun, will try all programs')
        }
        Else {   
            If ($Local:ModelFound) {
                [System.Collections.ArrayList] $Script:ProgramsToInstall = New-Object System.Collections.ArrayList
                $Local:C = [uint16]::MinValue
                $Script:LinkModelToPrograms[$Script:Category].Split('{,}') | ForEach-Object {
                    Write-DebugIfOn -In ('   Program number {0}' -f ($_))
                    $null = $Script:ProgramsToInstall.Add($Script:ProgramInfo[$_].Clone())
                    Write-DebugIfOn -In ('     Added "{0}"' -f ($Script:ProgramsToInstall[$Local:C]))
                    $Local:C += 1
                }
            }
        }
        $Local:CProgramsToInstall = [uint16]::MinValue
        If ($Script:ProgramsToInstall.Count -ge 1) {
            $Local:CProgramsToInstall = $Script:ProgramsToInstall.Count
            $Local:ProgramsFound = $true
        }
        Write-DebugIfOn -In ('  Found {0} programs to install' -f $Local:CProgramsToInstall)
    }
    #endregion Decide programs


    #region Install  
    If ($Script:ProgramsFound) {
        Write-DebugIfOn -In ("`r`n" + '# Installing programs')     
        [bool[]] $Script:InstallSuccess = @($false) * ($Script:ProgramsToInstall.Count)
        $C = [uint16]::MinValue

        foreach ($Prog in $Script:ProgramsToInstall) {
            $Local:Step = [uint16]::MinValue
            $Local:ProgName = $Local:DLURL = $Local:DLFileName = $Local:DLFilePath = $Local:InstallDir = $Local:InstallArgs = [String]::Empty
            Write-DebugIfOn -In ('###############################')


            ###############################
            # GET PROGRAM INFO
            Write-DebugIfOn -In ('  {0}. Getting program info' -f ($Local:Step += 1))         
            $Local:Scenario = [uint16] $Prog[-1]
            Write-DebugIfOn -In ('    Program Name:         {0}' -f ($Local:ProgramName = $Prog[0]))
            Write-DebugIfOn -In ('    Install scenario ({0}): {1}' -f ($Local:Scenario,$Script:ScenarioInfo[$Local:Scenario]))
            Write-DebugIfOn -In ('    Download URL:         {0}' -f ($Local:DLURL = $Prog[1]))
            Write-DebugIfOn -In ('    DL File Name:         {0}' -f ($Local:DLFileName = ($DLURL.Split('{/}')[-1]).Replace('%20',' ').Replace('%26','&')))
            Write-DebugIfOn -In ('    DL File Path:         {0}' -f ($Local:DLFilePath = ('{0}\Temp\{1}' -f ($env:windir,$Local:DLFileName))))
            Write-DebugIfOn -In ('    Install Dir:          {0}' -f ($Local:InstallDir = $Prog[2]))
            
            If (($Local:Scenario -eq 3) -or ($Local:Scenario -eq 4)) {
                [String] $Local:DLFileNameExtracted = $DLFileName.Replace('.7z','.msi')
                [String] $Local:DLFilePathExtracted = ('{0}\Temp\{1}' -f ($env:windir,$Local:DLFileNameExtracted))
                Write-DebugIfOn -In ('    Install Args:         {0}' -f ($Local:InstallArgs = ($Prog[3]).Replace('_','"{0}"' -f ($Local:DLFilePathExtracted)).Replace('msiexec.log',('msiexec{0}.log' -f ($C)))))
            }
            Else {
                Write-DebugIfOn -In ('    Install Args:         {0}' -f ($Local:InstallArgs = $Prog[3]))
            }

            
            ###############################
            # CHECK IF INSTALLED
            Write-DebugIfOn -In ('  {0}. Checking if program is installed' -f ($Local:Step += 1))
            If (Test-Path -Path $Local:InstallDir) {
                If ($Script:TestRun) {
                    Write-DebugIfOn -In '    TestRun, will pretend the program is not there'
                }
                Else {
                    Write-DebugIfOn -In '    Program is already installed. Next'
                    $InstallSuccess[$C] = $true
                    Continue
                }
            }
            Else {
                Write-DebugIfOn -In '    Program is not installed. Continuing.'
            }




            # SCENARIO 0-2  | EXE, EXE in 7z, EXE in Zip
            #region EXE - ALL
            If ($Local:Scenario -ge 0 -and $Local:Scenario -le 2) {
                #region Scenario 0 - Exe
                If ($Local:Scenario -eq 0) {
                    Install-ExeProg -ProgName $Local:ProgramName -InstallDir $Local:InstallDir -InstallArgs $Local:InstallArgs -DLFileName $Local:DLFileName -DLURL $DLURL
                    If ($? -or $Script:TestRun) {
                        $InstallSuccess[$C] = $true
                    }
                }
                #endregion Scenario 0 - Exe
            }
            #endregion EXE - ALL



            # SCENARIO 3-6 - MSI, MSI in 7z, MSI in ZIP, MSI in 7z from Azure Private Blob
            #region MSI - ALL
            ElseIf ($Local:Scenario -ge 3 -and $Local:Scenario -le 6) {
                
                $Local:SuccessDL = $Local:SuccessUnpack = $Local:SuccessInstall = [bool] $false
                If ($Local:Scenario -eq 3) {$Local:SuccessUnpack = $true}



                #region GENERIC MSI DOWNLOAD
                ###############################
                # DOWNLOAD
                Write-DebugIfOn -In ('  {0}. Downloading the install file.' -f ($Local:Step += 1)) 
                $null = Remove-Item -Path ($Local:DLFilePath) -Force -ErrorAction SilentlyContinue

                # OPEN BLOB
                If ($Local:Scenario -ne 6) {
                    $Local:DL = Download-FileToWinTemp -DLFileName $Local:DLFileName -DLURL $Local:DLURL -Increment 4
                    Write-DebugIfOn -In $Local:DL[1]
                    If ($Local:DL[0]) {$Local:SuccessDL = $true}
                }

                # PRIVATE BLOB
                Else {                   
                    $Local:BlobContext = New-AzureStorageContext -ConnectionString $Script:BlobKey[1]
                    [String] $Local:ContainerName = 'hp-hotkey-support'                     
                    $null = Get-AzureStorageBlobContent -Blob $Local:DLFileName `
                        -Container $Local:ContainerName `
                        -Destination $Local:DLFilePath `
                        -Context $Local:BlobContext -Force
                
                    # TEST DOWNLOADED FILE
                    If (Test-Path -Path $Local:DLFilePath) {
                        Write-DebugIfOn -In ('      Download successfull.')
                        If ((Get-Item $Local:DLFilePath).Length -gt 8MB) {
                            Write-DebugIfOn -In ('        File is larger than 8MB.')
                            $Local:SuccessDL = $true
                        }
                    }                
                }               
                #endregion GENERIC MSI DOWNLOAD



                #region SCENARIO 4 - MSI in 7z
                If ($Local:Scenario -eq 4) {
                    ###############################
                    # EXTRACT 7z
                    If ($Local:SuccessDL) { 
                        Write-DebugIfOn -In ('  {0}. Extracting the .7z to .msi.' -f ($Local:Step += 1))
                        If (-not($Script:7zPresent)) {
                            Write-DebugIfOn -In ('      ERROR: 7z.exe could not be found ("{0}")' -f ($Script:7z))
                            Continue
                        }
                        $null = Remove-Item -Path ($Local:DLFilePathExtracted) -Force -ErrorAction SilentlyContinue 
                        [String] $Local:Do = ('"{0}" e "{1}" -o"{2}"' -f($Script:7z,$Local:DLFilePath,($env:windir + '\Temp\')))
                        Write-DebugIfOn -In ('      Extracting:')
                        Write-DebugIfOn -In ('        {0}' -f ($Local:Do))
                        $null = cmd /c ('{0}' -f ($Local:Do))  
                        If ($?) {
                            If (Test-Path -Path $Local:DLFilePath) {                                          
                                Write-DebugIfOn ('          SUCCESS!')                        
                                $Local:SuccessUnpack = $true
                            }
                            Else {
                                Write-DebugIfOn ('          FAIL!')
                                Continue
                            }
                        }     
                    }
                }
                #endregion SCENARIO 4 - MSI in 7z



                #region SCENARIO 5 - MSI in ZIP
                ElseIf ($Local:Scenario -eq 5) {
                }
                #endregion SCENARIO 3 - MSI in ZIP



                #region GENERIC MSI INSTALL
                ###############################
                # INSTALL MSI
                If ($Local:SuccessUnpack) {
                    Write-DebugIfOn -In ('  {0}. Installing.' -f ($Local:Step += 1))
                    Write-DebugIfOn -In ('      cmd /c {0}' -f ($Local:InstallArgs))
                    If ($Script:ReadOnly -or $Script:TestRun) {
                        Write-DebugIfOn -In ('        ReadOnly or TestRun is on, will not install.')
                        $Local:SuccessInstall = $true
                    }
                    Else {
                        cmd /c ('{0}' -f $Local:InstallArgs)                   
                        [bool] $Local:InstallerExitStatus = $?
                        [bool] $Local:InstallPathExists = Test-Path -Path $Local:InstallDir
                        Write-DebugIfOn -In ('        Installer exit status: {0} | Test-Path Install Dir Exists: {1}' -f ($Local:InstallerExitStatus,$Local:InstallPathExists))
                        If (($Local:InstallerExitStatus) -or ($Local:InstallPathExists)) {                           
                            $Local:SuccessInstall = $true
                        }
                    }
                }    
                #endregion GENERIC MSI INSTALL                                            
            }
            #endregion MSI - ALL


            # Else
            Else {
                Write-DebugIfOn -In ('  FAIL: No scenario provided for "{0}"' -f ($Prog[0]))
            }
            

            ###############################
            # 5. CHECK SUCCESS
            Write-DebugIfOn ('  {0}. Checking for success.' -f ($Local:Step += 1))              
            If (($Local:Scenario -eq 3) -or ($Local:Scenario -eq 4)) {
                If (($Local:SuccessDL -eq $true) -and ($Local:SuccessUnpack -eq $true) -and ($Local:SuccessInstall -eq $true)) {                    
                    $Local:InstallSuccess[$C] = $true
                }
            }
            Else {
                If ($Local:SuccessInstall) {
                    $Local:InstallSuccess[$C] = $true
                }
            }

            If ($Script:InstallSuccess[$C]) {
                Write-DebugIfOn ('      Great success.')
            }
            Else {
                Write-DebugIfOn ('      Great fail.')
            }


            ###############################
            # CLEANING
            $null = Remove-Item -Path ($Local:DLFilePath) -Force -ErrorAction SilentlyContinue
            If ($Local:DLFilePathExtracted) {
                $null = Remove-Item -Path ($Local:DLFilePathExtracted) -Force -ErrorAction SilentlyContinue
            }


            # Icrement counter by 1
            $C += 1
        }
        
        

    }
    #endregion Install
    
    
    
    # SUCCESS?
    Write-DebugIfOn -In ('{0}# Checking for success' -f ("`r`n"))
    Write-DebugIfOn -In ('  Did this computer match any of the ones listed? {0}' -f ($Local:ModelFound))
    Write-DebugIfOn -In ('  Did the script find any programs for this computer? {0}' -f ($Local:ProgramsFound))
    If ($Local:ProgramsFound) {
        Write-DebugIfOn -In ('  Did all programs install successfully? {0}' -f ($Local:ProgramsInstalled))
        $Script:SuccessStr = [String]::Empty
        $Local:C = [uint16]::MinValue
        $Script:ProgramsInstalled = $true
        $Script:InstallSuccess | ForEach-Object {
            $Local:SuccessStr += ('    "{0}" : {1}' -f ($Script:ProgramsToInstall[$Local:C][0],$_.ToString()))
            If (-not($_)) {
                $Local:ProgramsInstalled = $false            
            }
            $Local:C += 1
            If ($Script:ProgramsToInstall.Count -gt $Local:C) {
                $Local:SuccessStr += "`r`n"
            }
        }
        Write-DebugIfOn -In ($Script:SuccessStr)
    }
        

    



    #Done
    Write-DebugIfOn -In ("`r`n" + 'Done.')
#endregion Main



#region Debug
If ($DebugConsole -and ($Script:DebugLevel -ge 1)) {
    Write-DebugIfOn -In ($Script:DeepDebugStr)
    $Script:DebugStr += $Script:DeepDebugStr
}
If ($DebugWinTemp) {
    If ([String]::IsNullOrEmpty($Script:DebugStr)) {
        $Script:DebugStr = 'Everything failed'
    }

    ### Write Output
    # Get variables
    $Local:DirLog = ('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration\' -f ($env:SystemDrive))
    $Local:NameScriptFile = $Script:WhatToConfig
    $Local:CurTime = Get-Date -Uformat '%y%m%d%H%M%S'
    
    # Create log file name
    $Local:DebugFileName = ('{0} {1}.txt' -f ($Local:NameScriptFile,$Local:CurTime))

    # Check if log destination exists, or else: Create it
    If (-not(Test-Path -Path $DirLog)) {
        $null = New-Item -Path $DirLog -Force -ItemType Directory
    }
    $Script:DebugStr | Out-File -FilePath ($Local:DirLog + $Local:DebugFileName) -Encoding 'utf8'
}
#endregion Debug
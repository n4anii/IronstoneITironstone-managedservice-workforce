#Requires -RunAsAdministrator


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
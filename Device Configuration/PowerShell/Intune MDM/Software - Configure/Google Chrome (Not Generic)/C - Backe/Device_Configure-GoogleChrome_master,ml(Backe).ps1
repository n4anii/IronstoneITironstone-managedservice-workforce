<#

.SYNOPSIS


.DESCRIPTION


.NOTES
You need to run this script in the DEVICE context in Intune.

#>


# Script Variables
$DeviceContext = [bool]   $true
$NameScript    = [string] 'Configure-GoogleChrome(Backe)'

# Settings - PowerShell - Output Preferences
$DebugPreference       = 'SilentlyContinue'
$VerbosePreference     = 'SilentlyContinue'
$WarningPreference     = 'Continue'

#region    Don't Touch This
# Settings - PowerShell - Interaction
$ConfirmPreference     = 'None'
$InformationPreference = 'SilentlyContinue'
$ProgressPreference    = 'SilentlyContinue'

# Settings - PowerShell - Behaviour
$ErrorActionPreference = 'Continue'

# Dynamic Variables - Process & Environment
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'NameScriptFull' -Value ([string]('{0}_{1}' -f ($(if($DeviceContext){'Device'}else{'User'}),$NameScript)))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'NameScriptVerb' -Value ([string]$NameScript.Split('-')[0])
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'NameScriptNoun' -Value ([string]$NameScript.Split('-')[-1])
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrArchitectureProcess' -Value ([string]$(if([System.Environment]::Is64BitProcess){'64'}else{'32'}))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrArchitectureOS' -Value ([string]$(if([System.Environment]::Is64BitOperatingSystem){'64'}else{'32'}))

# Dynamic Variables - User
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsAdmin'  -Value ([bool]$([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsSystem' -Value ([bool]$(([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)) -eq ([string]('S-1-5-18'))))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsCorrectUser' -Value ([bool]$(if($Script:DeviceContext -and $Script:BoolIsSystem){$true}elseif((-not($DeviceContext)) -and (-not($Script:BoolIsSystem))){$true}else{$false}))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrUserNameRunningAs' -Value ([string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrUserIntuneSID' -Value ([string]$(if($Script:BoolIsSystem){[string]([string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]}) | Where-Object {@(Get-ChildItem -Path ('Registry::\HKEY_Users\{0}\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC' -f ($_)) -Recurse:$false -ErrorAction 'SilentlyContinue').Count -eq 1})}else{[string]([System.Security.Principal.NTAccount]::new([string]('{0}\{1}' -f ($env:USERDOMAIN,$env:USERNAME))).Translate([System.Security.Principal.SecurityIdentifier]).Value)}))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrUserIntuneName' -Value ([string]$(if($Script:BoolIsSystem){([System.Security.Principal.SecurityIdentifier]::new($Script:StrUserIntuneSID).Translate([System.Security.Principal.NTAccount]).Value)}else{[string]('{0}\{1}' -f ($env:USERDOMAIN,$env:USERNAME))}))

# Dynamic Variables - Logging
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'Timestamp' -Value ([string]$([datetime]::Now.ToString('yyMMdd-HHmmssffff')))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'PathDirLog' -Value ([string]$('{0}\IronstoneIT\Intune\DeviceConfiguration\' -f ([string]$(if($DeviceContext -and $Script:BoolIsCorrectUser -and $Script:BoolIsAdmin){$env:ProgramW6432}elseif($Script:BoolIsSystem -and (-not($Script:BoolIsCorrectUser))){[string](Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Volatile Environment' -f ($Script:StrUserIntuneSID)) -Name 'APPDATA' | Select-Object -ExpandProperty 'APPDATA')}else{$env:APPDATA}))))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'PathFileLog' -Value ([string]$('{0}{1}-{2}bit-{3}.txt' -f ($PathDirLog,$NameScriptFull,$StrArchitectureProcess,$Script:Timestamp)))

# Start Transcript
if (-not(Test-Path -Path $Script:PathDirLog)) {$null = New-Item -ItemType 'Directory' -Path $Script:PathDirLog -ErrorAction 'Stop'}
Start-Transcript -Path $Script:PathFileLog -ErrorAction 'Stop'


# Wrap in Try/Catch, so we can always end the transcript
Try {
    # Output User Info, Exit if not $BoolIsCorrectUser
    Write-Output -InputObject ('Running as user "{0}". Has admin privileges? {1}. $DeviceContext = {2}. Running as correct user? {3}.' -f ($Script:StrUserNameRunningAs,$Script:BoolIsAdmin.ToString(),$Script:DeviceContext.ToString(),$Script:BoolIsCorrectUser.ToString()))
    if (-not($Script:BoolIsCorrectUser)){Throw 'Not running as correct user!'; Break}

    # Output Process and OS Architecture Info
    Write-Output -InputObject ('PowerShell is running as a {0} bit process on a {1} bit OS.' -f ($Script:StrArchitectureProcess,$Script:StrArchitectureOS))

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
    

    # Only continue if Chrome is not configured already
    if (Test-Path -Path ('{0}\Google\Chrome\Application\' -f (${env:ProgramFiles(x86)}, ${env:ProgramFiles} -ne $null)[0])) {
        Write-Output -InputObject 'Chrome is already installed, will skip installing master_preferences.'
    }
    
    #region    If Chrome not installed already
    else {
        #region    Initialize - Settings and Variables
            # Settings
            [bool] $ReadOnly = $false
            $VerbosePreference = 'Continue'

            #region    Variables - Case Specific              
                # Sync Folder
                [string] $PathDirInstall = ('{0}\Google\Chrome\Application' -f (${env:ProgramFiles(x86)}, ${env:ProgramFiles} -ne $null)[0])               
                #region     Install Files
                    [PSCustomObject[]] $InstallFiles = @(
                        [PSCustomObject[]]@{Name=([string]'master_preferences' -f ($NameScript));
                                            Encoding=[string]'utf8';
                                            Content=[string]'ewogICJob21lcGFnZSI6ICJodHRwczovL2JhY2tlLmZhY2Vib29rLmNvbSIsCiAgImhvbWVwYWdlX2lzX25ld3RhYnBhZ2UiOiBmYWxzZSwKICAiYnJvd3NlciI6IHsKICAgICJjaGVja19kZWZhdWx0X2Jyb3dzZXIiOiBmYWxzZSwKCSJoYXNfc2Vlbl93ZWxjb21lX3BhZ2UiOiB0cnVlLAoJInNob3dfaG9tZV9idXR0b24iOiB0cnVlLAoJInNob3dfdXBkYXRlX3Byb21vdGlvbl9pbmZvX2JhciI6IGZhbHNlCiAgfSwKICAic2Vzc2lvbiI6IHsKICAgICJyZXN0b3JlX29uX3N0YXJ0dXAiOiA0LAogICAgInN0YXJ0dXBfdXJscyI6IFsiaHR0cHM6Ly9iYWNrZS5mYWNlYm9vay5jb20iXQogIH0sCiAgImJvb2ttYXJrX2JhciI6IHsKICAgICJzaG93X29uX2FsbF90YWJzIjogZmFsc2UKICB9LAogICJzeW5jX3Byb21vIjogewogICAgInNob3dfb25fZmlyc3RfcnVuX2FsbG93ZWQiOiBmYWxzZSwKCSJ1c2VyX3NraXBwZWQiOiB0cnVlCiAgfSwKICAiZGlzdHJpYnV0aW9uIjogewogICAgImFsbG93X2Rvd25ncmFkZSI6IGZhbHNlLAoJImNyZWF0ZV9hbGxfc2hvcnRjdXRzIjogdHJ1ZSwKCSJkb19ub3RfY3JlYXRlX2Rlc2t0b3Bfc2hvcnRjdXQiOiBmYWxzZSwKICAgICJkb19ub3RfY3JlYXRlX3F1aWNrX2xhdW5jaF9zaG9ydGN1dCI6IGZhbHNlLAogICAgImRvX25vdF9sYXVuY2hfY2hyb21lIjogdHJ1ZSwKICAgICJkb19ub3RfcmVnaXN0ZXJfZm9yX3VwZGF0ZV9sYXVuY2giOiB0cnVlLAoJImltcG9ydF9ib29rbWFya3MiOiBmYWxzZSwKICAgICJpbXBvcnRfaGlzdG9yeSI6IGZhbHNlLAogICAgImltcG9ydF9ob21lX3BhZ2UiOiBmYWxzZSwKICAgICJpbXBvcnRfc2VhcmNoX2VuZ2luZSI6IGZhbHNlLAogICAgIm1ha2VfY2hyb21lX2RlZmF1bHQiOiBmYWxzZSwKICAgICJtYWtlX2Nocm9tZV9kZWZhdWx0X2Zvcl91c2VyIjogZmFsc2UsCiAgICAibXNpIjogdHJ1ZSwJCgkicGluZ19kZWxheSI6IDYwLAoJInNob3dfd2VsY29tZV9wYWdlIjogZmFsc2UsCgkic2tpcF9maXJzdF9ydW5fdWkiOiB0cnVlLAoJInN1cHByZXNzX2RlZmF1bHRfYnJvd3Nlcl9wcm9tcHRfZm9yX3ZlcnNpb24iOiB0cnVlLAoJInN1cHByZXNzX2ZpcnN0X3J1bl9kZWZhdWx0X2Jyb3dzZXJfcHJvbXB0IjogdHJ1ZSwKICAgICJzdXBwcmVzc19maXJzdF9ydW5fYnViYmxlIjogdHJ1ZSwgIAoJInN5c3RlbV9sZXZlbCI6IHRydWUsCgkidmVyYm9zZV9sb2dnaW5nIjogdHJ1ZQogIH0sCiAgImZpcnN0X3J1bl90YWJzIjogWyJodHRwczovL2JhY2tlLmZhY2Vib29rLmNvbSJdCn0=';}
                    )
                #endregion Install Files                
            #endregion Variables - Case Specific
        #endregion Initialize - Settings and Variables




        #region    Functions
            #region    FileOut-FromBase64
                Function FileOut-FromBase64 {
                    [CmdLetBinding()]

                    # Parameters
                    Param(
                        [Parameter(Mandatory=$true)]
                        [ValidateNotNullOrEmpty()]
                        [string] $PathDirOut,
            
                        [Parameter(Mandatory=$true)]
                        [ValidateNotNullOrEmpty()]
                        [string] $NameFileOut,
            
                        [Parameter(Mandatory=$true)]
                        [ValidateNotNullOrEmpty()]
                        [string] $ContentFileOut, 
            
                        [Parameter(Mandatory=$true)]
                        [ValidateSet('utf8','default')]
                        [string] $EncodingFileOut,

                        [Parameter(Mandatory=$false)]
                        [Switch] $Force
                    )

                    # Output Debug Info
                    [byte] $SubstringLength = $(if($ContentFileOut.Length -lt 10){$ContentFileOut.Length}else{10})
                    Write-Debug -Message ('FileOut-FromBase64 -PathDirOut "{0}" -NameFileOut "{1}" -ContentFileOut "{2}" -EncodingFileOut "{3}"' -f ($PathDirOut,$NameFileOut,($ContentFileOut.Substring(0,$SubstringLength)+'...'),$EncodingFileOut))
        

                    # If writing to Program Files, and not admin
                    if ($PathDirOut -like '*Program Files\*' -and (-not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
                        Throw ('Cannot write to "{0}" without admin rights!' -f ($PathDirOut))
                    }
                    else {
                        # Create Install Dir if not exist
                        if(-not(Test-Path -Path $PathDirOut)){New-Item -Path $PathDirOut -ItemType 'Directory' -Force}
                
                        # Continue only if Install Dir exist    
                        if (Test-Path -Path $PathDirOut) {
                            [string] $Local:PathFileOut = ('{0}{1}{2}' -f ($PathDirOut,($(if($PathDirOut[-1] -ne '\'){'\'})) + $NameFileOut)).Replace('\\','\')
                            Write-Verbose -Message ('   Path exists, trying to write the file (File alrady exists? {0}).' -f (Test-Path -Path $Local:PathFileOut))
                            if (-not($ReadOnly)) {
                                Out-File -FilePath $Local:PathFileOut -Encoding $EncodingFileOut -InputObject ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($ContentFileOut))) -Force:$Force
                                Write-Verbose -Message ('      Success? {0}.' -f ($?))
                                Write-Verbose -Message ('         Does file actually exist? {0}.' -f (Test-Path -Path $Local:PathFileOut -ErrorAction 'SilentlyContinue'))
                            }
                        }
                        else {
                            Throw ('ERROR: Install Path does not exist.')
                        }
                    }
                }
            #endregion FileOut-FromBase64



            #region    Write-ReadOnly
            function Write-ReadOnly {Write-Verbose -Message ('ReadOnly = {0}, will not write any changes.' -f ($ReadOnly))}
            #endregion Write-ReadOnly
        #endregion Functions




        #region    Create Install Folder     
            foreach ($Dir in $PathDirInstall) {
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
        #endregion Create Install Folder 



        #region    Install Files
            foreach ($File in $InstallFiles) {
                Write-Verbose -Message ('Installing file "{0}"' -f ($File.Name))
                if ($ReadOnly) {Write-ReadOnly}
                else { 
                    # Install
                    FileOut-FromBase64 -PathDirOut $PathDirInstall -NameFileOut $File.Name -ContentFileOut $File.Content -EncodingFileOut $File.Encoding
                    Write-Verbose -Message ('Install success? {0}' -f ($?))
                    # Set Read Only
                    (Get-Item ('{0}\{1}' -f ($PathDirInstall,$File.Name)) -Force).Attributes = 'ReadOnly, Archive'
                    Write-Verbose -Message ('Setting "Read Only" success? {0}' -f ($?))
                }
            }
        #endregion Install Files
    }
    #endregion If Chrome not installed already




    #region    Configure Chrome Policies in Registry
        Write-Verbose -Message 'Setting registry values.'
        if ($ReadOnly) {Write-ReadOnly}
        else {
            [string] $Dir      = 'HKLM:\Software\Policies\Google\Chrome\'
            #[string] $HomePage = '"https://backe.facebook.com"'        # Is set using master_preferences
            

            # HKCU if Both = $True
            if ([bool] $Script:BothHKLM_HKCU = $false) {
                # Get Current User as SecurityIdentifier
                [string] $PathDirRootCU = ('HKU:\{0}\' -f ([System.Security.Principal.NTAccount]::new((Get-Process -Name 'Explorer' -IncludeUserName).UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value))
                # Add HKU:\ as PSDrive if not already
                if ((Get-PSDrive -Name 'HKU' -ErrorAction 'SilentlyContinue') -eq $null) {$null = New-PSDrive -PSProvider 'Registry' -Name 'HKU' -Root 'HKEY_USERS'}
            }
          

            # Registry variables - General Settings
            [PSCustomObject[]] $RegValues = @(
                [PSCustomObject]@{Dir=$Dir;Key=[string]'BackgroundModeEnabled';        Val=[byte]0;           Type=[string]'DWord'}, 
                [PSCustomObject]@{Dir=$Dir;Key=[string]'DefaultBrowserSettingEnabled'; Val=[byte]0;           Type=[string]'DWord'},              
                [PSCustomObject]@{Dir=$Dir;Key=[string]'HomepageLocation';             Val=[string]$HomePage; Type=[string]'String'},               
                [PSCustomObject]@{Dir=$Dir;Key=[string]'HomepageIsNewTabPage';         Val=[byte]0;           Type=[string]'DWord'},
                [PSCustomObject]@{Dir=$Dir;Key=[string]'WelcomePageOnOSUpgradeEnabled';Val=[byte]0;           Type=[string]'DWord'}                 
            )


            # Registry variables - RestoreOnStartupURLs
            <# Does not work           
            $DirRestoreOnStartupURLs = ('{0}RestoreOnStartupURLs\' -f ($Dir))
            [string[]] $RestoreOnStartupURLs = @('"http://intranett/Sider/hjem.aspx"','"https://backe.facebook.com"')
            $C = [byte]::MinValue+1
            foreach ($URL in $RestoreOnStartupURLs) {
                $RegValues += @([PSCustomObject]@{Dir=$DirRestoreOnStartupURLs;Key=([string]'{0}' -f ($C++));Val=[string]$URL;Type=[string]'String'})
            } 
            #>

            

            # Set registry variables
            foreach ($Item in $RegValues) {           
                Write-Verbose -Message ('{0}' -f ($Item.Dir))
                
                # Create path if it does not exist
                if (-Not(Test-Path -Path $Item.Dir)) {                
                    $null = New-Item -Path $Item.Dir -ItemType 'Directory' -Force
                    Write-Verbose -Message ('   Path does not exist, creating it. Success? {0}' -f ($?))
                }
            
                # Create key and set value HKLM
                Set-ItemProperty -Path $Item.Dir -Name $Item.Key -Value $Item.Val -Type $Item.Type -Force
                Write-Verbose -Message ('   Key: {0} | Value: {1} | Type: {2} | Success? {3}' -f ($Item.Key,$Item.Val,$Item.Type,$?))

                # Create key and set value HKCU
                if ($BothHKLM_HKCU) {
                    [string] $DirHKCU = $Item.Dir.Replace('HKLM:\','HKCU:\')
                    Write-Verbose -Message ('{0}' -f ($PathDirRootCU))
                    Set-ItemProperty -Path $DirHKCU -Name $Item.Key -Value $Item.Val -Type $Item.Type -Force
                    Write-Verbose -Message ('   Key: {0} | Value: {1} | Type: {2} | Success? {3}' -f ($Item.Key,$Item.Val,$Item.Type,$?))
                }
            }
        }   
    #endregion Configure Chrome Policies in Registry



    

################################################
#endregion Your Code Here
################################################   
#region    Don't touch this
}
Catch {
    # Construct Message
    $ErrorMessage = [string]('{0} finished with errors:' -f ($Script:NameScriptFull))
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
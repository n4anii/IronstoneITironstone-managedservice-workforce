<#
.SYNOPSIS
Configures generic trusted sites for Windows / Internet Explorer. 
Adds common Microsoft domains, to make sure SSO works smooth.


.DESCRIPTION
Configures generic trusted sites for Windows / Internet Explorer. 
Adds common Microsoft domains, to make sure SSO works smooth.


.AUTHOR
Olav R. Birkeland


.CHANGELOG
180601
- Implement new Ironstone Intune MDM PowerShell Template
- Major rewrite, removed unneccesary functions
180420
- Initial Release


.RESOURCES
    * O365 Internet Explorer Protected Mode and security zones
      https://blogs.technet.microsoft.com/victorbutuza/2016/06/20/o365-internet-explorer-protected-mode-and-security-zones/

.TODO

#>


# Script Variables
[bool]   $DeviceContext = $true
[string] $NameScript    = 'Add-IETrustedSites_Microsoft'

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
[string] $StrIsAdmin       = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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
    if ( (-not([System.Environment]::Is64BitProcess))  -and [System.Environment]::Is64BitOperatingSystem) {
        write-Output -InputObject (' * Will restart this PowerShell session as x64.')
        if ($myInvocation.Line) {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
        }
        else {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -File ('{0}' -f ($myInvocation.InvocationName)) $args
        }
        exit $lastexitcode
    }
    
    # End the Initialize Region
    Write-Output -InputObject ('**********************')
#endregion Don't Touch This
################################################
#region    Your Code Here
################################################


    # Settings
    $VerbosePreference = 'Continue'


    #region    Get Current User + New PS Drive for HKU
        # Get Current User as SecurityIdentifier
        if (-not($Script:PathDirRootCU)){
            [string] $Script:PathDirRootCU = ('HKU:\{0}\' -f ([System.Security.Principal.NTAccount]::new(@(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value))
            if((-not($?)) -or [string]::IsNullOrEmpty($Script:PathDirRootCU) -or $Script:PathDirRootCU -like '*\\*'){Throw 'ERROR: Must be admin to get username from Get-Process.';Break}
        }
        # Add HKU:\ as PSDrive if not already
        if ((Get-PSDrive -Name 'HKU' -ErrorAction SilentlyContinue) -eq $null) {$null = New-PSDrive -PSProvider Registry -Name 'HKU' -Root 'HKEY_USERS'}
        if ((Get-PSDrive -Name 'HKU' -ErrorAction SilentlyContinue) -eq $null) {Throw 'ERROR: Could not add "HKEY_USERS" as PSDrive.'}
    #endregion Get Current User + New PS Drive for HKU


    # Domains, add 'https://*.lync.com' as 'lync.com' in the list 
    [string[]] $Domains = @('lync.com',
                            'microsoftonline.com',
                            'microsoftstream.com'
                            'office.com',
                            'office365.com',
                            'outlook.com',
                            'powerapps.com',
                            'sharepoint.com',
                            'sway.com'
                           )
    

    # Registry directories
    [string[]] $Paths = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\{0}',
                          'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\{0}\www',
                          '{0}Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\{1}',
                          '{0}Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\{1}\www')
    

    # Only HTTPS will be trusted
    [string]   $Name  = 'https'
    [byte]     $Value = 2
    

    # Set registry values
    foreach ($Path in $Paths) {
        foreach ($Domain in $Domains) {                      
            # Create Path Dynamically
            [string] $PathDynamic = ($(if($Path -like 'HKLM:\*'){$Path -f ($Domain)}else{$Path -f ($Script:PathDirRootCU,$Domain)}))
            $PathDynamic = $PathDynamic.Replace('\\','\')
            Write-Verbose -Message ('Path: "{0}".' -f ($PathDynamic))

            # Check that $TempPath is valid
            if ($PathDynamic -notlike 'HK*:\*' -or $PathDynamic -like '*:*:*' -or $PathDynamic -like '*\\*' -or $PathDynamic.Split(':')[0].Length -gt 4){
                Throw 'Not a valid path! Will not continue'
            }

            # Check if $TempPath exist, create it if not
            if (-not(Test-Path -Path $PathDynamic)){
                $null = New-Item -Path $PathDynamic -ItemType 'Directory' -Force
                Write-Verbose -Message ('   Path did not exist. Successfully created it? {0}.' -f ($?.ToString()))
            }
            
            # Set-ItemProperty
            Set-ItemProperty -Path $PathDynamic -Name $Name -Value $Value -Type 'DWord' -Force
            Write-Verbose -Message ('Set-ItemProperty -Path "{0}" -Name "{1}" -Value "{2}" -Type "DWord" -Force{3}   Success? {4}.' -f ($PathDynamic,$Name,$Value,"`r`n",$?.ToString()))

            # Write out success
            Write-Output -InputObject ('{0}: Adding "{1}://{2}*.{3}" to InternetExplorer Trusted Sites. Success? {4}' -f ($PathDynamic.Split(':')[0],$Name,$(if($PathDynamic.Split('\')[-1] -eq 'www'){'www'}),$Domain,$?.ToString()))
        }
    }



################################################
#endregion Your Code Here
################################################   
#region    Don't touch this
}
Catch {
    # Construct Message
    $ErrorMessage = ('{0} finished with errors:' -f ($NameScriptFull))
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
#endregion Don't touch this
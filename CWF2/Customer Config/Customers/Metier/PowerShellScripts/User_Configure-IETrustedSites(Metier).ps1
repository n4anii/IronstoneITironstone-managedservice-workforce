<#

.SYNOPSIS


.DESCRIPTION


.NOTES
You need to run this script in the USER context in Intune.

#>

$AppName = 'User_Configure-IETrustedSites(Metier)'
$Timestamp = Get-Date -Format 'HHmmssffff'
$LogDirectory = ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f $env:APPData)
$Transcriptname = ('{2}\{0}_{1}.txt' -f $AppName, $Timestamp, $LogDirectory)
$ErrorActionPreference = 'continue'

if (!(Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -ErrorAction Stop
}

Start-Transcript -Path $Transcriptname


#Wrap in a try/catch, so we can always end the transcript
Try {
    
    #region    Code Goes Here
    ##############################
        #region    Settings, Variables
            # PowerShell Settings
            $VerbosePreference = 'Continue'
            $ErrorActionPreference = 'Continue'
            $WarningPreference = 'Continue'
        #endregion Settings, Variables
    

        # Add IE Trusted Domain 'https://metiero365.sharepoint.com'
        Write-Verbose -Message '# Add IE Trusted Domains.'
        [string] $Domain     = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\sharepoint.com\metiero365\'
        [string] $Protocol   = 'https'
        [byte]   $TrustLevel = 2
        # Create dir
        Write-Verbose -Message ('New-Item -Path {0} -ItemType Directory -Force' -f ($Domain))
        $null = New-Item -Path $Domain -ItemType Directory -Force
        Write-Verbose -Message ('   Success? {0}' -f ($?))
        # Create Item
        Write-Verbose -Message ('Set-ItemProperty -Path {0} -Name {1} -Value {2} -Type DWord -Force' -f ($Domain,$Protocol,$TrustLevel))
        $null = Set-ItemProperty -Path $Domain -Name $Protocol -Value $TrustLevel -Type DWord -Force
        Write-Verbose -Message ('   Success? {0}' -f ($?)) 


        # Clean up previous scripts
        Write-Verbose -Message '# Remove previous configs.'
        [string[]] $PathsDirRemove = @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\metiero365.sharepoint.com')
        foreach ($Dir in $PathsDirRemove) {
            if (Test-Path -Path $Dir) {
                Write-Verbose -Message ('Remove-Item -Path {0} -Recurse -Force -ErrorAction SilentlyContinue' -f ($Dir))
                $null = Remove-Item -Path $Dir -Recurse -Force -ErrorAction SilentlyContinue
                Write-Verbose -Message ('   Success? {0}' -f ($?))
            }
            else {
                Write-Verbose -Message ('{0} does not exist' -f ($Dir))
            }
        }
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
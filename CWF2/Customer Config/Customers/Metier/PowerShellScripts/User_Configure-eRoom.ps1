<#

.SYNOPSIS


.DESCRIPTION


.NOTES
You need to run this script in the USER context in Intune.

#>

$AppName = 'User_Configure-eRoom'
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
    
    
        # Add IE Compatibility list
        Write-Verbose -Message '# Add IE Compatibility List.'
        [string] $Dir1 = 'HKCU:\Software\Microsoft\Internet Explorer\BrowserEmulation\ClearableListData'
        [string] $Key1 = 'userfilter'
        [string] $Val1 = '41,1f,00,00,53,08,ad,ba,01,00,00,00,42,00,00,00,01,00,00,00,01,00,00,00,0c,00,00,00,26,6e,d1,c5,2e,89,d3,01,01,00,00,00,12,00,70,00,72,00,6f,00,73,00,6a,00,65,00,6b,00,74,00,68,00,6f,00,74,00,65,00,6c,00,6c,00,2e,00,63,00,6f,00,6d,00'
        [byte[]] $ValByte = @($Val1.Split(',') | ForEach-Object {('0x{0}' -f ($_))})
        # Create Dir
        Write-Verbose -Message ('New-Item -Path {0} -ItemType Directory -Force' -f ($Dir1))
        $null = New-Item -Path $Dir1 -ItemType Directory -Force
        Write-Verbose -Message ('   Success? {0}' -f ($?))
        # Create Item
        Write-Verbose -Message ('Set-ItemProperty -Path {0} -Name {1} -Value $ValByte -Type Binary -Force' -f ($Dir1,$Key1))
        $null = Set-ItemProperty -Path $Dir1 -Name $Key1 -Value $ValByte -Type Binary -Force
        Write-Verbose -Message ('   Success? {0}' -f ($?)) 


        # Add IE Trusted Domain 'joint.prosjekthotell.com'
        Write-Verbose -Message '# Add IE Trusted Domains.'
        [string]   $Domain     = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\prosjekthotell.com\'
        [string[]] $SubDomains = @('joint','joint1','joint2','joint3','joint4','joint5','joint*')
        [string]   $Protocol   = 'https'
        [byte]     $TrustLevel = 2
        # Create dir
        Write-Verbose -Message ('New-Item -Path {0} -ItemType Directory -Force' -f ($Domain))
        $null = New-Item -Path $Domain -ItemType Directory -Force
        Write-Verbose -Message ('   Success? {0}' -f ($?))
        foreach ($SubDomain in $SubDomains) {
            [string] $TempPath = ('{0}{1}\' -f ($Domain,$SubDomain))
            # Create reg dir
            Write-Verbose -Message ('New-Item -Path {0} -ItemType Directory -Force' -f ($TempPath))
            $null = New-Item -Path $TempPath -ItemType Directory -Force
            Write-Verbose -Message ('   Success? {0}' -f ($?))
            # Create Item
            Write-Verbose -Message ('Set-ItemProperty -Path {0} -Name {1} -Value {2} -Type DWord -Force' -f ($TempPath,$Protocol,$TrustLevel))
            $null = Set-ItemProperty -Path $TempPath -Name $Protocol -Value $TrustLevel -Type DWord -Force
            Write-Verbose -Message ('   Success? {0}' -f ($?)) 
        }


        # Clean up previous scripts
        Write-Verbose -Message '# Remove previous configs.'
        [string[]] $PathsDirRemove = @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\prosjekthotell.com\www\',
                                       'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\joint.prosjekthotell.com\')
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
<#PSScriptInfo 
.VERSION 1.7
.GUID f5187e3f-ed0a-4ce1-b438-d8f421619ca3 
.ORIGINAL AUTHOR Jan Van Meirvenne 
.MODIFIED BY Sooraj Rajagopalan, Paul Huijbregts, Pieter Wigleven & Niall Brady (windows-noob.com 2017/8/17)
.COPYRIGHT 
.TAGS Azure Intune BitLocker  
.LICENSEURI  
.PROJECTURI  
.ICONURI  
.EXTERNALMODULEDEPENDENCIES  
.REQUIREDSCRIPTS  
.EXTERNALSCRIPTDEPENDENCIES  
.RELEASENOTES  
#>

<# 
 
.DESCRIPTION 
 Check whether BitLocker is Enabled, if not Enable BitLocker on AAD Joined devices and store recovery info in AAD 
 Added logging
#> 

[cmdletbinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $OSDrive = $env:SystemDrive
)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Function LogWrite {
    Param ([string]$logstring)
    $a = Get-Date
    $logstring = $a, $logstring
    Add-content $Logfile -value $logstring
    Write-host $logstring
}

Function LogErrors {
    LogWrite "Caught an exception:"
    LogWrite "Exception Type: $($_.Exception.GetType().FullName)"
    LogWrite "Exception Message: $($_.Exception.Message)"
}

# Settings
[bool] $GUI = $false
[bool] $IsEncrypted = [bool] $IsProtectionPassw = [bool] $IsBackupOD = [bool] $IsBackupAAD = $false
$Logfile = "C:\Windows\Temp\TriggerBitLocker.log"
LogWrite "Starting Trigger BitLocker script."

#### Global Variables Created at runtime
## Tenant
$Local:ID = (Get-ChildItem Cert:\LocalMachine\My\ | Where-Object { $_.Issuer -match 'CN=MS-Organization-Access' }).Subject.Replace('CN=','')
[String] $Global:NameTenant = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$($Local:ID)).UserEmail.Split('@')[1]
[String] $Global:NameTenantShort = $Global:NameTenant.Split('.')[0]
## Others
[String] $Script:ScheduledTaskName = 'BitLockerTrigger'


####################
#### ENCRYPTION ####
####################
LogWrite ('### BitLocker Encryption')
# Get encryption status
[Microsoft.BitLocker.Structures.BitLockerVolume] $BitLockStatus = Get-BitLockerVolume $OSDrive
[String] $VolumeEncSatus = ($BitLockStatus | Select-Object -Property VolumeStatus).VolumeStatus
LogWrite ('# Encryption')
Logwrite ('Status of OS drive (' + $OSDrive + ') = ' + $VolumeEncSatus)
try {
    # Encrypt if not FullyEncrypted
    if ($VolumeEncStatus -eq 'FullyDecrypted') {
        LogWrite ('Attempting to Enable BitLocker on OS drive ({0})' -f ($OSDrive))
        # Enable BitLocker using TPM
        Enable-BitLocker -MountPoint $OSDrive -TpmProtector -ErrorAction Stop
        If ($?) {
            $IsEncrypted = $true
        }
        Logwrite ('Success Enabling BitLocker? {0}' -f ($IsEncrypted))
    } else {
        $IsEncrypted = $true
    }
} 
catch {
    LogErrors
    Enable-BitLocker -MountPoint $OSDrive -TpmProtector -ErrorAction SilentlyContinue
    If ($?) {
        $IsEncrypted = $true
    }
    LogWrite ('Will attempt to Enable BitLocker anyway and then continue. Success? {0}' -f ($IsEncrypted))
}


# Add BitLocker Recovery Password if none are present
LogWrite ('# RecoveryPassword')
If ($IsEncrypted) {
    $BitLockStatus = Get-BitLockerVolume $OSDrive
    $KeyProtectorStatus = ($BitLockStatus | Select-Object -Property KeyProtector).KeyProtector
    [System.Collections.ArrayList] $Script:ArrayProtectionPasswords = [System.Collections.ArrayList]::new()
    [uint16] $Script:CountProtectionKeys = 0

    $KeyProtectorStatus | ForEach-Object {
        If ($_.KeyProtectorType -eq 'RecoveryPassword') {
            $Script:CountProtectionKeys += 1
            $null = $Script:ArrayProtectionPasswords.Add([PSCustomObject]@{KeyProtectorId = [String]$_.KeyProtectorId; RecoveryPassword = [String]$_.RecoveryPassword})
        }
    }


    If ($Script:CountProtectionKeys -eq 0) {
        LogWrite ('No RecoveryPasswords found for OS Drive {0}, creating new one.' -f $OSDrive)
        try {
            #$null = Enable-BitLocker -MountPoint $OSDrive -RecoveryPasswordProtector -ErrorAction Stop
            $null = Add-BitLockerKeyProtector -MountPoint $OSDrive -RecoveryPasswordProtector -ErrorAction Stop -WarningAction SilentlyContinue
            If ($?) {
                $IsProtectionPassw = $true
            }
            LogWrite ('Attempting to add RecoveryPasswordProtector on OS Drive ({0}). Success? {1}.' -f ($OSDrive,$IsEncrypted)) 
        } catch {
            LogErrors
            #$null = Enable-BitLocker -MountPoint $OSDrive -RecoveryPasswordProtector -ErrorAction SilentlyContinue
            $null = Add-BitLockerKeyProtector -MountPoint $OSDrive -RecoveryPasswordProtector -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            If ($?) {
                $IsProtectionPassw = $true
            }
            LogWrite ('Will attempt to Enable BitLocker RecoveryPasswordProtector anyway and then continue. Success? {0}.' -f ($IsEncrypted))
        }

        # Count key(s) and list them if success
        If ($IsProtectionPassw) {
            $BitLockStatus = Get-BitLockerVolume $OSDrive
            $KeyProtectorStatus = ($BitLockStatus | Select-Object -Property KeyProtector).KeyProtector
            $Script:ArrayProtectionPasswords = [System.Collections.ArrayList]::new()
            $Script:CountProtectionKeys = 0

            $KeyProtectorStatus | ForEach-Object {
                If ($_.KeyProtectorType -eq 'RecoveryPassword') {
                    $Script:CountProtectionKeys += 1
                    $null = $Script:ArrayProtectionPasswords.Add([PSCustomObject]@{KeyProtectorId = [String]$_.KeyProtectorId; RecoveryPassword = [String]$_.RecoveryPassword})
                }
            }
        }  
    }

    ElseIf ($Script:CountProtectionKeys -eq 1) {
        LogWrite ('Perfect, there are one BitLocker Protection Key present already.')
        $IsProtectionPassw = $true
    
    }

    Else {
        $IsProtectionPassw = $true
        LogWrite ('There are already {0} RecoveryPasswords, no point in creating more' -f ($CountProtectionKeys))
        [uint16] $IntTempCounter = 0
        $Script:ArrayProtectionPasswords | ForEach-Object { LogWrite ('{0} | KeyProtectorId "{1}" | RecoveryPassword "{2}": ' -f (($IntTempCounter += 1),$_.KeyProtectorId,$_.RecoveryPassword)) }
        LogWrite ('Removing all but the first one.')
        $Script:ArrayProtectionPasswords | ForEach-Object { 
            If ($_.KeyProtectorId -ne $Script:ArrayProtectionPasswords[0].KeyProtectorId) {
                $null = Remove-BitLockerKeyProtector -MountPoint $OSDrive -KeyProtectorId $_.KeyProtectorID
                If ($?) {
                    LogWrite ('Successfully removed | KeyProtectorId "{0}" | RecoveryPassword "{1}"' -f ($_.KeyProtectorId,$_.RecoveryPassword))
                }
            }
            Else {
                LogWrite ('Successfully skipped the first key. | KeyProtectorId "{0}" | RecoveryPassword "{1}"' -f ($_.KeyProtectorId,$_.RecoveryPassword))
            }
        }
        LogWrite 'Check if success, AKA only one ProtectionPassword.'
        $BitLockStatus = Get-BitLockerVolume $OSDrive
        $KeyProtectorStatus = ($BitLockStatus | Select-Object -Property KeyProtector).KeyProtector
        $Script:ArrayProtectionPasswords = [System.Collections.ArrayList]::new()
        $Script:CountProtectionKeys = 0

        $KeyProtectorStatus | ForEach-Object {
            If ($_.KeyProtectorType -eq 'RecoveryPassword') {
                $Script:CountProtectionKeys += 1
                $null = $Script:ArrayProtectionPasswords.Add([PSCustomObject]@{KeyProtectorId = [String]$_.KeyProtectorId; RecoveryPassword = [String]$_.RecoveryPassword})
            }
        }
        If ($Script:CountProtectionKeys -eq 1) {
            LogWrite ('SUCCESS, keys left: 1.')
        }
        Else {
            LogWrite 'FAIL, keys left: {0}.' -f ($Script:ArrayProtectionPasswords.Count)
            $IsProtectionPassw = $false
        }
    }

    # Output the one key thats hopefully left        
    LogWrite ('Status: {0} key(s) present:' -f ($Global:CountProtectionKeys))
    LogWrite ('KeyProtectorId "{0}" | RecoveryPassword "{1}".' -f ($Script:ArrayProtectionPasswords[0].KeyProtectorId,$Script:ArrayProtectionPasswords[0].RecoveryPassword))         
}


Else {
    LogWrite ('OS Drive is not encrypted, therefore BitLocker RecoveryPassword can not be added')
    $IsProtectionPassw = $false
}



####################
###### BACKUP ######
####################
# Backup BitLocker Key to OneDrive and AzureAD
LogWrite ('### Backup Protection Password')
# Check whather OSDrive is encrypted and if Protection Password(s) exist
If ($IsEncrypted -and $IsProtectionPassw) {
    LogWrite ('OS Drive is encrypted, and there are {0} ProtectionPassword(s) present. Continuing with backup.' -f ($Script:CountProtectionKeys))
    LogWrite ('Will only backup 1 password to Azure, all present passwords to OneDrive')
    ##############################
    # OneDrive for Business backup
    ##############################
    LogWrite ('# Backup to OneDrive')
    try {
        #Writing Value to OneDrive first 
        $regValues = Get-ChildItem 'HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\'
        ForEach ($regValue in $regValues) {
            [String] $Local:OD4BAccType = [String[]] ((($regValue | Select-Object Name).Name).Split('{\}')[-1])
            If ($Local:OD4BAccType -like 'Business*') {
                LogWrite ('Found a OneDrive for Business account')
                $Local:Key = $regValue.name.Replace('HKEY_CURRENT_USER', 'hkcu:')              
                [String] $Local:OD4BPath = (Get-ItemProperty -Path $Local:Key -Name UserFolder).UserFolder
                                
                If ((-not($Local:OD4BPath -like ($OSDrive + '\Users\*\OneDrive -*'))) -and (Test-Path $Local:OD4BPath)) {
                    LogWrite ('Failed to build OneDrive path: "{0}", or it does not exist.' -f $Local:Path)
                    $IsBackupOD = $false
                    #[String] $Local:Path = ($env:SystemDrive + $env:HOMEPATH + 'OneDrive - ' + '\BitLocker Recovery\' + $env:COMPUTERNAME + '\' )
                } Else {                
                    [String] $Local:OD4BBackupPath = ($Local:OD4BPath + '\BitLocker Recovery\' + $env:COMPUTERNAME + '\')
                    LogWrite ('OneDrive for Business path: {0}' -f ($Local:OD4BPath))
                    LogWrite ('Restore password path: {0}' -f ($Local:OD4BBackupPath)) 
                    #Testing if Recovery folder exists if not create one
                    LogWrite ('Testing if backup folder exists, create it if not.')
                    if (!(Test-Path $Local:Path)) {
                        $null = New-Item -ItemType Directory -Force -Path $Local:Path
                        If ($?) {
                            LogWrite 'Success creating OneDrive for Business folder for backup'
                        }
                    }
                    Else {
                        LogWrite ('Backup folder already exists')
                    }
                
                    # Create string for BitLockerRecoveryPassword.txt
                    [String] $Local:StrRecPass = ('There are {0} RecoveryPassword(s):' -f ($CountProtectionKeys))
                    [uint16] $IntTempCounter = 0
                    $Script:ArrayProtectionPasswords | ForEach-Object {
                        $Local:StrRecPass += ("`r`n" + '{0} | KeyProtectorId "{1}" | RecoveryPassword "{2}": ' -f (($IntTempCounter += 1),$_.KeyProtectorId,$_.RecoveryPassword))
                    }

                    # OutFile the string
                    Out-File -FilePath ($Local:Path + 'BitlockerRecoveryPassword.txt') -Encoding utf8 -Force -InputObject ($Local:StrRecPass)
                    If ($?) {
                        $IsBackupOD = $true
                    }
                }
            }
        }
    }
    Catch {
        LogWrite ('Error while backup to OneDrive, make sure that you are AAD joined and are running the cmdlet as an admin.')
        LogWrite ('Error message:' + "`r`n" + ($_))
    }
    Finally {
        LogWrite ('Did backup to OneDrive succeed? {0}' -f ($IsBackupOD))
    }
    
    #################
    # Azure AD Backup
    #################
    LogWrite ('# Backup to Azure AD')           
    #Check if we can use BackupToAAD-BitLockerKeyProtector commandlet
    try {
        LogWrite 'Check if we can use BackupToAAD-BitLockerKeyProtector commandlet...'
        $cmdName = 'BackupToAAD-BitLockerKeyProtector'
        if (Get-Command $cmdName -ErrorAction SilentlyContinue) {
            #BackupToAAD-BitLockerKeyProtector commandlet exists
            LogWrite ('{0} commandlet exists!' -f $cmdName)
            $BLV = Get-BitLockerVolume -MountPoint $OSDrive
            $null = BackupToAAD-BitLockerKeyProtector -MountPoint $OSDrive -KeyProtectorId $BLV.KeyProtector[0].KeyProtectorId
            If ($?) {
                $IsBackupAAD = $true
            }
            LogWrite ('Success? {0}' -f ($IsBackupAAD))
        } 
        else { 
            # BackupToAAD-BitLockerKeyProtector commandlet not available, using other mechanism 
            LogWrite 'BackupToAAD-BitLockerKeyProtector commandlet not available, using other mechanism.' 
            # Get the AAD Machine Certificate
            $cert = Get-ChildItem Cert:\LocalMachine\My\ | Where-Object { $_.Issuer -match 'CN=MS-Organization-Access' }

            # Obtain the AAD Device ID from the certificate
            $id = $cert.Subject.Replace('CN=','')

            # Get the tenant name from the registry
            $tenant = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$($id)).UserEmail.Split('@')[1]
            LogWrite $tenant
            # Generate the body to send to AAD containing the recovery information
            # Get the BitLocker key information from WMI
            (Get-BitLockerVolume -MountPoint $OSDrive).KeyProtector|? {$_.KeyProtectorType -eq 'RecoveryPassword'}| % {
                $key = $_
                write-verbose "kid : $($key.KeyProtectorId) key: $($key.RecoveryPassword)"
                $body = "{""key"":""$($key.RecoveryPassword)"",""kid"":""$($key.KeyProtectorId.replace('{','').Replace('}',''))"",""vol"":""OSV""}"
                    
                # Create the URL to post the data to based on the tenant and device information
                $url = "https://enterpriseregistration.windows.net/manage/$tenant/device/$($id)?api-version=1.0"
                Logstring "Creating url...$url"
                    
                # Post the data to the URL and sign it with the AAD Machine Certificate
                $req = Invoke-WebRequest -Uri $url -Body $body -UseBasicParsing -Method Post -UseDefaultCredentials -Certificate $cert
                $req.RawContent
                If ($?) {
                    $IsBackupAAD = $true
                }    
                LogString ('Post the data to the URL and sign it with the AAD Machine Certificate. Success? {0}' -f ($IsBackupAAD))
            }
        } 
    }
    catch {
        LogWrite ('Error while backup to Azure AD, make sure that you are AAD joined and are running the cmdlet as an admin.')
        LogWrite ('Error message:' + "`r`n" + ($_))
    }
    Finally {
        LogWrite ('Did backup to Azure AD Succeed? {0}' -f ($IsBackupAAD))
    }

} 
else {
    LogWrite ('Drive is not encrypted and/or no Protection Password(s) present.')
    LogWrite ('Will skip backup, for now.')
}


####################
######  G U I ######
####################
#region GUI
If ($IsEncrypted -and $IsProtectionPassw -and $GUI) {
    # Show reboot prompt to user
    LogWrite "Prompting user to Reboot computer."
           

    [void][System.Reflection.Assembly]::LoadWithPartialName( “System.Windows.Forms”)
    [void][System.Reflection.Assembly]::LoadWithPartialName( “Microsoft.VisualBasic”)

    $form = New-Object “System.Windows.Forms.Form”;
    $form.Width = 500;
    $form.Height = 150;
    $form.Text = "BitLocker requires a reboot !";
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen;

    $DropDownArray = @("4:Hours", "8:Hours", "12:Hours", "24:Hours")
    $DDL = New-Object System.Windows.Forms.ComboBox
    $DDL.Location = New-Object System.Drawing.Size(140, 10)
    $DDL.Size = New-Object System.Drawing.Size(130, 30)
    ForEach ($Item in $DropDownArray) {
        $DDL.Items.Add($Item) | Out-Null
    }
    $DDL.SelectedIndex = 0

    $button1 = New-Object “System.Windows.Forms.button”;
    $button1.Left = 40;
    $button1.Top = 85;
    $button1.Width = 100;
    $button1.Text = “Reboot Now”;
    $button1.Add_Click( {$global:xinput = "Reboot"; $Form.Close()})

    $button2 = New-Object “System.Windows.Forms.button”;
    $button2.Left = 170;
    $button2.Top = 85;
    $button2.Width = 100;
    $button2.Text = “Postpone”;
    $button2.Add_Click( {$global:xinput = "Postpone:" + $DDL.Text; $Form.Close()})

    $button3 = New-Object “System.Windows.Forms.button”;
    $button3.Left = 290;
    $button3.Top = 85;
    $button3.Width = 100;
    $button3.Text = “Cancel”;
    $button3.Add_Click( {$global:xinput = "Postpone24"; $Form.Close()})


    $form.KeyPreview = $True
    $form.Add_KeyDown( {if ($_.KeyCode -eq "Enter") 
            {$x = $textBox1.Text; $form.Close()}})
    $form.Add_KeyDown( {if ($_.KeyCode -eq "Escape") 
            {$form.Close()}})



    $eventHandler = [System.EventHandler] { 
        $button1.Click;
        $DropDownArray.Text;
        $form.Close(); };

    #$button.Add_Click($eventHandler) ;
    $form.Controls.Add($button1);
    $form.Controls.Add($button2);
    $form.Controls.Add($button3);
    $form.Controls.Add($DDL);
    $form.Controls.Add($textLabel1)
    $ret = $form.ShowDialog();

    if ($global:xinput -eq "Reboot") {shutdown -r -f /t 600}
    if ($global:xinput -like "Postpone:*:Hours") {
        $hval = (([int]$global:xinput.split(":")[1]) * 60 * 60)
        shutdown -r -f /t $hval
    }
    if ($global:xinput -eq "Postpone24") {shutdown -r -f /t 86400}
}
#endregion GUI




####################
#### END RESULT ####
####################
LogWrite ('### End results')
LogWrite ('Success status | Encrypted : {0} | Protection Passwords present : {1} | Backup to OneDrive : {2} | Backup to AzureAD : {3}' -f ($IsEncrypted,$IsProtectionPassw,$IsBackupAAD,$IsBackupOD))
# Cleaning up if success
If ($IsEncrypted -and $IsProtectionPassw -and $IsBackupAAD -and $IsBackupOD) {
    LogWrite 'Removing the Scheduled task and files.'
    # Scheduled Task
    If (Get-ScheduledTask -TaskName $Script:ScheduledTaskName -ErrorAction SilentlyContinue) {
        $null = Unregister-ScheduledTask -TaskName $Script:ScheduledTaskName -Confirm:$false -ErrorAction SilentlyContinue
        LogWrite ('Removing the Scheduled task "{0}". Success? {1}' -f ($Script:ScheduledTaskName,$?))
    }
    Else {
        LogWrite ('Scheduled task "{0}" does not exist.' -f ($Script:ScheduledTaskName))
    }
    # Files
    #Remove-Item -Recurse -Force (${env:ProgramFiles(x86)} + '\BitLockerTrigger')
    #LogWrite (' Removing the files. Success? {0}' -f ($?))
}
Else {
    LogWrite 'Fail, something failed (See Success Status above).'
}



####################
#### S T A T S #####
####################
LogWrite ('### STATS')
[String] $PathStats = (${env:ProgramFiles(x86)} + '\BitLockerTrigger\stats.txt')
[uint16] $CountRuns = 1
If (Test-Path $PathStats) {
    $CountRuns = Get-Content $PathStats
    $CountRuns += 1
}
Out-File -FilePath $PathStats -Encoding utf8 -Force -InputObject ([string]($CountRuns))
LogWrite ('Runs so far: {0}' -f ($CountRuns))

If ($CountRuns -eq 30) {
    LogWrite ('Should have been done by now. Sending a support request to your helpdeks')
    ### Gathering info for the email
    [String] $Local:NameComputer = $env:COMPUTERNAME
    ## Tenant
    $Local:ID = (Get-ChildItem Cert:\LocalMachine\My\ | Where-Object { $_.Issuer -match 'CN=MS-Organization-Access' }).Subject.Replace('CN=','')
    # Get the tenant name from the registry
    [String] $Local:NameTenant = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$($Local:ID)).UserEmail.Split('@')[1]
    ## Environment info
    [System.Management.ManagementObject] $Script:WMIInfo = Get-WmiObject -Class win32_operatingsystem
    [String] $Local:WindowsEdition = $Script:WMIInfo.Caption
    [String] $Local:WindowsVersion = $Script:WMIInfo.Version
    ## Mail address(es)
    [String] $Local:StrToEmailAddress = 'Olav R. Birkeland <olavb@ironstoeit.com>;'
    #$StrEmailAddress += 'Ironstone Servicedesk <servicedeks@ironstoneit.com>'
    [String] $Local:StrFromEmailAddress = ('BitLockerTriggerFail@{0}' -f ($Local:NameTenant))
    ### Building email string
    [String] $Local:StrSubject = ('BitLockerTrigger failed {0} times for tenant "{1}", device: "{2}"' -f ($CountRuns.ToString(),$Local:NameTenant,$Local:NameComputer))
    [String] $Local:StrEmail = [String]::Empty
    $Local:StrEmail += ($Local:StrSubject)
    $Local:StrEmail += ("`r`n")
    $Local:StrEmail += ("`r`n" + '## Environment info')
    $Local:StrEmail += ("`r`n" + ('Device name: ' + $Local:NameComputer + ', Windows Edition: ' + $Local:WindowsEdition + ' , Windows Version' + $Local:WindowsVersion))
    $Local:StrEmail += ("`r`n`r`n" + 'There have now been {0} runs, but BitLockerTrigger STILL fails.' -f ($CountRuns))
    $Local:StrEmail += ("`r`n" + 'Success status | Encrypted : {0} | Protection Passwords present : {1} | Backup to AzureAD : {2} | Backup to OneDrive : {3}' -f ($IsEncrypted,$IsProtectionPassw,$IsBackupAAD,$IsBackupOD))
    ### Send email
    #Send-MailMessage -To $Local:StrToEmailAddress -SmtpServer  -From $Local:StrFromEmailAddress -Subject $Local:StrSubject -Body $Local:StrEmail
}



####################
####  D O N E  #####
####################
LogWrite ('All done, exiting script...')
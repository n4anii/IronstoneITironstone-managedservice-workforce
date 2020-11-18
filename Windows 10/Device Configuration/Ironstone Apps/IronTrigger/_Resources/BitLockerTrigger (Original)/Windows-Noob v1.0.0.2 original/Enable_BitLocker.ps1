<#PSScriptInfo 
.VERSION 1.7
.GUID f5187e3f-ed0a-4ce1-b438-d8f421619ca3 
.ORIGINAL AUTHOR Jan Van Meirvenne 
.MODIFIED BY Sooraj Rajagopalan, Paul Huijbregts, Pieter Wigleven & Niall Brady (windows-noob.com 2017/8/17)
.COPYRIGHT 
.TAGS Azure Intune Bitlocker  
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
 Check whether BitLocker is Enabled, if not Enable Bitlocker on AAD Joined devices and store recovery info in AAD 
 Added logging
#> 
[cmdletbinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $OSDrive = $env:SystemDrive
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Function LogWrite
{
     Param ([string]$logstring)
     $a = Get-Date
     $logstring = $a,$logstring
     Add-content $Logfile -value $logstring
     Write-host $logstring
}
Function LogErrors
{
     LogWrite "Caught an exception:"
     LogWrite "Exception Type: $($_.Exception.GetType().FullName)"
     LogWrite "Exception Message: $($_.Exception.Message)"
}

$Logfile = "C:\Windows\Temp\TriggerBitLocker.log"

LogWrite "Starting Trigger BitLocker script."

#BitLocker code here

        LogWrite "Checking if Fully Decrypted."
        $bdeProtect = Get-BitLockerVolume $OSDrive | select -Property VolumeStatus
        Logwrite "detected $OSDrive = $bdeProtect"
        try{
            if ($bdeProtect.VolumeStatus -eq "FullyDecrypted") 
	           {
                LogWrite "Attempting to Enable BitLocker on $OSDrive"
                  # Enable Bitlocker using TPM
                Enable-BitLocker -MountPoint $OSDrive -TpmProtector -ErrorAction Stop
               }
            }
         catch
                {LogErrors
                 LogWrite "will attempt to Enable BitLocker anyway and then continue .."
                 Enable-BitLocker -MountPoint $OSDrive -TpmProtector -ErrorAction SilentlyContinue
                 }

        try{
             LogWrite "Attempting to add RecoveryPasswordProtector on $OSDrive"
             Enable-BitLocker -MountPoint $OSDrive  -RecoveryPasswordProtector -ErrorAction Stop  
             }
        catch
                {LogErrors
                LogWrite "will attempt to Enable BitLocker RecoveryPasswordProtector anyway and then continue .."
                Enable-BitLocker -MountPoint $OSDrive  -RecoveryPasswordProtector -ErrorAction SilentlyContinue  
                }  

 # check if BitLocker was enabled or not
 $keyProtect = Get-BitLockerVolume $OSDrive | select -Property KeyProtector
 If ($keyProtect.KeyProtector.Count -ge 1)
 {LogWrite "BitLocker Protectors found, continuing..."
 

#OneDrive BitLocker key handling code here

try
{
			  #Writing Value to OneDrive first
                LogWrite "Writing BitLocker key to OneDrive..."
              $regValues = Get-ChildItem "hkcu:\SOFTWARE\Microsoft\OneDrive\Accounts\"
              ForEach( $regValue in $regValues)
              {
                 #Check if OD4B has been configured
                  LogWrite "Checking if OD4B has been configured..."
                 $key = $regValue.name.Replace("HKEY_CURRENT_USER","hkcu:")              
                 $ODfBAcct =(Get-ItemProperty -Path $key -ErrorAction SilentlyContinue -Name Business).Business 
 
                 #Creating Business account path
                 if ( $ODfBAcct -eq "1")
               {LogWrite "$ODfBAcct -eq '1'"
                    {
                    $path = ""
                    $path = (Get-ItemProperty -Path $key -Name UserFolder).UserFolder + "\Recovery"
                    }
                    #Testing if Recovery folder exists if not create one
                      LogWrite "Testing if Recovery folder exists if not create one..."
                    if (!(test-path $path))
                    {
                    LogWrite "Creating Recovery folder..."
                New-Item -ItemType Directory -Force -Path $path | out-null
                }
                (Get-BitLockerVolume -MountPoint $OSDrive).KeyProtector   | Out-File "$($path)\$($env:computername)_BitlockerRecoveryPassword.txt"
              }
              }
			
                #Check if we can use BackupToAAD-BitLockerKeyProtector commandlet
			    LogWrite "Check if we can use BackupToAAD-BitLockerKeyProtector commandlet..."
                $cmdName = "BackupToAAD-BitLockerKeyProtector"
                if (Get-Command $cmdName -ErrorAction SilentlyContinue)
				{
					#BackupToAAD-BitLockerKeyProtector commandlet exists
                    LogWrite "BackupToAAD-BitLockerKeyProtector commandlet exists!"
                    $BLV = Get-BitLockerVolume -MountPoint $OSDrive | select *
					BackupToAAD-BitLockerKeyProtector -MountPoint $OSDrive -KeyProtectorId $BLV.KeyProtector[1].KeyProtectorId
                }
			    else
                { 

		  		# BackupToAAD-BitLockerKeyProtector commandlet not available, using other mechanism 
                LogWrite "BackupToAAD-BitLockerKeyProtector commandlet not available, using other mechanism  " 
				# Get the AAD Machine Certificate
				$cert = dir Cert:\LocalMachine\My\ | where { $_.Issuer -match "CN=MS-Organization-Access" }

				# Obtain the AAD Device ID from the certificate
				$id = $cert.Subject.Replace("CN=","")

				# Get the tenant name from the registry
				$tenant = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$($id)).UserEmail.Split('@')[1]
                LogWrite $tenant
				# Generate the body to send to AAD containing the recovery information
				# Get the BitLocker key information from WMI
					(Get-BitLockerVolume -MountPoint $OSDrive).KeyProtector|?{$_.KeyProtectorType -eq 'RecoveryPassword'}|%{
					$key = $_
					write-verbose "kid : $($key.KeyProtectorId) key: $($key.RecoveryPassword)"
					$body = "{""key"":""$($key.RecoveryPassword)"",""kid"":""$($key.KeyProtectorId.replace('{','').Replace('}',''))"",""vol"":""OSV""}"
				
				# Create the URL to post the data to based on the tenant and device information
					$url = "https://enterpriseregistration.windows.net/manage/$tenant/device/$($id)?api-version=1.0"
                    Logstring "Creating url...$url"
				
				# Post the data to the URL and sign it with the AAD Machine Certificate
					$req = Invoke-WebRequest -Uri $url -Body $body -UseBasicParsing -Method Post -UseDefaultCredentials -Certificate $cert
					$req.RawContent
                    LogString "Post the data to the URL and sign it with the AAD Machine Certificate"
                }
			}
           
           # remove the scheduled task
           LogWrite "removing the Scheduled task, as encryption is enabled...."
           Unregister-ScheduledTask -TaskName BitLockerTrigger -Confirm:$false
    
    } catch 
            {
            LogWrite "Error while setting up AAD Bitlocker, make sure that you are AAD joined and are running the cmdlet as an admin: $_"
            }

# show reboot prompt to user
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
$DDL.Location = New-Object System.Drawing.Size(140,10)
$DDL.Size = New-Object System.Drawing.Size(130,30)
ForEach ($Item in $DropDownArray) {
    $DDL.Items.Add($Item) | Out-Null
}
$DDL.SelectedIndex  = 0

$button1 = New-Object “System.Windows.Forms.button”;
$button1.Left = 40;
$button1.Top = 85;
$button1.Width = 100;
$button1.Text = “Reboot Now”;
$button1.Add_Click({$global:xinput = "Reboot";$Form.Close()})

$button2 = New-Object “System.Windows.Forms.button”;
$button2.Left = 170;
$button2.Top = 85;
$button2.Width = 100;
$button2.Text = “Postpone”;
$button2.Add_Click({$global:xinput = "Postpone:" + $DDL.Text;$Form.Close()})

$button3 = New-Object “System.Windows.Forms.button”;
$button3.Left = 290;
$button3.Top = 85;
$button3.Width = 100;
$button3.Text = “Cancel”;
$button3.Add_Click({$global:xinput = "Postpone24";$Form.Close()})


$form.KeyPreview = $True
$form.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$x=$textBox1.Text;$form.Close()}})
$form.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$form.Close()}})



$eventHandler = [System.EventHandler]{ 
$button1.Click;
$DropDownArray.Text;
$form.Close();};

#$button.Add_Click($eventHandler) ;
$form.Controls.Add($button1);
$form.Controls.Add($button2);
$form.Controls.Add($button3);
$form.Controls.Add($DDL);
$form.Controls.Add($textLabel1)
$ret = $form.ShowDialog();

if ($global:xinput -eq "Reboot") {shutdown -r -f /t 600}
if ($global:xinput -like "Postpone:*:Hours") {
$hval = (([int]$global:xinput.split(":")[1])*60*60)
shutdown -r -f /t $hval}
if ($global:xinput -eq "Postpone24") {shutdown -r -f /t 86400}
}

LogWrite "All done, exiting script..."





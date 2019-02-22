[cmdletbinding()]
param
(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OSDrive = $env:SystemDrive,

    [ValidateNotNullOrEmpty()]
    [string]$LogPath = ($env:TEMP+'\Bitlocker_Intune_Trigger.log')
)
$crlf = [string]([char]13+[char]10);
$datestring = (Get-Date).ToString('g');
$msg = '';
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
try
{
    $blVolume = Get-BitLockerVolume -MountPoint $OSDrive;
    if($blVolume.VolumeStatus -eq 'FullyDecrypted') 
    {
        $tpmWmi = Get-WmiObject Win32_TPM -Namespace root\cimv2\Security\MicrosoftTPM;
        $tpmEnabled = if($tpmWmi){$tpmWmi.IsEnabled() | Select-Object -ExpandProperty IsEnabled} else {$false};
        # Enable Bitlocker using TPM
        if($tpmEnabled)
        {
            $null = Enable-BitLocker -MountPoint $OSDrive -TpmProtector -EncryptionMethod XtsAes128 -UsedSpaceOnly -SkipHardwareTest -ErrorAction SilentlyContinue;
        };
        $null = Enable-BitLocker -MountPoint $OSDrive -RecoveryPasswordProtector -UsedSpaceOnly -SkipHardwareTest -ErrorAction SilentlyContinue;
        $msg += $datestring+' Enabled BitLocker Encryption for ' + $OSDrive + $crlf;
    } else {$msg += $datestring+' BitLocker Encryption already enabled for ' + $OSDrive + $crlf;};
    # Writing recovery key to temp directory, another user-mode task will move this to OneDrive for Business (if configured)
    $blVolume = Get-BitLockerVolume -MountPoint $OSDrive;
    $keyProtector = $blVolume.KeyProtector | Where-Object{$_.KeyProtectorType -eq 'RecoveryPassword'};
    if($keyProtector.KeyProtectorId)
    {
        $keyfile = "$($env:TEMP)\$($env:COMPUTERNAME)_BitlockerRecoveryPassword.txt";
        $blVolume.KeyProtector | Out-File -FilePath $keyfile;
        $msg += $datestring+' BitLocker Recovery key stored at ' + $keyfile + $crlf;
        # Check if we can use BackupToAAD-BitLockerKeyProtector commandlet
        if(Get-Command -Name BackupToAAD-BitLockerKeyProtector -Module BitLocker -ErrorAction SilentlyContinue)
        {
            # BackupToAAD-BitLockerKeyProtector commandlet exists
            foreach($key in $keyProtector)
            {
                $null = BackupToAAD-BitLockerKeyProtector -MountPoint $OSDrive -KeyProtectorId $key.KeyProtectorId;
                $msg += $datestring+' BitLocker Encryption key ' + $key.KeyProtectorId + ' saved to AAD' + $crlf;
            }
        } else {
            # BackupToAAD-BitLockerKeyProtector commandlet not available, using other mechanisme  
            # Get the AAD Machine Certificate
            $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Issuer -match 'CN=MS-Organization-Access'};
            if($cert -and $cert -is [array]){$cert = $cert | Sort-Object -Property NotBefore -Descending | Select-Object -First 1};
            # Obtain the AAD Device ID from the certificate
            $id = $cert.Subject.Replace('CN=','');
            # Get the tenant name from the registry
            $regitem = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$($id) -ErrorAction SilentlyContinue;
            if($regitem)
            {
                $tenant = if($regitem.UserEmail -match '@'){$regitem.UserEmail.Split('@')[1]} else {$regitem.UserEmail};
                # Generate the body to send to AAD containing the recovery information
                # Get the BitLocker key information from WMI
                foreach($key in $keyProtector)
                {
                    $body = "{""key"":""$($key.RecoveryPassword)"",""kid"":""$($key.KeyProtectorId.replace('{','').Replace('}',''))"",""vol"":""OSV""}";
                    # Create the URL to post the data to based on the tenant and device information
                    $url = "https://enterpriseregistration.windows.net/manage/$tenant/device/$($id)?api-version=1.0";
                    # Post the data to the URL and sign it with the AAD Machine Certificate
                    $req = Invoke-WebRequest -Uri $url -Body $body -UseBasicParsing -Method Post -UseDefaultCredentials -Certificate $cert;
                    if($req.StatusCode -eq 200)
                    {
                        $msg += $datestring+' BitLocker Encryption key ' + $key.KeyProtectorId + ' saved to AAD' + $crlf;
                    } else {$datestring+' Error saving BitLocker Encryption key ' + $key.KeyProtectorId + ' to AAD! ErrorCode: ' + $req.StatusCode + ' ' + $req.StatusDescription + $crlf;};
                };
            } else {$datestring+' Error reading registry key: HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\' + $id + $crlf;};
        };
    } else {$datestring+' BitLocker Encryption key do not exist, save to AAD aborted!' + $crlf;};
} catch {
    $msg += $datestring+' Error: '+$_.ToString().Replace($crlf,' ').Replace("`n",' ').Trim() + $crlf;
} finally {
    $null = Add-Content -Value $msg.Trim() -Path $LogPath -Force;
};
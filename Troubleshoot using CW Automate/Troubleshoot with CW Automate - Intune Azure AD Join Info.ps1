# CloudDomainJoin
## JoinInfo
Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo' -Depth 0
## TenantInfo
Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo' -Depth 0


# WorkplaceJoin (GPO / SCCM only)
Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin' -Depth 0


# Profile list
Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -Depth 0
[string[]]$(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -Depth 0 | Select-Object -ExpandProperty 'Name').ForEach{$_.Split('\')[-1]}
## Intune enrolled?
### SID S-1-12-* exist
[bool]($([string[]]$(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -Depth 0 | Select-Object -ExpandProperty 'Name').ForEach{$_.Split('\')[-1]}).ForEach{$_ -like 'S-1-12-*'} -contains $true)
### Tenant info exist
[bool]($(Get-ItemProperty -Path ('Registry::{0}' -f ([string]($(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo' -Depth 0).'Name'))) -Name 'MdmEnrollmentUrl').'MdmEnrollmentUrl' -like 'https://enrollment.manage.microsoft.com*')


# Enrollment date last
## Get the date
[datetime](Get-Item -Path ('{0}\Microsoft Intune Management Extension' -f (${env:ProgramFiles(x86)})) | Select-Object -ExpandProperty 'CreationTime')
## One day
[datetime]$(Try{Get-Item -Path ('{0}\Microsoft Intune Managementp Extension' -f (${env:ProgramFiles(x86)})) -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'CreationTimeUtc'}Catch{[datetime]::UtcNow}) -gt [datetime]::UtcNow.AddDays(-1)
## Two days
[datetime]$(Try{Get-Item -Path ('{0}\Microsoft Intune Managementp Extension' -f (${env:ProgramFiles(x86)})) -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'CreationTimeUtc'}Catch{[datetime]::UtcNow}) -gt [datetime]::UtcNow.AddDays(-2)
## Two days
$Path = ('{0}\Microsoft Intune Management Extension' -f (${env:ProgramFiles(x86)}))
[bool]$(
    [datetime]$(
        if ([bool]$(Test-Path -Path $Path -ErrorAction 'SilentlyContinue')) {
            Try{
                $Date = [datetime]$(Get-Item -Path $Path -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'CreationTimeUtc')
                if ($Date -ne [datetime]::MinValue) {
                    $Date
                }
                else{
                    [datetime]::UtcNow
                }
            }
            Catch{
                [datetime]::UtcNow
            }
        }
        else {
            [datetime]::UtcNow
        }
    ) -gt [datetime]::UtcNow.AddDays(-2)
)


# Get UPN from registry AzureAD Joined Devices
Get-ItemProperty -Path ('Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\{0}' -f ((Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\').'Name'.Split('\')[-1])) -Name 'UserEmail' | Select-Object -ExpandProperty 'UserEmail'


# Get UPN from registry AzureAD Joined Devices
Get-ItemProperty -Path ('Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\{0}' -f ((Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\' -ErrorAction 'SilentlyContinue' | Select-Object -First 1 -ExpandProperty 'Name').Split('\')[-1])) -Name 'UserEmail' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserEmail'


# Get AAD Certificat (can be used to upload BitLocker Recovery Password for instance)
$Certificate           = ($([array]$(Get-ChildItem -Path 'Certificate::LocalMachine\My')).Where{$_.'Issuer' -match 'CN=MS-Organization-Access'})
$CertificateThumbprint = [string]$($Certificate | Select-Object -ExpandProperty 'Thumbprint')
$CertificateSubject    = [string]$([string]$($Certificate | Select-Object -ExpandProperty 'Subject').Replace('CN=',''))
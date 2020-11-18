$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsAdmin'  -Value ([bool]$([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsSystem' -Value ([bool]$(([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)) -eq ([string]('S-1-5-18'))))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsCorrectUser' -Value ([bool]$(if($DeviceContext -and $BoolIsSystem){$true}elseif(-not($DeviceContext) -and (-not($BoolIsSystem))){$true}else{$false}))


$Script:StrIntuneUserNameSignedIn = [string]$(
    $x = [string]::Empty
    if ($BoolIsSystem -and $BoolIsAdmin) {
        $x = [string](Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName' -Unique -First 1 -ErrorAction 'SilentlyContinue')
        if ((-not($?)) -or [string]::IsNullOrEmpty($x) -or $x -like 'nt *' -or $x -like 'nt-*'){
            $x = [string]$($y='Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IdentityStore\Cache';$z=[string]([string[]]@(Get-ChildItem -Path $X | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]}) | Where-Object {$_.Length -ge 9 -and $_ -notlike '*1000'} | Sort-Object -Descending:$false | Select-Object -First 1);[string](Get-ItemProperty -Path ('{0}\{1}\IdentityCache\{1}' -f ($X,$Y)) -Name 'SAMName' | Select-Object -ExpandProperty 'SAMName'))
        }
    }
    else {$x = [string]([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)}
    if ($? -and (-not([string]::IsNullOrEmpty($x)))) {$x}
    else {Throw ('ERROR: Did not manage to get "Domain\UserName" for the logged in user.')}
)




$Script:StrIntuneUserIdentifier = [string]$(
    $h = [byte](50)
    $x = [string]::Empty
    if ($BoolIsSystem -and $BoolIsAdmin) {
        $x = [string]([string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -Force | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {([string]($_)).Length -ge $h -and $_ -notlike '*_Classes'} | Select-Object -Unique | Sort-Object -Descending:$false) | Select-Object -First 1)
        if ((-not($?)) -or [string]::IsNullOrEmpty($x) -or ([string]($x)).Length -le $h) {
            $x = [string]([System.Security.Principal.NTAccount]::new($Script:StrUserNameSignedIn).Translate([System.Security.Principal.SecurityIdentifier]).Value)
        }
    }
    else {$x = [string]([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)}
    if ($? -and (-not([string]::IsNullOrEmpty($x))) -and ([string]($x)).Length -ge $h){$x}
    else {Throw ('ERROR: Did not manage to get User Security Identifier for the logged in user.')}
)


$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrUserIdentifier' -Value ([string]$($h=[byte](50);$x=[string]::Empty;if($BoolIsSystem -and $BoolIsAdmin){$x=[string]([string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -Force | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {([string]($_)).Length -ge $h -and $_ -notlike '*_Classes'} | Select-Object -Unique | Sort-Object -Descending:$false) | Select-Object -First 1);if ((-not($?)) -or [string]::IsNullOrEmpty($x) -or ([string]($x)).Length -le $h) {$x = [string]([System.Security.Principal.NTAccount]::new([string](Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName' -Unique -First 1 -ErrorAction 'SilentlyContinue')).Translate([System.Security.Principal.SecurityIdentifier]).Value)}}else{$x=[string]([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)}if((-not([string]::IsNullOrEmpty($x))) -and ([string]($x)).Length -ge $h){$x}else{Throw('ERROR: Did not manage to get User Security Identifier for the logged in user.')}))



$Script:PathDirLog = ([string]$('{0}\IronstoneIT\Intune\DeviceConfiguration\' -f ($(
    if($DeviceContext -and $BoolIsCorrectUser -and $BoolIsAdmin){$env:ProgramW6432}
    elseif($BoolIsSystem -and (-not($DeviceContext)){
    else{$env:APPDATA}))
))



# UPN of the Intune joined user



# Current Username
$CurrentUserName = $env:USERNAME
$CurrentUserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]



# Current Username & Domain
$CurrentUserNameAndDomain = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$CurrentUserNameAndDomain = ('{0}\{1}' -f ($env:USERDOMAIN,$env:USERNAME))
$CurrentUserNameAndDomain = whoami




# Domain Joined User from any context
$ItnuneJoinedUserName          = [string]$($X='Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IdentityStore\Cache';$Y=[string]([string[]]@(Get-ChildItem -Path $X | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]}) | Where-Object {$_ -notlike 'S-1-5-*'} | Sort-Object -Descending:$false | Select-Object -First 1);[string](Get-ItemProperty -Path ('{0}\{1}\IdentityCache\{1}' -f ($X,$Y)) -Name 'SAMName' | Select-Object -ExpandProperty 'SAMName'))
$IntuneJoinedUserNameAndDomain = [string](Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty 'UserName' -Unique -First 1)
$IntuneJoinedUserNameAndDomain = [string]$($X='Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IdentityStore\Cache';$Y=[string]([string[]]@(Get-ChildItem -Path $X | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]}) | Where-Object {$_ -notlike 'S-1-5-*'} | Sort-Object -Descending:$false | Select-Object -First 1);[string]('{0}\{1}' -f ([string](Get-ItemProperty -Path ('{0}\{1}\IdentityCache\{1}' -f ($X,$Y)) -Name 'ProviderName' | Select-Object -ExpandProperty 'ProviderName'),[string](Get-ItemProperty -Path ('{0}\{1}\IdentityCache\{1}' -f ($X,$Y)) -Name 'SAMName' | Select-Object -ExpandProperty 'SAMName'))))
$IntuneJoinedUserIdentifier    = [string]([string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -Force | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {([string]($_)).Length -ge 50 -and $_ -notlike '*_Classes'} | Select-Object -Unique | Sort-Object -Descending:$false) | Select-Object -First 1)
$IntuneJoinedUserIdentifier    = [string]([string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -Force | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_ -notlike 'S-1-5-*' -and $_ -notlike '*_Classes' -and $_ -notlike '.DEFAULT'} | Select-Object -Unique | Sort-Object -Descending:$false) | Select-Object -First 1)
$IntuneJoinedUserIdentifier    = [string]([string[]]@($X = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IdentityStore\Cache'; [string[]]@(Get-ChildItem -Path $X | Select-Object -ExpandProperty 'Name' -Unique) | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_ -notlike 'S-1-5-*'}) | Select-Object -First 1)
$IntuneJoinedUserIdentifier    = [string]([System.Security.Principal.NTAccount]::new([string](Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty 'UserName' -Unique -First 1)).Translate([System.Security.Principal.SecurityIdentifier]).Value)
$IntuneJoinedUserIdentifier    = [string]([string[]]@([string[]]@(Get-Process -Name 'svchost' -IncludeUserName | Select-Object -ExpandProperty 'UserName' -Unique) | ForEach-Object{[string]([System.Security.Principal.NTAccount]::new($_)).Translate([System.Security.Principal.SecurityIdentifier]).Value}) | Where-Object {$_.Length -ge 9} | Select-Object -Unique -First 1)

# Current UPN
$CurrentUserUPN = [string]$($1='Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo';Get-ItemProperty -Path ('{0}\{1}' -f ($1,(Get-ChildItem -Path $1).Name.Split('\')[-1])) -Name 'UserEmail' | Select-Object -ExpandProperty 'UserEmail')
$CurrentUserUPN = Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\OneDrive\Accounts\Business1' -Name 'UserEmail' | Select-Object -ExpandProperty 'UserEmail'
$CurrentUserUPN = [string]$($X='Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IdentityStore\Cache';$Y=[string]([string[]]@(Get-ChildItem -Path $X | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]}) | Where-Object {$_.Length -ge 9 -and $_ -notlike '*1000'} | Sort-Object -Descending:$false | Select-Object -First 1);Get-ItemProperty -Path ('{0}\{1}\IdentityCache\{1}' -f ($X,$Y)) -Name 'UserName' | Select-Object -ExpandProperty 'UserName')
$CurrentUserUPN = whoami /UPN



# Current User Security Identifier (SID)
$CurrentUserIdentifier = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$CurrentUserIdentifier = [System.Security.Principal.NTAccount]::new((Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty UserName -First 1)).Translate([System.Security.Principal.SecurityIdentifier]).Value
$CurrentUserIdentifier = [System.Security.Principal.NTAccount]::new([System.Security.Principal.WindowsIdentity]::GetCurrent().Name).Translate([System.Security.Principal.SecurityIdentifier]).Value




# All Users Security Identitifiers (SIDs)
$UserIdentities = [string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -Force | Select-Object -ExpandProperty 'Name') | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_.Length -ge 9 -and $_ -notlike '*_Classes'}
$UserIdentities = [string[]]@($X = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IdentityStore\Cache'; [string[]]@(Get-ChildItem -Path $X | Select-Object -ExpandProperty 'Name' -Unique) | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_.Length -ge 9 -and $_ -notlike '*1000'}




# Current User Desktop folder location
$CurrentUserDesktopFolderPath = ('{0}\Desktop' -f ($env:USERPROFILE))
$CurrentUserDesktopFolderPath = [System.Environment]::GetFolderPath('Desktop')



# Convert from SID (Security Identifier) to "Domain\Username"
$SIDtoDomainUsername = [System.Security.Principal.SecurityIdentifier]::new([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value).Translate([System.Security.Principal.NTAccount]).Value
$SIDtoDomainUsername = [System.Security.Principal.SecurityIdentifier]::new('S-1-5-18').Translate([System.Security.Principal.NTAccount]).Value



# Convert from "Domain\Username" to SID (Security Identifier)
$DomainUsernameToSID = [System.Security.Principal.NTAccount]::new([System.Security.Principal.WindowsIdentity]::GetCurrent().Name).Translate([System.Security.Principal.SecurityIdentifier]).Value
$DomainUsernameToSID = [System.Security.Principal.NTAccount]::new('NT AUTHORITY\SYSTEM').Translate([System.Security.Principal.SecurityIdentifier]).Value




$Script:IntuneUserSID  = [string]$(if($BoolIsSystem){Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')} | Where-Object {$_ -notlike 'S-1-5-*' -and <#$_ -notlike '.DEFAULT' -and $_ -notlike '*_Classes' -and#> (Test-Path -Path ('Registry::HKEY_USERS\{0}\Volatile Environment' -f ($_)))} | Select-Object -First 1}else{$env:USERNAME})
$Script:IntuneUserName = [string]$(
    if ([string]::IsNullOrEmpty($IntuneUserSID)) {
        if ($BoolIsAdmin) {
            $UserName = [string](Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty 'UserName' -Unique | Where-Object {([string]([System.Security.Principal.NTAccount]::new($_).Translate([System.Security.Principal.SecurityIdentifier]).Value)) -notlike 'S-1-5-*'} | Select-Object -First 1 -ErrorAction 'SilentlyContinue')
            if ($? -and [string]::IsNullOrEmpty($UserName)) {
                $Script:IntuneUserSID = [System.Security.Principal.NTAccount]::new($UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value
                $UserName
            }
            else {
                Throw 'ERROR: Did not manage to get Security Identifier (SID) and/or "Domain\Username" for Intune joined user on this computer.'
            }
        }
    }
    else {
        [string]([System.Security.Principal.SecurityIdentifier]::new($IntuneUserSID).Translate([System.Security.Principal.NTAccount]).Value)
    }   
)

$PathDirLog = [string]$(if($BoolIsSystem){('{0}\Users\{1}\AppData' -f ($env:SystemDrive,$IntuneUserName.Split('\')[-1]))}else{('{0}\AppData' -f ($env:USERPROFILE))})


foreach ($SID in @(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]})) {
    $TenantIDHKCU = Get-ChildItem -Path ('Registry::\HKEY_Users\{0}\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC' -f ($SID)) -Recurse:$false | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]}
    Write-Output -InputObject $TenantIDHKCU
}


<# 

    Azure AD Joined Info
        HKLM = Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\<TenantGUID>
        HKCU = Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC\<TenantGUID>
        HKU  = Registry::HKEY_USERS\<UserSID>\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC\<TenantGUID>
#>


$Script:StrUserIntuneSID     = [string]$(if($BoolIsSystem){[string]([string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]}) | Where-Object {@(Get-ChildItem -Path ('Registry::\HKEY_Users\{0}\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC' -f ($_)) -Recurse:$false -ErrorAction 'SilentlyContinue').Count -eq 1})}else{[string]([System.Security.Principal.NTAccount]::new([string]('{0}\{1}' -f ($env:USERDOMAIN,$env:USERNAME))).Translate([System.Security.Principal.SecurityIdentifier]).Value)})
$Script:StrUserIntuneName    = [string]$(if($BoolIsSystem){([System.Security.Principal.SecurityIdentifier]::new($Script:StrUserIntuneSID).Translate([System.Security.Principal.NTAccount]).Value)}else{[string]('{0}\{1}' -f ($env:USERDOMAIN,$env:USERNAME))})
$Script:StrUserIntuneAppdata = [string](Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Volatile Environment' -f ($Script:StrUserIntuneSID)) -Name 'APPDATA' | Select-Object -ExpandProperty 'APPDATA')


# Get Tenant GUID from HKLM and HKCU
$TenantGUIDFromHKLM = [string]$($x='Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo'; Get-ItemProperty -Path ('{0}\{1}' -f ($x,[string](Get-ChildItem -Path $x -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]}))) -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'TenantId')
$TenantGUIDFromHKCU = [string]$($x='Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC'; Get-ItemProperty -Path ('{0}\{1}' -f ($x,[string](Get-ChildItem -Path $x -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]}))) -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'TenantDomain')

$TenantGUIDFromHKLM -eq $TenantGUIDFromHKCU
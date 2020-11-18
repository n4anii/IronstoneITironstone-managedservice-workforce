#region    Get Intune user SID - v1
[string]$(
    if ($Script:BoolIsSystem) {
        $Local:LengthInterval = [byte[]]@(40 .. 80)
        $Local:SID = [string]$(Try{$Local:SIDs=[string[]]@();$Local:SIDs=[string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_ -like 'S-1-12-*' -and $_ -notlike '*_Classes'});if(@($Local:SIDs).Count -eq 1){$Local:SIDs}else{[string]::Empty}}Catch{[string]::Empty})
        if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
            $Local:SID = [string]$(Try{$Local:SIDs=[string[]]@();$Local:SIDs=[string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_ -notlike '.DEFAULT' -and $_ -notlike 'S-1-5-??' -and $_ -notlike '*_Classes'});if(@($Local:SIDs).Count -eq 1){$Local:SIDs}else{[string]::Empty}}Catch{[string]::Empty})
        }
        if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
            $Local:SID = [string]$(Try{[System.Security.Principal.NTAccount]::new(([string]([string[]]@(Get-WmiObject -Class 'Win32_Process' -Filter "Name='Explorer.exe'" -ErrorAction 'SilentlyContinue' | ForEach-Object {$($Owner = $_.GetOwner();if($Owner.ReturnValue -eq 0){('{0}\{1}' -f ($Owner.Domain,$Owner.User))})}) | Select-Object -Unique -First 1))).Translate([System.Security.Principal.SecurityIdentifier]).Value}catch{[string]::Empty})
        }
        if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
            $Local:SID = [string]$(Try{[System.Security.Principal.NTAccount]::new([string]([string[]]@(Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName') | Select-Object -Unique -First 1)).Translate([System.Security.Principal.SecurityIdentifier]).Value}catch{[string]::Empty})
        }
        if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
            Throw 'ERROR: Did not manage to get Intune user SID from SYSTEM context.'
        }
        else {
            $Local:SID
        }
    }
    else {
        [string]([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)
    }
)
#endregion Get Intune user SID - v1


#region    DONT USE
    # Returns "OK" for some random cases
    [string]$(Try{[string]([string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]}) | Where-Object {$_ -notlike 'S-1-5-??' -and @(Get-ChildItem -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC' -f ($_)) -Recurse:$false -ErrorAction 'SilentlyContinue').Count -eq 1})}Catch{[string]::Empty})
#endregion DONT USE


#region    Get Intune user SID - v2
    # Registry or Running process (explorer.exe)
    [string]$(
        if ($Script:BoolIsSystem) {
            $Local:LengthInterval = [byte[]]@(40 .. 80)
            $Local:SID = [string]::Empty

            $Local:SID = [string]$(
                Try{
                    $Local:SIDs=[string[]]@()
                    $Local:SIDs=[string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_ -like 'S-1-12-*' -and $_ -notlike '*_Classes'})
                    if (@($Local:SIDs).Count -eq 0) {
                        $Local:SID = [string]$(Try{$Local:SIDs=[string[]]@();$Local:SIDs=[string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_ -notlike '.DEFAULT' -and $_ -notlike 'S-1-5-??' -and $_ -notlike '*_Classes'});if(@($Local:SIDs).Count -eq 1){$Local:SIDs}else{[string]::Empty}}Catch{[string]::Empty})
                    }
                    if(@($Local:SIDs).Count -eq 1){
                        $Local:SIDs
                    }
                    elseif(@($Local:SIDs).Count -gt 1){
                        $Local:SIDs = @($Local:SIDs | Where-Object {Test-Path -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC' -f ($_))})
                        if(@($Local:SIDs).Count -eq 1){
                            $Local:SIDs
                        }
                        else {
                            [string]::Empty
                        }
                    }
                    else{
                        [string]::Empty
                    }
                }
                Catch{[string]::Empty}
            )

            if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
                $Local:UN = [string]([string[]]@(Get-WmiObject -Class 'Win32_Process' -Filter "Name='Explorer.exe'" -ErrorAction 'SilentlyContinue' | ForEach-Object {$($Owner = $_.GetOwner();if($Owner.ReturnValue -eq 0 -and $Owner.Domain -notlike 'nt *' -and $Owner.Domain -notlike 'nt-*'){('{0}\{1}' -f ($Owner.Domain,$Owner.User))})}) | Select-Object -Unique -First 1)
                if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.Length -lt 3) {
                    $Local:UN = [string]([string[]]@(Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName' | Where-Object {$_ -notlike 'nt *' -and $_ -notlike 'nt-*'}) | Select-Object -Unique -First 1)
                }
                if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.Length -lt 3) {
                    [string]::Empty
                }
                else {
                    Try{
                        $Local:SID = [string]([System.Security.Principal.NTAccount]::new($Local:UN).Translate([System.Security.Principal.SecurityIdentifier]).Value)
                        if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
                            [string]::Empty
                        }
                        else {
                            $Local:SID
                        }
                    }
                    catch{
                        [string]::Empty
                    }
                }
            }
            
            if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
                Throw 'ERROR: Did not manage to get Intune user SID from SYSTEM context.'
            }
            else {
                $Local:SID
            }
        }
        else {
            [string]([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)
        }
    )

    # Registry - HKEY_USERS
    $Local:SID = [string]$(   
        $Local:SIDs=[string[]]@()
        $Local:SIDs=[string[]]@(Get-ChildItem -Path 'Regisstry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_ -like 'S-1-12-*' -and $_ -notlike '*_Classes'})
        if (@($Local:SIDs).Count -eq 0) {
            $Local:SIDs = [string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_ -notlike '.DEFAULT' -and $_ -notlike 'S-1-5-??' -and $_ -notlike '*_Classes'})
        }
        if(@($Local:SIDs).Count -eq 1){
            $Local:SIDs
        }
        elseif(@($Local:SIDs).Count -gt 1){
            $Local:SIDs = @($Local:SIDs | Where-Object {Test-Path -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC' -f ($_))})
            if(@($Local:SIDs).Count -eq 1){
                $Local:SIDs
            }
            else {
                [string]::Empty
            }
        }
        else{
            [string]::Empty
        }
    )


    # Explorer.exe
    $Local:SID = [string]$(
        $Local:UN = [string]([string[]]@(Get-WmiObject -Class 'Win32_Process' -Filter "Name='Explorer.exe'" -ErrorAction 'SilentlyContinue' | ForEach-Object {$($Owner = $_.GetOwner();if($Owner.ReturnValue -eq 0 -and $Owner.Domain -notlike 'nt *' -and $Owner.Domain -notlike 'nt-*'){('{0}\{1}' -f ($Owner.Domain,$Owner.User))})}) | Select-Object -Unique -First 1)
        if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.Length -lt 3) {
            $Local:UN = [string]([string[]]@(Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName' | Where-Object {$_ -notlike 'nt *' -and $_ -notlike 'nt-*'}) | Select-Object -Unique -First 1)
        }
        if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.Length -lt 3) {
            [string]::Empty
        }
        else {
            Try{
                $Local:SID = [string]([System.Security.Principal.NTAccount]::new($Local:UN).Translate([System.Security.Principal.SecurityIdentifier]).Value)
                if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
                    [string]::Empty
                }
                else {
                    $Local:SID
                }
            }
            catch{
                [string]::Empty
            }
        }
    )
#endregion Get Intune user SID - v2




#region    Get Intune user SID from Automate
    # Cozy
    [string]$(
        $Local:LengthInterval = [byte[]]@(40 .. 80)
        $Local:SID = [string]$(Try{$Local:SIDs = [string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_ -like 'S-1-12-*' -and $_ -notlike '*_Classes'});if(@($Local:SIDs).Count -eq 1){$Local:SIDs}else{[string]::Empty}}Catch{[string]::Empty})
        if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
            $Local:SID = [string]$(Try{[System.Security.Principal.NTAccount]::new(([string]([string[]]@(Get-WmiObject -Class 'Win32_Process' -Filter "Name='Explorer.exe'" -ErrorAction 'SilentlyContinue' | ForEach-Object {$($Owner = $_.GetOwner();if($Owner.ReturnValue -eq 0){('{0}\{1}' -f ($Owner.Domain,$Owner.User))})}) | Select-Object -Unique -First 1))).Translate([System.Security.Principal.SecurityIdentifier]).Value}catch{[string]::Empty})
        }
        if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
            $Local:SID = [string]$(Try{[System.Security.Principal.NTAccount]::new([string]([string[]]@(Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName') | Select-Object -Unique -First 1)).Translate([System.Security.Principal.SecurityIdentifier]).Value}catch{[string]::Empty})
        }
        if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
            $Local:SID = [string]$(Try{Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_ -notlike '.DEFAULT' -and $_ -notlike 'S-1-5-??' -and $_ -notlike '*_Classes'} | Sort-Object -Descending:$false | Select-Object -Last 1}Catch{[string]::Empty})
        }
        if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
            Throw 'ERROR: Did not manage to get Intune user SID from SYSTEM context'
        }
        else {
            $Local:SID
        }
    )
#endregion Get Intune user SID from Automate






# Get "Domain"\"UserName" from SID
$Script:StrUserIntuneSID = 'S-1-5-21-2580163292-722819548-3380774834-1001'



#region    Get "Domain"\"UserName"
[string]$(
    if ($Script:BoolIsSystem) {
        $Local:UN = [string]::Empty
        if ((-not([string]::IsNullOrEmpty($Script:StrUserIntuneSID)))) {
            $Local:UN = [string]$(Try{[System.Security.Principal.SecurityIdentifier]::new($Script:StrUserIntuneSID).Translate([System.Security.Principal.NTAccount]).Value}Catch{[string]::Empty})
        }
        if ([string]::IsNullOrEmpty($Local:UN)){
            $Local:UN = [string]$(Try{[string]([string[]]@(Get-WmiObject -Class 'Win32_Process' -Filter "Name='Explorer.exe'" -ErrorAction 'SilentlyContinue' | ForEach-Object {$($Owner = $_.GetOwner();if($Owner.ReturnValue -eq 0){('{0}\{1}' -f ($Owner.Domain,$Owner.User))})}) | Select-Object -Unique -First 1)}Catch{[string]::Empty})   
        }
        if ([string]::IsNullOrEmpty($Local:UN)) {
            $Local:UN = [string]$(Try{[string]([string[]]@(Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName') | Select-Object -Unique -First 1)}Catch{[string]::Empty})
        }   
        if ([string]::IsNullOrEmpty($Local:UN) -and (-not([string]::IsNullOrEmpty($Script:StrUserIntuneSID)))) {
            $Local:UN = [string]$(Try{$Local:x = Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Volatile Environment' -f ($Script:StrUserIntuneSID)) -Name 'USERDOMAIN','USERNAME';('{0}\{1}' -f ([string]($Local:x | Select-Object -ExpandProperty 'USERDOMAIN'),[string]($Local:x | Select-Object -ExpandProperty 'USERNAME')))}Catch{[string]::Empty}) 
        }
        if ([string]::IsNullOrEmpty($Local:UN)){
            Throw 'ERROR: Did not manage to get "Domain"\"UserName" for Intune User.'
        }
        else {
            $Local:UN
        }
    }
    else {
        [string]([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
    }
)
#endregion Get "Domain"\"UserName"
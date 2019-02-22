# Keep count of loaded profiles
$Script:RegistryLoadedProfiles = [string[]]@()



# Load User Profiles NTUSER.DAT (Registry) that is not available from current context
$PathProfileList = [string]('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList')
$SIDsProfileList = [string[]]@(Get-ChildItem -Path $PathProfileList -Recurse:$false | Select-Object -ExpandProperty 'Name' | ForEach-Object -Process {$_.Split('\')[-1]} | Where-Object -FilterScript {$_ -like 'S-1-12-*'})
foreach ($SID in $SIDsProfileList) {
    if (Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($SID)) -ErrorAction 'SilentlyContinue') {
        Write-Output -InputObject ('User with SID "{0}" is already logged in and/or NTUSER.DAT is loaded.' -f ($SID))
    }
    else {
        Write-Output -InputObject ('User with SID "{0}" is not logged in, thus NTUSER.DAT is not loaded into registry.' -f ($SID))
                    
        # Get User Directory
        $PathUserDirectory = [string]$(Get-ItemProperty -Path ('{0}\{1}' -f ($PathProfileList,$SID)) -Name 'ProfileImagePath' | Select-Object -ExpandProperty 'ProfileImagePath')
        if ([string]::IsNullOrEmpty($PathUserDirectory)) {
            Throw ('ERROR: No User Directory was found for user with SID "{0}".' -f ($SID))
        }

        # Get User Registry File, NTUSER.DAT
        $PathFileUserRegistry = ('{0}\NTUSER.DAT' -f ($PathUserDirectory))
        if (-not(Test-Path -Path $PathFileUserRegistry)) {
            Throw ('ERROR: "{0}" does not exist.' -f ($PathFileUserRegistry))
        }

        # Load NTUSER.DAT
        $null = Start-Process -FilePath ('{0}\reg.exe' -f ([string]([system.environment]::SystemDirectory))) -ArgumentList ('LOAD "HKEY_USERS\{0}" "{1}"' -f ($SID,$PathFileUserRegistry)) -WindowStyle 'Hidden' -Wait
        if (Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($SID))) {
            Write-Output -InputObject ('{0}Successfully loaded "{1}".' -f ("`t",$PathFileUserRegistry))
            $RegistryLoadedProfiles += @($SID)
        }
        else {
            Throw ('ERROR: Failed to load registry hive for SID "{0}", NTUSER.DAT location "{1}".' -f ($SID,$PathFileUserRegistry))
        }
    }
}




# Unload Users' Registry Profiles (NTUSER.DAT) if any were loaded
if (([string[]]@($RegistryLoadedProfiles | Where-Object -FilterScript {-not([string]::IsNullOrEmpty($_))})).Count -gt 0) {
    # Close Regedit.exe if running, can't unload hives otherwise
    $null = Get-Process -Name 'regedit' -ErrorAction 'SilentlyContinue' | ForEach-Object -Process{Stop-Process -InputObject $_ -ErrorAction 'SilentlyContinue'}
            
    # Get all logged in users
    $SIDsLoggedInUsers = [string[]]@(([string[]]@(Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty 'UserName' -Unique | ForEach-Object -Process {Try{[System.Security.Principal.NTAccount]::new(($_)).Translate([System.Security.Principal.SecurityIdentifier]).Value}Catch{}} | Where-Object -FilterScript {-not([string]::IsNullOrEmpty($_))}) + @([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value))) | Select-Object -Unique)

    foreach ($SID in $RegistryLoadedProfiles) {
        # If SID is found in $SIDsLoggedInUsers - Don't Unload Hive
        if ([bool]$(([string[]]@($SIDsLoggedInUsers | ForEach-Object -Process {$_.Trim().ToUpper()})).Contains($SID.Trim().ToUpper()))) {
            Write-Output -InputObject ('User with SID "{0}" is currently logged in, will not unload registry hive.' -f ($SID))
        }
        # If SID is not found in $SIDsLoggedInUsers - Unload Hive
        else {
            $PathUserHive = [string]('HKEY_USERS\{0}' -f ($SID))
            $null = Start-Process -FilePath ('{0}\reg.exe' -f ([string]([system.environment]::SystemDirectory))) -ArgumentList ('UNLOAD "{0}"' -f ($PathUserHive)) -WindowStyle 'Hidden' -Wait

            # Check success
            if (Test-Path -Path ('Registry::{0}' -f ($PathUserHive)) -ErrorAction 'SilentlyContinue') {
                Write-Output -InputObject ('ERROR: Failed to unload user registry hive "{0}".' -f ($PathUserHive)) -ErrorAction 'Continue'
            }
            else {
                Write-Output -InputObject ('Successfully unloaded user registry hive "{0}".' -f ($PathUserHive))
            }
        }
    }
}
# Help variables
[bool] $Script:HasChanged = $false

# Get all Fixed volumes
[string] $SystemDriveLetter = [string]$(if(-not([string]::IsNullOrEmpty($env:SystemDrive))){$env:SystemDrive.Trim(':')}else{[System.Environment]::SystemDirectory.Split(':')[0]}).ToUpper()
[string[]] $Volumes         = @($SystemDriveLetter) + @(Get-Volume -Verbose:$false | Where-Object {
    $_.'DriveLetter' -and $_.'DriveType' -eq 'Fixed' -and (@('NTFS','REFS').Contains([string]($_.FileSystem).ToUpper())) -and $_.'DriveLetter'.ToString().ToUpper() -ne $SystemDriveLetter
} | Select-Object -ExpandProperty 'DriveLetter')


# Loop all fixed volumes
:LoopAllFixedVolumes foreach ($Volume in $Volumes) {
    # Get BitLocker Info
    $BitLockerVolume = Get-BitLockerVolume -MountPoint $Volume

    # Skip if not encrypted or no RecoveryPassword Exist
    if ($BitLockerVolume.VolumeStatus -ne 'FullyEncrypted' -or $RecoveryPasswordsBefore.Count -le 0) {Continue LoopAllFixedVolumes}

    # Get all Existing RecoveryPasswords on the volume BEFORE adding a new one
    $RecoveryPasswordsBefore = @($BitLockerVolume | Select-Object -ExpandProperty KeyProtector | Where-Object -Property 'KeyProtectorType' -EQ 'RecoveryPassword')

    # Add
    $null = Add-BitLockerKeyProtector -MountPoint $env:SystemDrive -RecoveryPasswordProtector -WarningAction 'SilentlyContinue'

    # Get all Existing RecoveryPasswords on the volume AFTER adding a new one
    $RecoveryPasswordsAfter  = @(Get-BitLockerVolume -MountPoint $Volume | Select-Object -ExpandProperty KeyProtector | Where-Object -Property 'KeyProtectorType' -EQ 'RecoveryPassword')

    # Remove all but the newly created
    if ($RecoveryPasswordsAfter.Count -gt $RecoveryPasswordsBefore.Count) {
        $Script:HasChanged = $true
        foreach ($KeyProtectorId in [string[]]@($RecoveryPasswordsBefore | Select-Object -ExpandProperty 'KeyProtectorId')) {
            $null = Remove-BitLockerKeyProtector -MountPoint $Volume -KeyProtectorId $KeyProtectorId
        }
    }
}


# If anything changed, and if Ironstone IT "IronTrigger" is present => Trigger a run
if ($Script:HasChanged) {
    $IronTrigger = Get-ScheduledTask -TaskName 'IronTrigger'
    if ($? -and -not [string]::IsNullOrEmpty( $IronTrigger.TaskName)) {
        $null = Start-ScheduledTask -InputObject $IronTrigger
    }
}
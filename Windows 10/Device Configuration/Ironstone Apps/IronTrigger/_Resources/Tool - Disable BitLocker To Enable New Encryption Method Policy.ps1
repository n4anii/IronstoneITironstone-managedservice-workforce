# Help variables
$Script:HasChanged = [bool] $false

# Get all Fixed volumes
$SystemDriveLetter = [string]$(if(-not([string]::IsNullOrEmpty($env:SystemDrive))){$env:SystemDrive.Trim(':')}else{[System.Environment]::SystemDirectory.Split(':')[0]}).ToUpper()
$Volumes           = [string[]]@(@($SystemDriveLetter) + @(Get-Volume -Verbose:$false | Where-Object {
    $_.'DriveLetter' -and $_.'DriveType' -eq 'Fixed' -and (@('NTFS','REFS').Contains([string]($_.FileSystem).ToUpper())) -and $_.'DriveLetter'.ToString().ToUpper() -ne $SystemDriveLetter
} | Select-Object -ExpandProperty 'DriveLetter'))


# Loop all fixed volumes
:LoopAllFixedVolumes foreach ($Volume in $Volumes) {
    # Get BitLocker Info
    $BitLockerVolume = Get-BitLockerVolume -MountPoint $Volume

    # Skip if not encrypted or no RecoveryPassword Exist
    if (($BitLockerVolume | Select-Object -ExpandProperty 'VolumeStatus') -ne 'FullyEncrypted') {Continue LoopAllFixedVolumes}

    # Disable BitLocker for current Volume
    Write-Output -InputObject ('{0} - Disabling BitLocker.' -f ($Volume))
    $null = Disable-BitLocker -MountPoint $env:SystemDrive -WarningAction 'SilentlyContinue' -Confirm:$false
    
    # Check for success
    Write-Output -InputObject ('   Success? {0}' -f (($Local:Success = [bool]($? -and (Get-BitLockerVolume -MountPoint $Volume).VolumeStatus -ne 'FullyEncrypted')).ToString()))
    if ($Local:Success) {$Script:HasChanged = $true}
}


# If anything changed, and if Ironstone IT "IronTrigger" is present => Set to run every 15 minute
if ($Script:HasChanged) {
    $IronTrigger = Get-ScheduledTask -TaskName 'IronTrigger'
    if ($? -and -not [string]::IsNullOrEmpty( $IronTrigger.TaskName)) {
        $IronTrigger.Triggers = (New-ScheduledTaskTrigger -Once -At ([DateTime]::Today) -RepetitionInterval ([TimeSpan]::FromMinutes(15)))
        $null = Set-ScheduledTask -InputObject $IronTrigger
    }
}
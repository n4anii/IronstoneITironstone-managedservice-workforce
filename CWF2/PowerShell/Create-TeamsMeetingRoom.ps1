<#
     .SYNOPSIS
        https://learn.microsoft.com/en-us/microsoftteams/rooms/bookable-desks
        Create Bookable desks and Meeting Rooms for Teams. 

    .NOTES
        Version: 1.0.0.0
        Author: Herman Bergsløkken /IronstoneIT
        Creation Date: 31.07.2024
        Purpose/Change: Initial script development
#>

$UserPrincipalName = "adm-herman.bergslokken@ironstoneit.com"
# Uncomment WhatIfPreference to run script in WhatIf mode
#$WhatIfPreference = $true

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Applocker Check
if ($ExecutionContext.SessionState.LanguageMode -eq "ConstrainedLanguage") {
    throw "This script must be run with administrative privileges"
}

$RequiredModules = @('ExchangeOnlineManagement')

foreach ($Module in $RequiredModules) {
    if (-not(Get-Module $Module -ListAvailable)) {
        Install-Module -Name $Module -Force -ErrorAction Stop
    }
    Import-Module $Module -ErrorAction Stop
}

Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName 

try {
    Write-Output "Checking connectivity to exchange online....."
    Get-AcceptedDomain -ErrorAction Stop
}
catch [System.Management.Automation.CommandNotFoundException] {
    Write-Output "Connection to Exchange Online seems to have failed. Please connect again!"
}

# Define the required parameters for workspaces and meeting rooms
$Rooms = @(
    #[PSCustomObject]@{ Name = "Arbeidsrom Stingray";   Alias = "Stingray";   Type = "Workspace"; MinimumDurationInMinutes = 60; MaxDurationInMinutes = 480; Capacity = 2; Floor = 4; Building = "Øvre Vollgate"; City = "Oslo"; CountryOrRegion = "Norway"; FloorLabel = "4. Etasje"}
    #[PSCustomObject]@{ Name = "Arbeidsrom SmartCraft"; Alias = "SmartCraft"; Type = "Workspace"; MinimumDurationInMinutes = 60; MaxDurationInMinutes = 480; Capacity = 1; Floor = 4; Building = "Øvre Vollgate"; City = "Oslo"; CountryOrRegion = "Norway"; FloorLabel = "4. Etasje"}
    #[PSCustomObject]@{ Name = "Arbeidsrom Eltek";      Alias = "Eltek";      Type = "Workspace"; MinimumDurationInMinutes = 60; MaxDurationInMinutes = 480; Capacity = 1; Floor = 4; Building = "Øvre Vollgate"; City = "Oslo"; CountryOrRegion = "Norway"; FloorLabel = "4. Etasje"}
    #[PSCustomObject]@{ Name = "Arbeidsrom Møller";     Alias = "Moller";     Type = "Workspace"; MinimumDurationInMinutes = 60; MaxDurationInMinutes = 480; Capacity = 1; Floor = 4; Building = "Øvre Vollgate"; City = "Oslo"; CountryOrRegion = "Norway"; FloorLabel = "4. Etasje"}
    #[PSCustomObject]@{ Name = "Møterom Bergans";       Alias = "Bergans";    Type = "Room";      MinimumDurationInMinutes = 60; MaxDurationInMinutes = 480; Capacity = 8; Floor = 4; Building = "Øvre Vollgate"; City = "Oslo"; CountryOrRegion = "Norway"; FloorLabel = "4. Etasje"}
)

# Loop through each room and create the mailbox if it doesn't exist
foreach ($Room in $Rooms) {

    if ($Room.Alias -match '[ÆØÅ]') {
        Throw "Alias $($Room.Alias) contains one or more of the invalid characters: Æ, Ø, or Å!"
    }
    
    $Mailbox = Get-Mailbox -Identity $Room.Alias -ErrorAction SilentlyContinue
    if (-not($Mailbox)) {
        Write-Output "Creating $($Room.Name)"
        # Get all properties by running Get-Place -Identity $Room.Alias | Format-List *
        New-Mailbox -Name $Room.Name -Alias $Room.Alias -Room | Set-Mailbox -Type $Room.Type
    }
    else {
        Write-Output "$($Room.Name) Already exists!"
    }

    Start-sleep -Seconds 5

    Write-Output "Set the mailbox properties"
    Set-Place -Identity $Room.Alias -Capacity $Room.Capacity -Floor $Room.Floor -Building $Room.Building -City $Room.City -State $Room.State -CountryOrRegion $Room.CountryOrRegion -FloorLabel $Room.FloorLabel

    # Get all Properties by running Get-CalendarProcessing -Identity $Room.Alias | Format-List *
    Write-Output "Set the calendar processing properties"
    Set-CalendarProcessing -Identity $Room.Alias -EnforceCapacity $True -MinimumDurationInMinutes $Room.MinimumDurationInMinutes -MaximumDurationInMinutes $Room.MaxDulrationInMinutes 
}

Disconnect-ExchangeOnline -Confirm:$false
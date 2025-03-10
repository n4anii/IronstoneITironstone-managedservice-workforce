###############################################################################################################
## This PowerShell script adds the teams backgrund to "$env:APPDATA\Microsoft\Teams\Backgrounds\Uploads"     ##               
##"$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Backgrounds\Uploads"        ##
## Author: Stefan Petrovic | Ironstone | 10.03.2025                                                          ##   
###############################################################################################################


#---------------------------------------------------------------------------------------------------------------------------#


# Define the paths for the old and new Teams versions
$OldTeamsPath = "$env:APPDATA\Microsoft\Teams\Backgrounds\Uploads"
$NewTeamsPath = "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Backgrounds\Uploads"

# Set the new background image path (Replace with your actual image file)
$NewBackgroundImage = "C:\Path\To\Your\Background.jpg"

# Function to copy background image
Function Copy-Background {
    param (
        [string]$Destination
    )

    # Ensure the destination folder exists
    if (!(Test-Path $Destination)) {
        Write-Host "Creating directory: $Destination"
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    # Copy the background image
    Copy-Item -Path $NewBackgroundImage -Destination $Destination -Force
    Write-Host "New background set in: $Destination"
}

# Check which Teams version is installed
if (Test-Path $OldTeamsPath) {
    Write-Host "Old Microsoft Teams detected. Updating background..."
    Copy-Background -Destination $OldTeamsPath
} 

if (Test-Path $NewTeamsPath) {
    Write-Host "New Microsoft Teams detected. Updating background..."
    Copy-Background -Destination $NewTeamsPath
}

Write-Host "Background update complete!"

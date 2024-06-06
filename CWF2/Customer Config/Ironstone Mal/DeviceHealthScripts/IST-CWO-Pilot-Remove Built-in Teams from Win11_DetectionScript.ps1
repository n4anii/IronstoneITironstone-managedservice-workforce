# Set this variable to $true for remediation, or $false for detection
$Remediate = $false

$AppName = "MicrosoftTeams"

function Find-App {
    param (
        [string]$AppName
    )
    $AppDetected = Get-AppxPackage -Name $AppName -AllUsers -ErrorAction SilentlyContinue
    if ($AppDetected) {
        Write-Host "$AppName Detected"
        exit 1
    } else {
        Write-Host "$AppName Not Detected"
        exit 0
    }
}
function Remove-App {
    param (
        [string]$AppName
    )
    $ErrorActionPreference = 'SilentlyContinue'
    # Suppress all error messages
    $null = Get-AppxPackage -Name $AppName -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    $null = Get-AppXProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $AppName } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

try {
    if ($Remediate -eq $true) {
        Remove-App -AppName $AppName
        # Re-check for the app presence
        if (-not(Find-App -AppName $AppName)) {
            Write-Host "$AppName Successfully Removed"
            exit 0
        } else {
            Write-Host "$AppName Detected After Remediation"
            exit 1
        }
    } elseif ($Remediate -eq $false) {
        Find-App -AppName $AppName
    }
} catch {
    $errMsg = $_.Exception.Message
    Write-Error "Error: $errMsg"
}
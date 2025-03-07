# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host ""
    Write-Host "***************************************************"
    Write-Host "* This script needs to be run as administrator.   *"
    Write-Host "* Please close the script, right-click and choose  *"
    Write-Host '*         "Run as administrator"                  *'
    Write-Host "***************************************************"
    exit
}

# Windows Update service (actual service name is wuauserv)
$ServiceName = "wuauserv"
$DeletionDone = $false

Write-Host "Attempting to stop Windows Update service..."
try {
    Stop-Service -Name $ServiceName -Force -ErrorAction Stop
} catch {
    Write-Host "Failed to stop $($ServiceName): $($_)"
}

# Loop until the service is running again
do {
    Clear-Host
    # Retrieve service details using CIM
    $svc = Get-CimInstance -ClassName Win32_Service -Filter "Name='$ServiceName'"

    # Change startup type to automatic if needed
    if ($svc.StartMode -ne "Auto") {
        Write-Host "Service startup type is $($svc.StartMode). Changing startup type to auto."
        Set-Service -Name $ServiceName -StartupType Automatic
    }

    if ($svc.State -eq "Stop Pending") {
        Write-Host "Windows Update service is in state $($svc.State)."
        Write-Host "Stopping Windows Update service by killing PID $($svc.ProcessId)..."
        if ($svc.ProcessId -and $svc.ProcessId -ne 0) {
            try {
                Stop-Process -Id $svc.ProcessId -Force -ErrorAction Stop
            } catch {
                Write-Host "Failed to kill process $($svc.ProcessId): $($_)"
            }
        }
    }
    elseif ($svc.State -eq "Start Pending") {
        Write-Host "Windows Update service is in state $($svc.State). Waiting..."
    }
    elseif ($svc.State -eq "Stopped") {
        Write-Host "Windows Update service is in state $($svc.State)."
        if (-not $DeletionDone) {
            Write-Host "Deleting contents of C:\Windows\SoftwareDistribution\ ..."
            try {
                Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction Stop
                $DeletionDone = $true
            } catch {
                Write-Host "Failed to delete contents: $($_)"
            }
        }
        Write-Host "Attempting to start Windows Update service..."
        try {
            Start-Service -Name $ServiceName -ErrorAction Stop
        } catch {
            Write-Host "Failed to start $($ServiceName): $($_)"
        }
    }
    
    Start-Sleep -Seconds 5
    # Refresh service information
    $svc = Get-CimInstance -ClassName Win32_Service -Filter "Name='$ServiceName'"
} while ($svc.State -ne "Running")

Write-Host "Windows Update service is in state $($svc.State)"
Write-Host "Restart was successful!"

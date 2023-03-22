[int]$WindowsVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId

Try {
    
    Import-Module HP.ClientManagement, HP.Private

    if ((Confirm-SecureBootUEFI) -and ($WindowsVersion -gt 1709)) {
        if (Get-HPBIOSUpdates -Check) {        
            Write-Output "Compliant"
            Exit 0
        } else {
            Write-Warning "Not Compliant"
            #Write-Host "BIOS Update Required"
            Exit 1
        }
    } else {
            Write-Warning "Not Compliant"
            #Write-Host "Failed Secure or OS Check"
            Exit 1
        }
} 
Catch {
    Write-Warning "Not Compliant"
    #Write-Host "Catch"
    #Write-Host $_
    Exit 1
}
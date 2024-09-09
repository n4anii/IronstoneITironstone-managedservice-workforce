try {
    # Get all local user accounts
    $accounts = Get-LocalUser

    # Find the local Administrator account using the SID ending with -500 and named 'lapsadmin'
    $adminAccount = $accounts | Where-Object { $_.SID -match '-500$' }

    if ($adminAccount) {
        if ($adminAccount.Name -ne 'lapsadmin') {
            Write-Output "The local Administrator account is not named 'lapsadmin'. Remediation cannot be applied."
            exit 1
        }
        if ($adminAccount.Enabled -eq $false) {
            Write-Output "The 'lapsadmin' account is deactivated. Activating the account..."
            # Activate the account if it is deactivated
            Enable-LocalUser -Name $adminAccount.Name
            Write-Output "The 'lapsadmin' account has been activated."
            exit 0
        } else {
            Write-Output "The 'lapsadmin' account is already activated."
            exit 0
        }
    } else {
        Write-Output "The local Administrator account was not found."
        exit 1
    }
} catch {
    Write-Output "An error occurred: $_"
    exit 1
}

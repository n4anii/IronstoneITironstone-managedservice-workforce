try {
    # Get all local user accounts
    $accounts = Get-LocalUser

    # Find the local Administrator account using the SID ending with -500
    $adminAccount = $accounts | Where-Object { $_.SID -match '-500$' }

    if ($adminAccount) {
        if ($adminAccount.Enabled -eq $true) {
            Write-Output "The local Administrator account is activated."
            exit 0
        } else {
            Write-Output "The local Administrator account is deactivated."
            exit 1
        }
    } else {
        Write-Output "The local Administrator account was not found."
        exit 1
    }
} catch {
    Write-Output "An error occurred: $_"
    exit 1
}

#Set the registry key that enables the device to report the OneDrive sync status to the OneDrive Report

New-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\OneDrive -Name EnableSyncAdminReports -Value 1
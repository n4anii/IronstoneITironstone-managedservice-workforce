# Company Portal
[System.IO.Directory]::Exists('{0}\WindowsApps\Microsoft.CompanyPortal_10.3.4991.0_x64__8wekyb3d8bbwe' -f ($env:ProgramW6432))


# Citrix Workspace App
[System.IO.Directory]::Exists('{0}\WindowsApps\D50536CD.CitrixReceiver_19.7.11.0_x86__hmf6bx7z76t54' -f ($env:ProgramW6432))


# General / testing
[System.IO.Directory]::Exists('{0}\WindowsApps' -f ($env:ProgramW6432))
[System.IO.Directory]::Exists('{0}\WindowsApps' -f (${env:ProgramFiles(x86)}))
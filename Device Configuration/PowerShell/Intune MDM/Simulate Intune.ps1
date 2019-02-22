<#
    Run as NT Authority\SYSTEM user
        PsExec64.exe -s -i powershell.exe
#>


$PathFilePs1 = 'C:\Users\OlavRønnestadBirkela\OneDrive - Ironstone\Documents - Work\Script & Code\PowerShell - Intune MDM\Software - Configure\Configure - Citrix Workspace\User_Config-CitrixWorkspaceApp(Customer)\Backe\Current Uploaded to Intune\User_Config-CitrixWorkspace(Backe).ps1'

# Run PS1 file
& ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile -File $PathFilePs1
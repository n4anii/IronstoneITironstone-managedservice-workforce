# Find EXE's in \Files directory and install. Add parameters as required
Execute-Process -Path (Get-ChildItem -Path "$dirFiles\*.exe").FullName -Parameters "" 

# Find MSI's in \Files directory and install. Remove "-AddParameters" if no custom parameters are required
Execute-MSI -Action Install -Path (Get-ChildItem -Path "$dirFiles\*.msi").FullName -AddParameters ""

# Import HKLM settings from reg-file found in \Files Directory
Execute-Process -FilePath $env:windir\System32\reg.exe -Parameters "IMPORT `"$dirFiles\name-of-reg-export.reg`""
        
# Import HKCU settings from reg-file found in \Files Directory. (Will use a scheduled task to run the commandline as the logged on user) This will run with the users privilege level
Execute-ProcessAsUser -Path $env:windir\System32\reg.exe -Parameters "IMPORT `"$dirFiles\HKCU.reg`""

$WingetInstall = @(
    [PSCustomObject]@{
        Name = "Microsoft Visual Studio Code (User)"; #Run Winget list on target machine to get ID and Name
        ID = "Microsoft.VisualStudioCode"; 
        Version = $null; #Only include version if absolutely necessary. If not supplied Winget will install newest version
        Scope = "User"; #User/Machine
    },
    [PSCustomObject]@{
        Name = "Microsoft Visual C++ 2015-2022 Redistributable (x86)"; #Run Winget list on target machine to get ID and Name
        ID = "Microsoft.VCRedist.2015+.x86"; 
        Version = $null; #Only include version if absolutely necessary. If not supplied Winget will install newest version
        Scope = "Machine"; #User/Machine
    },
    [PSCustomObject]@{
        Name = "Microsoft Visual C++ 2015-2022 Redistributable (x64)"; #Run Winget list on target machine to get ID and Name
        ID = "Microsoft.VCRedist.2015+.x64"; 
        Version = $null; #Only include version if absolutely necessary. If not supplied Winget will install newest version
        Scope = "Machine"; #User/Machine
    }
)

$winget_exe = Get-WingetPath
foreach ($App in $WingetInstall) {
    if ($winget_exe) {
        Show-InstallationProgress "Installing $($App.Name)"
        $Scope = if ($env:USERNAME -like "$env:COMPUTERNAME*") { "Machine" } else { "User" }
        $VersionParam = if ($App.Version) { "--version $($App.Version)" } else { "" }
        $CommandLineArgs = "Install --id $($App.ID) --scope $($App.Scope) --silent --force --accept-package-agreements --accept-source-agreements"

        if ($Scope -eq $App.Scope) {
            Write-Log -Message "Installing $($App.Name) with Winget as $Scope"
            Write-Log -Message "Executing this command line: `"$winget_exe`" $CommandLineArgs"
            CMD /C "`"$winget_exe`" $CommandLineArgs"
            # Execute-Process -FilePath `"$winget_exe`" -Parameters "$CommandLineArgs"
        } else {
            Write-Log -Message "Installing $($App.Name) with Winget as $($App.Scope) is not possible in current scope $Scope. App will not be installed!" -Severity "2"
        }
    }
}
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
#Example on how to properly check for prereqs.This is to prevent the accidental downgrading of already installed software.
#region Prereqs
$RequiredPrereqs = [PSCustomObject]@{
    "Microsoft Visual C++ 2015-2022 Redistributable (x64)" = @{
        Version = "14.40.33810.0"
        InstallationFile = "vc_redist2022_x64.exe"
        Parameters = "/install /passive /norestart"
    }
    "Microsoft Visual C++ 2015-2022 Redistributable (x86)" = @{
        Version = "14.40.33810.0"
        InstallationFile = "vc_redist2022_x86.exe"
        Parameters = "/install /passive /norestart"
    }
    "Microsoft Edge WebView2 Runtime" = @{
        Version = "127.0.0.0"
        InstallationFile = "MicrosoftEdgeWebView2RuntimeInstallerX64.exe"
        Parameters = "/silent /install"
    }
    "Microsoft SQL Server 2012 Native Client" = @{
        Version = "11.4.7001.0"
        InstallationFile = "sqlncli_x64.msi"
        Parameters = "IACCEPTSQLNCLILICENSETERMS=YES"
    }
    "Microsoft OLE DB Driver for SQL Server" = @{
        Version = "18.3.0.0"
        InstallationFile = "msoledbsql_18.3.0.0_x64.msi"
        Parameters = "IACCEPTMSOLEDBSQLLICENSETERMS=YES"
    }
}

# Check if the Prereqs is installed and if the version is up-to-date
foreach ($Software in $RequiredPrereqs.PSObject.Properties) {
    $Name = $Software.Name
    $RequiredVersion = $Software.Value.Version

    $InstalledPackage = $InstalledPackages | Where-Object { $_.Name -like "*$Name*" }

    if ($InstalledPackage) {
        $InstalledVersion = $InstalledPackage.Version
        if (Compare-Version -InstalledVersion $InstalledVersion -RequiredVersion $RequiredVersion) {
            Write-Log -Message "$Name is installed and up-to-date (Version: $InstalledVersion)"
        } else {
            Write-Log -Message "$Name is installed but not up-to-date (Installed Version: $InstalledVersion, Required Version: $RequiredVersion)"
        }
    } else {
        Write-Log -Message "$Name is not installed"

        # Determine the installation file type and install
        $InstallationFile = Get-ChildItem -Path "$DirFiles\PreRequisites\$($Software.Value.InstallationFile)"
        if ($InstallationFile -like "*.exe") {
            Show-InstallationProgress "Installing $Name"
            Execute-Process -Path $InstallationFile.FullName -Parameters $Software.Value.Parameters
        } elseif ($InstallationFile -like "*.msi") {
            Show-InstallationProgress "Installing $Name"
            Execute-MSI -Action Install -Path $InstallationFile.FullName -AddParameters $Software.Value.Parameters
        } else {
            Write-Log -Message "Installation file for $Name not found."
        }
    }
}

#endregion

$WingetPath = Get-WingetPath
$WingetLogFilePath = "$Env:TEMP\Winget"
foreach ($App in $WingetInstall) {
    if ($WingetPath) {
        Show-InstallationProgress "Installing $($App.Name)"
        $Scope = if ($env:USERNAME -like "$env:COMPUTERNAME*") { "Machine" } else { "User" }
        $VersionParam = if ($App.Version) { "--version $($App.Version)" } else { "" }
        $CommandLineArgs = "install --id $($App.ID) --exact --scope $($App.Scope) --silent --force --accept-package-agreements --accept-source-agreements --disable-interactivity --log $WingetLogFilePath"

        if ($Scope -eq $App.Scope) {
            Write-Log -Message "Installing $($App.Name) with Winget as $Scope"
            Write-Log -Message "Executing this command line: `"$WingetPath`" $CommandLineArgs"
            Set-Location -Path $WingetPath
            & .\Winget.exe $CommandLineArgs
            Pop-Location
            # Execute-Process -FilePath `"$WingetPath\Winget.exe`" -Parameters "$CommandLineArgs"
        } else {
            Write-Log -Message "Installing $($App.Name) with Winget as $($App.Scope) is not possible in current scope $Scope. App will not be installed!" -Severity "2"
        }
    }
}
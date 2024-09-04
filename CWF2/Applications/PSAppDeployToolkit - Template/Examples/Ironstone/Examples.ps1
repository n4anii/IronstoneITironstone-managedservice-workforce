# Find EXE in \Files directory and install. Add parameters as required
Execute-Process -Path (Get-ChildItem -Path "$dirFiles\*.exe").FullName -Parameters "" 

# Find MSI in \Files directory and install. Remove "-AddParameters" if no custom parameters are required
Execute-MSI -Action Install -Path (Get-ChildItem -Path "$dirFiles\*.msi").FullName -AddParameters ""

# Import HKLM settings from reg-file found in \Files Directory
Execute-Process -FilePath $env:windir\System32\reg.exe -Parameters "IMPORT `"$dirFiles\name-of-reg-export.reg`""
        
# Import HKCU settings from reg-file found in \Files Directory. (Will use a scheduled task to run the commandline as the logged on user) This will run with the users privilege level
Execute-ProcessAsUser -Path $env:windir\System32\reg.exe -Parameters "IMPORT `"$dirFiles\HKCU.reg`""

# Example on how to properly check for prereqs. This is to prevent the accidental downgrading of already installed software.
#region Prereqs
$RequiredPrereqs = [PSCustomObject]@{
    "Microsoft Visual C++ 2015-2022 Redistributable (x64)" = @{
        Version = "14.40.33810.0"
        InstallationFile = "vc_redist.x64.exe"
        Parameters = "/install /passive /norestart"
        URL = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
    }
    "Microsoft Visual C++ 2015-2022 Redistributable (x86)" = @{
        Version = "14.40.33810.0"
        InstallationFile = "vc_redist.x86.exe"
        Parameters = "/install /passive /norestart"
        URL = "https://aka.ms/vs/17/release/vc_redist.x86.exe"
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

# Ensure $InstalledPackages is defined
$InstalledPackages = Get-Package

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

        if ($Software.Value.URL) {
            Show-InstallationProgress "Downloading $Name"
            $DownloadFolder = "$dirFiles\PreRequisites"
            if (-not (Test-Path -Path $DownloadFolder)) {
                Write-Log -Message "Creating $DownloadFolder"
                New-Item -Path $DownloadFolder -ItemType Directory -Force | Out-Null
            }
            try {
                [string]$PathFileOut = "$DownloadFolder\$($Software.Value.InstallationFile)"
                Start-BitsTransfer -Source $($Software.Value.URL) -Destination $PathFileOut -ErrorAction Stop
                Write-Log -Message "All files downloaded successfully to $PathFileOut"
            } catch {
                Write-Log -Message "An error occurred while downloading $Name : $_"
            }
        }

        # Determine the installation file type and install
        $InstallationFile = Get-ChildItem -Path "$dirFiles\PreRequisites\$($Software.Value.InstallationFile)"
        if ($InstallationFile -like "*.exe") {
            Show-InstallationProgress "Installing $Name"
            Execute-Process -Path $InstallationFile.FullName -Parameters $Software.Value.Parameters
        } elseif ($InstallationFile -like "*.msi") {
            Show-InstallationProgress "Installing $Name"
            Execute-MSI -Action Install -Path $InstallationFile.FullName -AddParameters $Software.Value.Parameters
        } elseif ($InstallationFile -like "Winget") {
            Show-InstallationProgress "Installing $Name"
        } else {
            Write-Log -Message "Installation file for $Name not found."
        }
    }
}

#endregion

$WingetInstall = @(
    [PSCustomObject]@{
        Name = "Microsoft Visual Studio Code (User)"; #Run Winget list on target machine to get ID and Name
        ID = "Microsoft.VisualStudioCode"; 
        Version = $null; #Only include version if absolutely necessary. If not supplied Winget will install newest version
        Scope = "User"; #User/Machine
    },
    [PSCustomObject]@{
        Name = "Microsoft Visual C++ 2015-2022 Redistributable (x86)"; 
        ID = "Microsoft.VCRedist.2015+.x86"; 
        Version = $null; 
        Scope = "Machine"; 
    },
    [PSCustomObject]@{
        Name = "Microsoft Visual C++ 2015-2022 Redistributable (x64)"; 
        ID = "Microsoft.VCRedist.2015+.x64"; 
        Version = $null; 
        Scope = "Machine"; 
    },
    [PSCustomObject]@{
        Name = "7-Zip"; 
        ID = "7zip.7zip"; 
        Version = $null; 
        Scope = "Machine"; 
    }
)

[string]$WingetDirectory = Get-WingetPath
if ($WingetDirectory) {
    Set-Location -Path $WingetDirectory
    foreach ($App in $WingetInstall) {
        Show-InstallationProgress "Installing $($App.Name)"
        $Scope = if ($env:USERNAME -like "$env:COMPUTERNAME*") {"machine"} else {"user"}
        $VersionParam = if ($App.Version) {"--version $($App.Version)"} else {""}
        $CommandLineArgs = "install --id $($App.ID) --exact --scope $Scope --accept-package-agreements --accept-source-agreements --silent --disable-interactivity --log $Global:WingetLogFilePath"  -replace "\s{2,}", " "
        if ($Scope -eq $App.Scope) {
            Write-Log -Message "Installing $($App.Name) with Winget as $Scope"
            Write-Log -Message "Executing this command line: .\Winget.exe $CommandLineArgs"
            .\Winget.exe install --id $($App.ID) --exact --scope $Scope --accept-package-agreements --accept-source-agreements --silent --disable-interactivity --log $Global:WingetLogFilePath
            Start-Sleep -Seconds 10
        } else {
            Write-Log -Message "Installing $($App.Name) with Winget as $($App.Scope) is not possible in current scope $Scope. App will not be installed!" -Severity "2"
        }
    }
}
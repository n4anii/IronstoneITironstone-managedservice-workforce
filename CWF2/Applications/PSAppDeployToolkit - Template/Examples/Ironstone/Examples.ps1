# Find EXE in \Files directory and install. Add parameters as required
Execute-Process -Path (Get-ChildItem -Path "$dirFiles\*.exe").FullName -Parameters "" 

# Find MSI in \Files directory and install. Remove "-AddParameters" if no custom parameters are required
Execute-MSI -Action Install -Path (Get-ChildItem -Path "$dirFiles\*.msi").FullName -AddParameters ""

# Import HKLM settings from reg-file found in \Files Directory
Execute-Process -FilePath $env:windir\System32\reg.exe -Parameters "IMPORT `"$dirFiles\name-of-reg-export.reg`""
        
# Import HKCU settings from reg-file found in \Files Directory. (Will use a scheduled task to run the commandline as the logged on user) This will run with the users privilege level
Execute-ProcessAsUser -Path $env:windir\System32\reg.exe -Parameters "IMPORT `"$dirFiles\HKCU.reg`""

#region Prereqs
# Example on how to properly check for prereqs. This is to prevent the accidental downgrading of already installed software.
# Will automatically download if "URL" is present. 
# For other Prereqs they must be in the Prereqs folder in $dirFiles\PreRequisites
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

Test-InstallPrereqs -RequiredPrereqs $RequiredPrereqs

#endregion

#region Apps to Remove
# Example on how to uninstall applications
$AppsToRemove = @(
    @{
        Name = "Example_*7-Zip*" #Check Appwiz.cpl for correct name. Wildcards are supporterd.
        Type = "msi"
    },
    @{
        Path = "Example_C:\Program Files\7-Zip\Uninstall.exe" #Supports wildcards
        Parameters = "/S"
        Type = "exe"
        IgnoreExitCodes = "$false" # Add ExitCodes to ignore when uninstalling. IgnoreExitCodes = "1,2,3"
    },
    @{
        Name = "Example_E046963F.LenovoSettingsforEnterprise" # Run Get-AppxPackage | Select-Object Name, version
        Type = "AppX"
    },
    @{
        Name = "Example_Notepad++ (64-bit x64)" # Run Winget list on target machine to get ID and Name
        ID = "Example_Notepad++.Notepad++"
        Scope = "User" # User/Machine
        Type = "Winget"
    }
)
Uninstall-Apps -AppsToRemove $AppsToRemove
#endregion

#region Cleanups
$Cleanups = @(
    "Example_C:\Programdata\AdobeR",
    "Example_HKLM:\Software\Adobe\AcrobatR",
    "Example_C:\Users\*\AppData\Local\AcrobatR"
)
Remove-Leftovers -Cleanups $Cleanups
#endregion

#region Winget
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
#endregion
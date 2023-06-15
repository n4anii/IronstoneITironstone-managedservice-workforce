<#
    .NAME
        User_AddIEZoneMapDomains().ps1
        Device_AddIEZoneMapDomains().ps1
    
    .SYNOPSIS
        Adds IE Zone map domains, to user context if not run by SYSTEM, else in SYSTEM context.

    .NOTES
        Author:   Olav Rønnestad Birkeland
        Created:  201127
        Modified: 201127

        Domain
            'lync.com' in the list means 'http://*.lync.com','http://www.*.lync.com','https://*.lync.com','http://www.*.lync.com'

        Setting
            0 = My computer
            1 = Local intranet zone
            2 = Trusted sites zone
            3 = Internet zone
            4 = Restricted sites zone

        Resources
          * https://support.microsoft.com/en-us/help/182569/internet-explorer-security-zones-registry-entries-for-advanced-users

    .EXAMPLE
        # Run from PowerShell ISE
        & $psISE.'CurrentFile'.'FullPath'
#>



# Input parameters
[OutputType($null)]
Param()



# Domains
$Domains = [ordered]@{
    'bergans.no'=1
    'bergans.local'=1
    'bergans.facebook.com'=2
}



# PowerShell preferences
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

    

# Scipt help variables
$ScriptSuccess = [bool] $true



# Put in Try Catch to exit properly based on actual success status
Try {
    # Registry directories
    $IsAdmin = [bool](
        $(
            [System.Security.Principal.WindowsPrincipal](
                [System.Security.Principal.WindowsIdentity]::GetCurrent()
            )
        ).IsInRole(
            [System.Security.Principal.WindowsBuiltInRole]::Administrator
        )
    )
    $IsSystem = [bool](
        [string][System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value' -eq 'S-1-5-18'
    )
    $BasePath = [string] 'Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\{0}'
    $Paths = [string[]](
        $(
            if ($IsSystem -or $IsAdmin) {
                'Registry::HKEY_LOCAL_MACHINE\' + $BasePath
            }
            if (-not $IsSystem) {
                'Registry::HKEY_CURRENT_USER\' + $BasePath
            }
        ).Where{
            $_
        }
    )


    # Set registry values
    foreach ($Domain in [string[]]($Domains.GetEnumerator().'Name')) {
        foreach ($Path in $Paths) {
            # Create Paths Dynamically
            $PathDynamicBase = [string] $Path -f $Domain
            $PathsDynamic = [string[]](
                $PathDynamicBase,
                ($PathDynamicBase+'\www.*')
            )
        
            # Trust both HTTP and HTTPS on intranet (1), HTTPS only on internet (2 or greater)
            $Names = [string[]](
                $(if($Domains.$Domain -le 1){'http'}),'https' -ne $null
            )

            # Set ZoneMap for Domain
            foreach ($PathDynamic in $PathsDynamic) {
                # Create Path if it does not exist
                if (-not(Test-Path -Path $PathDynamic)) {
                    $null = New-Item -Path $PathDynamic -ItemType 'Directory' -Force
                }

                # Set ZoneMap for domain
                foreach ($Name in $Names) {
                    # Set-ItemProperty
                    Set-ItemProperty -Path $PathDynamic -Name $Name -Value $Domains.$Domain -Type 'DWord' -Force

                    # Verbose
                    Write-Information -MessageData (
                        'Set-ItemProperty -Path "{0}" -Name "{1}" -Value "{2}" -Type "DWord" -Force{3}   Success? {4}.' -f (
                            $PathDynamic,
                            $Name,
                            $Domains.$Domain,[System.Environment]::NewLine,
                            $?.ToString()
                        )
                    )

                    # Write out success
                    Write-Information -MessageData (
                        'Adding "{0}://{1}*.{2}" to InternetExplorer Zone Map. Success? {3}' -f (
                            $Name,
                            $(if($PathDynamic -like '*\www.?'){'www.'}),
                            $Domain,
                            $?.ToString()
                        )
                    )
                }
            }
        }
    }
}
Catch {
    $ScriptSuccess = [bool] $false
}



# Exit
if ($ScriptSuccess) {
    Write-Output -InputObject 'Success.'
    Exit 0
}
else {
    Write-Error -ErrorAction 'Continue' -Exception 'Fail.' -Message 'Fail.'
    Exit 1
}

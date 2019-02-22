#Requires -RunAsAdministrator

<#

.RESOURCES
    Microsoft Docs
        Get-PackageProvider         https://docs.microsoft.com/en-us/powershell/module/packagemanagement/get-packageprovider
        Install-PackageProvider     https://docs.microsoft.com/en-us/powershell/module/packagemanagement/install-packageprovider

#>


# Settings - PowerShell Preferences - Interaction
$ConfirmPreference     = 'None'
$ProgressPreference    = 'SilentlyContinue'
# Settings - PowerShell Preferences - Output Streams
$DebugPreference       = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'SilentlyContinue'
$VerbosePreference     = 'Continue'
$WarningPreference     = 'SilentlyContinue'




#region    Functions
    function Get-PublishedModuleVersion {
        param(
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string] $Name
        )

        # access the main module page, and add a random number to trick proxies
        $url = ('https://www.powershellgallery.com/packages/{0}/?dummy={1}' -f ($Name,[System.Random]::New().Next(9999)))
        $request = [System.Net.WebRequest]::Create($url)
        # do not allow to redirect. The result is a "MovedPermanently"
        $request.AllowAutoRedirect=$false
        try {
            # send the request
            $response = $request.GetResponse()
            # get back the URL of the true destination page, and split off the version
            $response.GetResponseHeader('Location').Split('/')[-1] -as [System.Version]
            # make sure to clean up
            $response.Close()
            $response.Dispose()
        }
        catch {
            Write-Warning -Message ($_.Exception.Message)
        }
    }
#endregion Functions




#region    Main
    # NuGet
    [System.Version] $VersionNuGetMinimum   = [System.Version](Find-PackageProvider -Name 'NuGet' -Force -Verbose:$false -Debug:$false | Select-Object -ExpandProperty 'Version')
    [System.Version] $VersionNuGetInstalled = [System.Version]([System.Version[]]@(Get-PackageProvider -ListAvailable -Name 'NuGet' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Version') | Sort-Object)[-1]
    Write-Output -InputObject ('NuGet')
    if ( (-not($VersionNuGetInstalled)) -or $VersionNuGetInstalled -lt $VersionNuGetMinimum) {        
        Install-PackageProvider 'NuGet' –Force -Verbose:$false -Debug:$false
        Write-Output -InputObject ('Not installed, or newer version available. Installing... Success? {0}' -f ($?))
    }


    # Wanted Module
    [string[]] $NameWantedModules = @('PowerShellGet','AudioDeviceCmdlets')
    foreach ($Module in $NameWantedModules) {
        Write-Output -InputObject ('{0}' -f ($Module))
        [System.Version] $VersionModuleAvailable = [System.Version](Get-PublishedModuleVersion -Name $Module)
        [System.Version] $VersionModuleInstalled = [System.Version](Get-InstalledModule -Name $Module -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Version')
        if ( (-not($VersionModuleInstalled)) -or $VersionModuleInstalled -lt $VersionModuleAvailable) {           
            Install-Module -Name $Module -Repository 'PSGallery' -Scope 'AllUsers' -Verbose:$false -Debug:$false -Confirm:$false -Force
            Write-Output -InputObject ('Not installed, or newer version available. Installing... Success? {0}' -f ($?))
        }
    }
#endregion Main
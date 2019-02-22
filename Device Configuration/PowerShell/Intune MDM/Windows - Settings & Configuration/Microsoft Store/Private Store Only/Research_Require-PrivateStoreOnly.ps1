<#
    .SYNAPSIS
        Removes all retail apps and features from Microsoft Store. Only apps added to Microsoft Store for Business for the organization will appear.

    .DESCRIPTION
        Removes all retail apps and features from Microsoft Store. Only apps added to Microsoft Store for Business for the organization will appear.

    .NOTES
        Resources
          * https://getadmx.com/?Category=Windows_10_2016&Policy=Microsoft.Policies.WindowsStore::RequirePrivateStoreOnly

#>


$Path = [string]('Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\WindowsStore')
if (-not(Test-Path -Path $Path)){$null = New-Item -Path $Path -ItemType 'Directory'}
$null = Set-ItemProperty -Path $Path -Name 'RequirePrivateStoreOnly' -Value 1 -Type 'DWord' -Force
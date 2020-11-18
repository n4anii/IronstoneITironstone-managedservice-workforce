#Requires -RunAsAdministrator
<#
    .SYNOPSIS
        Removes IronSync office template files.
#>

# PowerShell preferences
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

# Assets
$Path = [string] '{0}\Users\Public\OfficeTemplates' -f $env:SystemDrive

# Continue only if path exists
if ([System.IO.Directory]::Exists($Path)) {
    # Find content
    $Content = [array](Get-ChildItem -Path $Path -Recurse -Force)

    # Delete all content of the folder if no files inside it is currently in use
    if ($([bool[]]($Content.ForEach{$_.'Name' -like '~$*'})) -notcontains $true) {
        $null = [System.IO.Directory]::Delete($Path,$true)
        $null = [System.IO.Directory]::Create($Path)
        Write-Output -InputObject 'Successfully cleared folder and it`s content.'
    }
    else {
        Throw 'Files in use.'
    }
}
else {
    Write-Output -InputObject 'Path does not exist.'
}
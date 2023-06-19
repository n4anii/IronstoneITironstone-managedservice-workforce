#Requires -RunAsAdministrator
<#
    .SYNOPSIS
        Adds Node.JS to environmental variables.
#>


# Assets
$NewPath = [string] 'C:\Program Files\nodejs'


# Get existing
$EnvVariables = [string[]](
    [System.Environment]::GetEnvironmentVariables('Machine').'Path'.Split(';') | Sort-Object -Unique
)


# Clean existing
## Remove ending '\'
$EnvVariables = [string[]](
    $EnvVariables.ForEach{
        if ($_[-1] -eq '\') {
            $_.Substring(0,$_.'Length'-1)
        }
        else {
            $_
        }
    }
)

## Remove paths that does not exist
$EnvVariables = [string[]](
    $EnvVariables.Where{
        [System.IO.Directory]::Exists($_)
    }
)

## Add new to existing
$EnvVariables += [string[]]($NewPath)

## Sort and remove duplicates
$EnvVariables = [string[]](
    $EnvVariables | Sort-Object -Unique
)


# Set
[System.Environment]::SetEnvironmentVariable(
    'Path',
    [string]($EnvVariables -join ';'),
    'Machine'
)

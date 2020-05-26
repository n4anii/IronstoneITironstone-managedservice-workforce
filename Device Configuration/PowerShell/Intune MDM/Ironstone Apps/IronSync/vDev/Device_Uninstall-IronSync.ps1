#Reqiures -RunAsAdministrator
<#
    .SYNOPSIS
        Uninstalls IronSync.
#>



# Input parameters
[OutputType($null)]
Param ()



# Assets
## Manual
$Author   = 'Ironstone'
$Product  = 'IronSync'

## Dynamic
$DirPath  = [string]('{0}\IronstoneIT\{1}' -f ($env:ProgramW6432,$Product))
$RegPath  = [string]('Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\IronstoneIT\Intune\{0}' -f ($Product))
$DirPaths = [string[]]($(Get-ChildItem -Path ([System.IO.Directory]::GetParent($DirPath).'FullName') -Filter ('*{0}*' -f ($Product)) -Directory -Depth 0).'FullName')
$Paths    = [string[]]([string[]]$($RegPath) + [string[]]($DirPaths))


# Check
$Success = [bool[]]$(
    # Scheduled task
    [bool]$(
        Try {
            $null = $(Get-ScheduledTask).Where{
                $_.'Author' -like ('*{0}*' -f ($Author)) -and
                $_.'TaskName' -like ('*{0}*' -f ($Product)) -and
                $_.'TaskName' -notlike '*trigger*' -and
                $_.'TaskName' -notlike '*locker*'
            } | Unregister-ScheduledTask -Confirm:$false
            $?
        }
        Catch {
            $false
        }
    ),


    # Files and registry
    [bool[]]$(
        foreach ($Path in $Paths) {
            Try {
                
                if (Test-Path -Path $Path) {
                    $null = Remove-Item -Path $Path -Recurse -Force
                    $?
                }
                else {
                    $?
                }
            }
            Catch {
                $false
            }
        }
    )
)



# Exit
if ($Success -notcontains $false) {
    Write-Output -InputObject 'Uninstalled.'
    Exit 0
}
else {
    Write-Error -Message 'Installed.' -Exception 'Installed.' -ErrorAction 'Continue'
    Exit 1
}

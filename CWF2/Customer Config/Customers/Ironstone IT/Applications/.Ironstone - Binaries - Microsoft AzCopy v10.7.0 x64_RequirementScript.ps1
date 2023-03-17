# Input parameters
[OutputType([bool])]
Param ()


# PowerShell Preferences
$ErrorActionPreference = 'Stop'


# Assets
$Path = [string]('{0}\IronstoneIT\Binaries\AzCopy\azcopy.exe'-f($env:ProgramData))


# Return whether AzCopy is running
[bool](
    -not [System.IO.File]::Exists($Path) -or
    [string[]]($(Get-Process).'Path' | Sort-Object -Unique) -notcontains $Path
)

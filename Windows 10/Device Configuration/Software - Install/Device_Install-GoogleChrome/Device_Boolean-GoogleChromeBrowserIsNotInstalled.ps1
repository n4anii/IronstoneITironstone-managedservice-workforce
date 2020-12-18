[OutputType([bool])]
$ErrorActionPreference = 'SilentlyContinue'
[bool](
    $(
        [string[]](
            ('{0}\Google\Chrome\Application\chrome.exe' -f ${env:ProgramFiles(x86)}),
            ('{0}\Google\Chrome\Application\chrome.exe' -f $env:ProgramW6432)
        )
    ).ForEach{
        [System.IO.File]::Exists($_)
    } -notcontains $true
)
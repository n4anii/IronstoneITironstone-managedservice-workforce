[OutputType([bool])]
$ErrorActionPreference = 'Continue'
[bool](
    [byte](
        $(
            [array](
                Get-Process -Name 'chrome' -ErrorAction 'SilentlyContinue'
            )
        ).'Count'
    ) -le 0
)
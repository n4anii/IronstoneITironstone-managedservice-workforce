[OutputType([bool])]
Param (
    [Parameter(Mandatory = $false)]
    [string] $Path = [string]('{0}\IronSync' -f ($env:PUBLIC)),

    [Parameter(Mandatory = $false)]
    [string[]] $Extensions = [string[]]('jpg','jpeg','png')
)


# Assets
$Include = [string[]]($Extensions.ForEach{'*.{0}'-f$_})


# Look for a dedicated Teams background folder
if ([System.IO.Directory]::Exists($Path)) {
    $TeamsFolders = [array](Get-ChildItem -Path $Path -Directory -Filter '*teams*' -Depth 0)
    if ($TeamsFolders.'Count' -eq 1 -and $([array](Get-ChildItem -Path ('{0}\*'-f$TeamsFolders[0].'FullName') -Include $Include -Recurse -Force)).'Count' -gt 0) {
        $Path = $TeamsFolders[0].'FullName'
    }
}


# Look for Teams backgrounds
[bool](
    $(
        [array](
            Get-ChildItem -Path ('{0}\*' -f ($Path)) -Include $Include -File -Recurse -Force
        )
    ).'Count' -gt 0
)

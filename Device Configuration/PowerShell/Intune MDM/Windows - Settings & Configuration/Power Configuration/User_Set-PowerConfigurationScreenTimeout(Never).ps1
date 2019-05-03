# Assets
$Arguments = [string[]]$(
    # On Power
    '/setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0',
    '/setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOCONLOCK 0',
    # On Battery
    '/setdcvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0',
    '/setdcvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOCONLOCK 0',
    # Set SCHEME_CURRENT to be active
    '/setactive SCHEME_CURRENT'
)


# Set Power Config
foreach ($Argument in $Arguments) {
    $null = Start-Process -FilePath ('{0}\System32\powercfg.exe' -f ($env:SystemRoot)) -ArgumentList $Argument -WindowStyle 'Hidden' -Wait -ErrorAction 'Stop'
}
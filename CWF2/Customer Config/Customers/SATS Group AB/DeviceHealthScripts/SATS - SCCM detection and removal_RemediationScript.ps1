$Arguments = [string[]]$(
    ("$env:windir\ccmsetup\ccmsetup.exe"),
    ("/uninstall")
)

Write-Output ('& cmd /c {0}' -f ($Arguments -join ' '))

& 'cmd' '/c' ($Arguments -join ' ')
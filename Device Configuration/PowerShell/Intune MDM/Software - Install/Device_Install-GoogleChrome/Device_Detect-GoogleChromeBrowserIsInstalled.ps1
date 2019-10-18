if ([bool]$([byte]$([array]$(Get-ChildItem -Path ([string]$('{0}\Google\Chrome\Application' -f (${env:ProgramFiles(x86)}))) -Filter 'chrome.exe' -File -Recurse).'Count') -ge 0)) {
    Write-Output -InputObject 'Installed'
    Exit 0
}
else {
    Exit 1
}
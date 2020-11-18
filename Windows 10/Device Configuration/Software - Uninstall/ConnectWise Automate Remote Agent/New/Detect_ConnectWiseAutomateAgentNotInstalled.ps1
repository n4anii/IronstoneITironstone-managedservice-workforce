if ([System.IO.File]::Exists('{0}\LTSvc\LTSVC.exe'-f$env:windir)) {
    Write-Error -ErrorAction 'Continue' -Message 'Installed.'
    Exit 1
}
else {
    Write-Output -InputObject 'Not installed.'
    Exit 0
}
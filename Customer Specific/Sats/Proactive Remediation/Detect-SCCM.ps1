if(Test-Path -Path "$env:windir\ccmsetup\ccmsetup.exe"){
    Write-Host "SCCM found"
    Exit 1
} else {
    Write-Host "SCCM not found"
    Exit 0
}
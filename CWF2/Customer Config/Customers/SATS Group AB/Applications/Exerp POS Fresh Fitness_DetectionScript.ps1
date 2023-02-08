if(Test-Path -Path "$env:ProgramFiles\Exerp\Client"){
    Write-Host "64 bit version Exerp client found"
    Exit 0
}
elseif (Test-Path -Path "${env:ProgramFiles(x86)}\Exerp\Client") {
    Write-Host "32 bit version Exerp client found"
    Exit 0
}
else {
    Write-Host "Exerp client not found"
    Exit 1
}
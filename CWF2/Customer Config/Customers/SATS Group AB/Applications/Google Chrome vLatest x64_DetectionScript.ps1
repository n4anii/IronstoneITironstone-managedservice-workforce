if ((Test-Path "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe" -PathType Leaf) -Or (Test-Path "$env:ProgramFiles\Google\Chrome\Application\chrome.exe" -PathType Leaf))
{
    Write-Host "Found Chrome.exe"
}

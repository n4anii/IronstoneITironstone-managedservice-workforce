# Make sure it runs like 64 bit process
if ([System.Environment]::Is64BitOperatingSystem -and -not [System.Environment]::Is64BitProcess) {
    & ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile -File ('{0}' -f ($MyInvocation.'InvocationName')) $args
    exit $LASTEXITCODE
}

# Get all installed MSIs
$MSIGUIDs = [string[]]$(
    [string[]]$(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall' | Select-Object -ExpandProperty 'Name').ForEach{$_.Split('\')[-1]}.Where{Try{[guid]$($_)}Catch{}} +
    [string[]]$(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Select-Object -ExpandProperty 'Name').ForEach{$_.Split('\')[-1]}.Where{Try{[guid]$($_)}Catch{}} | `
    Select-Object -Unique
)

# Return result
if ([bool]$($MSIGUIDs -contains '{97A7D2C4-6628-4DC0-BA26-DCD17AFD90E5}')) {
    Exit 1
}
else {
    Write-Output -InputObject ('Not installed.')
    Exit 0
}
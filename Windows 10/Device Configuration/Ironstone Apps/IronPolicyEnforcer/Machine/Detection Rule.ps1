# Create Path, use "sysnative" instead of "System32" if x86 process on x64 OS
$Path = [string]$('{0}\{1}\GroupPolicy\Machine\registry.pol' -f (
    $env:windir,[string]$(if([System.Environment]::Is64BitOperatingSystem -and [System.Environment]::Is64BitProcess){'System32'}else{'sysnative'})))

# Run detection
if ([string]$('12782051C01A4C79E3995CF116A2AC3F15D389B0906F329D758B2B515EE8106D') -ne `
    [string]$(Get-FileHash -Path $Path -Algorithm 'SHA256' -ErrorAction 'Stop' | `
    Select-Object -ExpandProperty 'Hash' -ErrorAction 'Stop')) {
    [bool]$($false)
    Exit 1
}
else {
    [bool]$($true)
}
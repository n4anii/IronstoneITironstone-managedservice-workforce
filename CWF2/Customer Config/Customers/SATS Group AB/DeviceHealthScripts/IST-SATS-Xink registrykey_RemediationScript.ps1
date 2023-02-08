#If Xink ADConfig key exists replace, if it is missing create it

if ((Test-Path -LiteralPath "HKLM:\SOFTWARE\Policies\Xink\Xink Client AD\ADConfig") -ne $true) { 
    New-Item "HKLM:\SOFTWARE\Policies\Xink\Xink Client AD\ADConfig" -force -ea SilentlyContinue 
}
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Xink\Xink Client AD\ADConfig' -Name 'DomainAuthToken' -Value '-hJWMXsclb8GQeN7fONIhn87rk5Ax26H0t_AeSv-rAOv1nMSWveIWUtymM-kxcArdHKDCVKx9jqg3KPhtOCRLTwf8F33KhPN21YYEJPg9hIZHNu_aVNsTp83-erNVbTqA0w9WkMhrij4ULN3psjxUv-CiE1kxvMgsPWY9lwECqWdDG2xnPRuNhkYG6ttm5eYnZKlq6MJL5dYVIunMzdbYyG4favNI4bwv1L3Z1Pl36s' -PropertyType String -Force -ea SilentlyContinue;

if (-NOT (Test-Path -LiteralPath "HKLM:\SOFTWARE\Policies\Xink\Xink Client AD\ADConfig")) { 
    Write-Output "Registry key is missing"
    Exit 1 
}
if ((Get-ItemPropertyValue -LiteralPath 'HKLM:\SOFTWARE\Policies\Xink\Xink Client AD\ADConfig' -Name 'DomainAuthToken' -ea SilentlyContinue) -eq '-hJWMXsclb8GQeN7fONIhn87rk5Ax26H0t_AeSv-rAOv1nMSWveIWUtymM-kxcArdHKDCVKx9jqg3KPhtOCRLTwf8F33KhPN21YYEJPg9hIZHNu_aVNsTp83-erNVbTqA0w9WkMhrij4ULN3psjxUv-CiE1kxvMgsPWY9lwECqWdDG2xnPRuNhkYG6ttm5eYnZKlq6MJL5dYVIunMzdbYyG4favNI4bwv1L3Z1Pl36s') {
    Write-Output "Registry value is correct"
    Exit 0 
}
else {
    Write-Output "Registry value is incorrect"
    Exit 1 
}
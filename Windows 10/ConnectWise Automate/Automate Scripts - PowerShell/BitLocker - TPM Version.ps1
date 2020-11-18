# TPM info
$TPM = Get-Tpm

$Output = [PSObject]@{}
[PSCustomObject[]]$(foreach($Property in [string[]]$($TPM | Get-Member -MemberType 'Properties' | Select-Object -ExpandProperty 'Name')) {    
    [PSCustomObject]@{$Property=[string]$(if([string]::IsNullOrEmpty($TPM.$Property)){''}else{$TPM.$Property.ToString().Trim()})}
})

Get-Tpm | Select-Object -Property '*'
Get-Tpm | Select-Object -ExpandProperty 'ManufacturerVersion'
Get-Tpm | Select-Object -Property '*' | ConvertTo-Json -Depth 100

# TPM Version
[string]$([string]$(Get-WmiObject -Namespace 'root\cimv2\security\microsofttpm' -Query 'Select * from win32_tpm' | Select-Object -ExpandProperty 'SpecVersion').Split(',')[0].Trim())



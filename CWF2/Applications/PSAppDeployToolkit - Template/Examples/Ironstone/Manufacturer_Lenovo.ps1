$ComputerDetails = New-Object -TypeName PSObject -Property @{
    Manufacturer = $null
    Model = $null
    SystemSKU = $null
}

$ComputerManufacturer = (Get-CimInstance -ClassName "Win32_ComputerSystem" | Select-Object -ExpandProperty Manufacturer).Trim()
switch -Wildcard ($ComputerManufacturer) {
    "*Lenovo*" {
        $ComputerDetails.Manufacturer = "Lenovo"
        $ComputerDetails.Model = (Get-CimInstance -ClassName "Win32_ComputerSystemProduct" | Select-Object -ExpandProperty Version).Trim()
        $ComputerDetails.SystemSKU = ((Get-CimInstance -ClassName "Win32_ComputerSystem" | Select-Object -ExpandProperty Model).SubString(0, 4)).Trim()
    }
}

$isValidModel = $ComputerDetails.Manufacturer -eq "Lenovo" -and (
    $ComputerDetails.Model -like "*ThinkPad*" -or
    $ComputerDetails.Model -like "*ThinkCentre*" -or
    $ComputerDetails.Model -like "*ThinkStation*"
)

if ($isValidModel) {return $True}
$ComputerDetails = New-Object -TypeName PSObject -Property @{
    Manufacturer = $null
    Model = $null
    SystemSKU = $null
}

$ComputerManufacturer = (Get-WmiObject -Class "Win32_ComputerSystem" | Select-Object -ExpandProperty Manufacturer).Trim()
switch -Wildcard ($ComputerManufacturer) {
    "*Lenovo*" {
        $ComputerDetails.Manufacturer = "Lenovo"
	    $ComputerDetails.Model = (Get-WmiObject -Class "Win32_ComputerSystemProduct" | Select-Object -ExpandProperty Version).Trim()
	    $ComputerDetails.SystemSKU = ((Get-WmiObject -Class "Win32_ComputerSystem" | Select-Object -ExpandProperty Model).SubString(0, 4)).Trim()
	}
}

$isValidModel = $ComputerDetails.Manufacturer -eq "Lenovo" -and (
    $ComputerDetails.Model -like "*ThinkPad*" -or
    $ComputerDetails.Model -like "*ThinkCentre*" -or
    $ComputerDetails.Model -like "*ThinkStation*"
)

if ($isValidModel) {return $True}
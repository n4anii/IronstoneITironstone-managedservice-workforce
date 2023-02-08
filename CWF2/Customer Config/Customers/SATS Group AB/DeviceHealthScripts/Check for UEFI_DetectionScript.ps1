$staus = $env:firmware_type

if ($staus -eq "UEFI") {
    Exit 0
}
else {
    Exit 1
}
if ($true -eq (Test-Path -Path "C:\jottacloud\analysetjenester")) {
    Write-Host "C:\jottacloud symlink exists"
    Exit 0
}
else {
    if (Test-Path -Path "$home\Aksio InsurTech AS\Prosjekter - Dokumenter") {
        Write-Host "Dokumenter funnet uten symlink"
        Exit 1
    }
    elseif (Test-Path -Path "$home\Aksio InsurTech AS\Prosjekter - Documents") {
        Write-Host "Documents found without symlink"
        Exit 1
    }
    else{
        Write-Host "Prosjekter not found yet"
        Exit 0
    }
}
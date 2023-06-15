if ($false -eq (Test-Path -Path "C:\jottacloud")) {
    New-Item -Path "C:\jottacloud" -ItemType Directory -Force
}

if($false -eq (Test-Path -Path "C:\jottacloud\analysetjenester")){
    if (Test-Path -Path "$home\Aksio InsurTech AS\Prosjekter - Dokumenter") {
        Write-Host "Dokumenter funnet"
        New-Item -ItemType SymbolicLink -Path "C:\jottacloud\analysetjenester" -Value "$home\Aksio InsurTech AS\Prosjekter - Dokumenter" -Force
    }
    elseif (Test-Path -Path "$home\Aksio InsurTech AS\Prosjekter - Documents") {
        Write-Host "Documents found"
        New-Item -ItemType SymbolicLink -Path "C:\jottacloud\analysetjenester" -Value "$home\Aksio InsurTech AS\Prosjekter - Documents" -Force
    }
}
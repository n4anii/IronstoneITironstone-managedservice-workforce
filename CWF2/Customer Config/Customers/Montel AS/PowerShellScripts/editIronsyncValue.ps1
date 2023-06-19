(Get-Content 'C:\Program Files\IronstoneIT\IronSync\Run-IronSync.ps1').Replace("('files')","('internal')") |Set-Content 'C:\Program Files\IronstoneIT\IronSync\Run-IronSync.ps1'
cd 'C:\Program Files\IronstoneIT\IronSync'
.\Run-IronSync.ps1
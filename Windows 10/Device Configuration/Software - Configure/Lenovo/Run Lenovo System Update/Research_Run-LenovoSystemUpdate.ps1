<#
    Research_Run-LenovoSystemUpdate.ps1

    Search       A = All | C = ? | R = Recommended

    .RESOURCES
        Lenovo Community Forums - Update BIOS remotely on multiple machines?
        https://forums.lenovo.com/t5/Enterprise-Client-Management/Update-BIOS-remotely-on-multiple-machines/m-p/3912295/highlight/true#M4747

        Lenovo Community Forums - Lenovo TVSU Command Line Parameters - Silent Update
        https://forums.lenovo.com/t5/Pre-Installed-Lenovo-Software/Lenovo-TVSU-Command-Line-Parameters-Silent-Update/m-p/3599869/highlight/true#M30603
#>

# Path to Lenovo System Update tools
[string] $PathFileLSU_tvsu       = ('{0}\Lenovo\System Update\tvsu.exe' -f (${env:ProgramFiles(x86)}))
[string] $PathFileLSU_tvsukernel = ('{0}\Lenovo\System Update\tvsukernel.exe' -f (${env:ProgramFiles(x86)}))


# Arguments - tvsu.exe
[string] $tvsu_Update1    = ('/CM -search C -action INSTALL -includerebootpackages 1,3,4 -noicon -noreboot -nolicense -defaultupdate -schtask')
[string] $tvsu_Update2    = ('-search C -action INSTALL -includerebootpackages 1,3,4 -noicon -noreboot -nolicense -defaultupdate')
[string] $tvsu_Update3    = ('/CM -search A -action INSTALL -includerebootpackages 3 -noicon -noreboot -nolicense')
[string] $tvsu_Update4    = ('/CM -search A -action INSTALL -includerebootpackages 1,3,4 -noicon -noreboot -nolicense -defaultupdate')
[string] $tvsu_Update5    = ('/CM -search R -action INSTALL -includerebootpackages 1,3,4 -noicon -noreboot -nolicense -defaultupdate -schtask')


# Arguments - tvsukernel.exe
[string] $tvsukernel_Update1 = '/CM -search A -action INSTALL -includerebootpackages 1,3,4 -noicon -nolicense -noreboot'



# Testing - tvsu.exe
Start-Process -FilePath $PathFileLSUtvsu -ArgumentList $ArgsLSUAutoUpdate6 -WindowStyle 'Hidden' -Wait



# Testing - tvsukernel.exe
Start-Process -FilePath $PathFileLSUtvsukernel -ArgumentList $tvsukernel_Update1 -WindowStyle 'Hidden' -Wait

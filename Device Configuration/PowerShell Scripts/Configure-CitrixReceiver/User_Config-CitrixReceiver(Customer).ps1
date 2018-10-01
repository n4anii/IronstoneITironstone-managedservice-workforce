<#
    .SYNOPSIS
    Tests if a registry value exists, if not, add it

    .DESCRIPTION
    Tests if a registry value exists, if not, add it
    Written with PowerShell v5.1 documentation

    .USAGE
    Export values from registry, paste it to $RegFile 

    Sources:
    - https://stackoverflow.com/questions/5648931/test-if-registry-value-exists
    - https://stackoverflow.com/questions/29804234/run-registry-file-remotely-with-powershell
    - https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/out-file?view=powershell-5.1
    - https://docs.microsoft.com/en-us/intune/intune-management-extension
    
#>


#region    ONLY EDIT THESE VALUES
    [string] $Customer      = ''                # EXAMPLE 'Backe'
    [string] $CheckRegPath  = ''                # EXAMPLE 'HKCU:\Software\Citrix\Dazzle\Sites\backegrupp-ea578b8b\configUrl'
    [string] $CheckRegValue = ''                # EXAMPLE 'https://storefront.backe.no/Citrix/BackeGruppen/discovery'

    #region    Registry file @('Filename.ext','BASE64-encoded-string')
    [string[]] $RegFile = @('','')
    #EXAMPLE [string[]] $RegFile = @('TempRegFile.reg','V2luZG93cyBSZWdpc3RyeSBFZGl0b3IgVmVyc2lvbiA1LjAwCgpbSEtFWV9DVVJSRU5UX1VTRVJcU29mdHdhcmVcQ2l0cml4XQoKW0hLRVlfQ1VSUkVOVF9VU0VSXFNvZnR3YXJlXENpdHJpeFxEYXp6bGVdCiJDdXJyZW50QWNjb3VudCI9ImJhY2tlZ3J1cHAtZWE1NzhiOGIiCgpbSEtFWV9DVVJSRU5UX1VTRVJcU29mdHdhcmVcQ2l0cml4XERhenpsZVxTaXRlc10KCltIS0VZX0NVUlJFTlRfVVNFUlxTb2Z0d2FyZVxDaXRyaXhcRGF6emxlXFNpdGVzXGJhY2tlZ3J1cHAtZWE1NzhiOGJdCiJ0eXBlIj0iRFMiCiJuYW1lIj0iQmFja2VHcnVwcGVuIgoiY29uZmlnVXJsIj0iaHR0cHM6Ly9zdG9yZWZyb250LmJhY2tlLm5vL0NpdHJpeC9CYWNrZUdydXBwZW4vZGlzY292ZXJ5IgoiQ29uZmlndXJlZEJ5QWRtaW5pc3RyYXRvciI9IkZhbHNlIgoiZW5hYmxlZEJ5QWRtaW4iPSJUcnVlIgoic2VydmljZVJlY29yZElkIj0iMzUwOTg3MjkxMyIKInJlc291cmNlc1VybCI9Imh0dHBzOi8vc3RvcmVmcm9udC5iYWNrZS5uby9DaXRyaXgvQmFja2VHcnVwcGVuL3Jlc291cmNlcy92MiIKInNlc3Npb25VcmwiPSJodHRwczovL3N0b3JlZnJvbnQuYmFja2Uubm8vQ2l0cml4L0JhY2tlR3J1cHBlbi9zZXNzaW9ucy92MS9hdmFpbGFibGUiCiJhdXRoRW5kcG9pbnRVcmwiPSJodHRwczovL3N0b3JlZnJvbnQuYmFja2Uubm8vQ2l0cml4L0F1dGhlbnRpY2F0aW9uL2VuZHBvaW50cy92MSIKInRva2VuVmFsaWRhdGlvblVybCI9Imh0dHBzOi8vc3RvcmVmcm9udC5iYWNrZS5uby9DaXRyaXgvQXV0aGVudGljYXRpb24vYXV0aC92MS90b2tlbi92YWxpZGF0ZS8iCiJ0b2tlblNlcnZpY2VVcmwiPSJodHRwczovL3N0b3JlZnJvbnQuYmFja2Uubm8vQ2l0cml4L0F1dGhlbnRpY2F0aW9uL2F1dGgvdjEvdG9rZW4iCgpbSEtFWV9DVVJSRU5UX1VTRVJcU29mdHdhcmVcQ2l0cml4XFJlY2VpdmVyXQoKW0hLRVlfQ1VSUkVOVF9VU0VSXFNvZnR3YXJlXENpdHJpeFxSZWNlaXZlclxDdHhBY2NvdW50XQoKW0hLRVlfQ1VSUkVOVF9VU0VSXFNvZnR3YXJlXENpdHJpeFxSZWNlaXZlclxDdHhBY2NvdW50XDIwMDY5ZGI0LThiMWEtNGYzZS04YjI0LTMyNTMyNTEwYWEyYl0KIk5hbWUiPSJCYWNrZUdydXBwZW4iCiJVcGRhdGVyVHlwZSI9Im5vbmUiCiJDb250ZW50SGFzaCI9IjE3MDAwMTMwMTkiCiJBY2NvdW50U2VydmljZVVybCI9Imh0dHBzOi8vc3RvcmVmcm9udC5iYWNrZS5uby9DaXRyaXgvUm9hbWluZy9BY2NvdW50cyIKIlRva2VuU2VydmljZVVybCI9Imh0dHBzOi8vc3RvcmVmcm9udC5iYWNrZS5uby9DaXRyaXgvQXV0aGVudGljYXRpb24vYXV0aC92MS90b2tlbiIKIklzUHVibGlzaGVkIj0idHJ1ZSIKIklzUHJpbWFyeSI9InRydWUiCiJJc0VuYWJsZWQiPSJ0cnVlIgoKW0hLRVlfQ1VSUkVOVF9VU0VSXFNvZnR3YXJlXENpdHJpeFxSZWNlaXZlclxTUl0KCltIS0VZX0NVUlJFTlRfVVNFUlxTb2Z0d2FyZVxDaXRyaXhcUmVjZWl2ZXJcU1JcU3RvcmVdCgpbSEtFWV9DVVJSRU5UX1VTRVJcU29mdHdhcmVcQ2l0cml4XFJlY2VpdmVyXFNSXFN0b3JlXDM1MDk4NzI5MTNdCiJOYW1lIj0iQmFja2VHcnVwcGVuIgoiQWRkciI9Imh0dHBzOi8vc3RvcmVmcm9udC5iYWNrZS5uby9DaXRyaXgvQmFja2VHcnVwcGVuL2Rpc2NvdmVyeSIKIlNSVHlwZSI9ZHdvcmQ6MDAwMDAwMDAKCltIS0VZX0NVUlJFTlRfVVNFUlxTb2Z0d2FyZVxDaXRyaXhcUmVjZWl2ZXJcU1JcU3RvcmVcMzUwOTg3MjkxM1xCZWFjb25zXQoKW0hLRVlfQ1VSUkVOVF9VU0VSXFNvZnR3YXJlXENpdHJpeFxSZWNlaXZlclxTUlxTdG9yZVwzNTA5ODcyOTEzXEJlYWNvbnNcRXh0ZXJuYWxdCgpbSEtFWV9DVVJSRU5UX1VTRVJcU29mdHdhcmVcQ2l0cml4XFJlY2VpdmVyXFNSXFN0b3JlXDM1MDk4NzI5MTNcQmVhY29uc1xFeHRlcm5hbFxBZGRyMF0KIkFkZHJlc3MiPSJodHRwczovL2NpdHJpeC5iYWNrZS5ubyIKIkRTY29uZmlybWVkIj1kd29yZDowMDAwMDAwMAoKW0hLRVlfQ1VSUkVOVF9VU0VSXFNvZnR3YXJlXENpdHJpeFxSZWNlaXZlclxTUlxTdG9yZVwzNTA5ODcyOTEzXEJlYWNvbnNcRXh0ZXJuYWxcQWRkcjFdCiJBZGRyZXNzIj0iaHR0cDovL3d3dy5jaXRyaXguY29tIgoiRFNjb25maXJtZWQiPWR3b3JkOjAwMDAwMDAwCgpbSEtFWV9DVVJSRU5UX1VTRVJcU29mdHdhcmVcQ2l0cml4XFJlY2VpdmVyXFNSXFN0b3JlXDM1MDk4NzI5MTNcQmVhY29uc1xJbnRlcm5hbF0KCltIS0VZX0NVUlJFTlRfVVNFUlxTb2Z0d2FyZVxDaXRyaXhcUmVjZWl2ZXJcU1JcU3RvcmVcMzUwOTg3MjkxM1xCZWFjb25zXEludGVybmFsXEFkZHIwXQoiQWRkcmVzcyI9Imh0dHBzOi8vc3RvcmVmcm9udC5iYWNrZS5uby8iCiJEU2NvbmZpcm1lZCI9ZHdvcmQ6MDAwMDAwMDAKCltIS0VZX0NVUlJFTlRfVVNFUlxTb2Z0d2FyZVxDaXRyaXhcUmVjZWl2ZXJcU1JcU3RvcmVcMzUwOTg3MjkxM1xHYXRld2F5c10KCltIS0VZX0NVUlJFTlRfVVNFUlxTb2Z0d2FyZVxDaXRyaXhcUmVjZWl2ZXJcU1JcU3RvcmVcMzUwOTg3MjkxM1xHYXRld2F5c1w5OXggTmV0c2NhbGVyXQoiTG9nb25Qb2ludCI9Imh0dHBzOi8vY2l0cml4LmJhY2tlLm5vIgoiRWRpdGlvbiI9ZHdvcmQ6MDAwMDAwMDIKIkF1dGgiPWR3b3JkOjAwMDAwMDAyCiJBR01vZGUiPWR3b3JkOjAwMDAwMDAwCiJUcnVzdGVkQnlVc2VyIj1kd29yZDowMDAwMDAwMAoiVHJ1c3RlZEJ5RFMiPWR3b3JkOjAwMDAwMDAwCiJJc0RlZmF1bHQiPWR3b3JkOjAwMDAwMDAxCgo=')
    #endregion Registry file BASE64
#endregion ONLY EDIT THESE VALUES



#region Variables
#region Variables
# Settings
[bool] $Script:DebugLogFile = $true
[bool] $Script:DebugConsole = $false
[bool] $Script:ReadOnly     = $false
[bool] $Script:DeviceScope  = $false
If ($Script:DebugLogFile) {$Script:DebugStr=[string]::Empty}

# Script specific variables
[string] $WhatToConfig = ('User_Config-CitrixReceiver({0})' -f ($Customer))
#endregion Variables




#region Functions
    #region Write-DebugIfOn
    Function Write-DebugIfOn {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [String] $In
        )
        If ($Script:DebugConsole) {
            Write-Output -InputObject $In
        }
        If ($Script:DebugLogFile) {
            $Script:DebugStr += ($In + "`r`n")
        }
    }
    #endregion Write-DebugIfOn


    #region    Test-RegistryValue
    function Test-RegistryValue {
        <#
        .SYNAPSIS
        Returns true if value exists and is equal to the ValueToCompare.
        Else, returns false
        .EXAMPLE
        Test-RegistryValue -PathToCheck 'HKCU:\Environment\TEMP' -ValueToCompare ('{0}\AppData\Local\Temp' -f ($env:USERPROFILE))
        .PARAMETER PathToCheck
        The full registry path to check
        .PARAMETER ValueToCompare
        The value to compare against
        #>
        param(
            [Parameter(Mandatory=$true)]
            [string] $PathToCheck, 
        
            [Parameter(Mandatory=$true)]
            $ValueToCompare
        )
        $Key   = $PathToCheck.Split('\')[-1]
        $Dir   = $PathToCheck.Replace('\{0}' -f $Key,'\')
        If (Test-Path -Path $Dir) {
            $CurrentValue = (Get-ItemProperty -Path $Dir -Name $Key).$Key
            If ($CurrentValue -eq $ValueToCompare) {
                Return $true
            }
        }
        Return $false
    }
    #endregion Test-RegistryValue


    #region FileOut-FromBase64
    Function FileOut-FromBase64 {
        Param(
            [Parameter(Mandatory=$true)]
            [String] $InstallDir, $FileName, $File, $Encoding
        )
        Write-DebugIfOn -In ('FileOut-FromBase64 -FilePath ' + $InstallDir + ' -FileName ' + $FileName + ' -File ' + ($File.Substring(0,10) + '...'))
        $Local:FilePath = $InstallDir + $FileName

        If (Test-Path $InstallDir) {
            Write-DebugIfOn -In ('   Path exists, trying to write the file (File alrady exists? {0})' -f (Test-Path $Local:FilePath))
            If (-not($ReadOnly)) {
                Out-File -FilePath $Local:FilePath -Encoding $Encoding -InputObject ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($File)))
                Write-DebugIfOn -In ('      Success? {0}' -f ($?))
                Write-DebugIfOn -In ('         Does file actually exist? {0}' -f (Test-Path $Local:FilePath -ErrorAction SilentlyContinue))
            }
        }
        Else {
            Write-DebugIfOn -In ('   ERROR: Path does not exist')
        }
    }
    #enregion FileOut-FromBase64


    #region Query-Registry
    Function Query-Registry {
        Param ([Parameter(Mandatory=$true)] [String] $Dir)
        $Local:Out = [String]::Empty
        [String] $Local:Key = $Dir.Split('{\}')[-1]
        [String] $Local:Dir = $Dir.Replace($Local:Key,'')
        
        $Local:Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Local:Key) -ErrorAction SilentlyContinue
        If ($Exists) {
            $Local:Out = $Local:Exists.$Local:Key
        }
        return $Local:Out
    }
    #endregion Query-Registry


    #region Get-MachineInfo
    Function Get-MachineInfo {
        $Script:ComputerName = $env:COMPUTERNAME
        [String] $Script:ComputerManufacturer = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemManufacturer'
        If (-not([String]::IsNullOrEmpty($Script:ComputerManufacturer))) {
            [String] $Script:ComputerFamily = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemFamily'
            [String] $Script:ComputerProductName = Query-Registry -Dir 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS\SystemProductName'
            [String] $Script:WindowsEdition = Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProductName'
            [String] $Script:WindowsVersion = Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ReleaseId'
            [String] $Script:WindowsVersion += (' ({0})' -f (Query-Registry -Dir 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentBuild'))
        } 
        Else {
            $Local:EnvInfo = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property Manufacturer,Model,SystemFamily        
            [String] $Script:ComputerManufacturer = $Local:EnvInfo.Manufacturer
            [String] $Script:ComputerFamily = $Local:EnvInfo.SystemFamily
            [String] $Script:ComputerProductName = $Local:EnvInfo.Model
            $Local:OSInfo = Get-WmiObject -Class win32_operatingsystem | Select-Object -Property Caption,Version
            [String] $Script:WindowsEdition = $Local:OSInfo.Caption
            [String] $Script:WindowsVersion = $Local:OSInfo.Version
        }
    }
    #endregion Get-MachineInfo
#endregion Functions



#region Initialize
Get-MachineInfo
If ($Script:DebugLogFile -or $Script:DebugConsole) {
    Write-DebugIfOn -In '### Environment Info'
    Write-DebugIfOn -In ('Script settings: DebugConsole = "{0}", DebugWinTemp = "{1}", ReadOnly = "{2}"' -f ($Script:DebugConsole,$Script:DebugLogFile,$Script:ReadOnly))
    Write-DebugIfOn -In ('Machine info: Name = "{0}", Manufacturer = "{1}", Family = "{2}", Model = "{3}"' -f ($Script:ComputerName,$Script:ComputerManufacturer,$Script:ComputerFamily,$Script:ComputerProductName))
    Write-DebugIfOn -In ('Windows info: Edition = "{0}", Version = "{1}"' -f ($Script:WindowsEdition,$Script:WindowsVersion))
}
#endregion Initialize



#region Main
    Write-DebugIfOn -In ("`r`n" + '### ' + $WhatToConfig)

    # Check if value exists
    if (Test-RegistryValue -PathToCheck $CheckRegPath -ValueToCompare $CheckRegValue) {
        Write-DebugIfOn -In 'Reg dir already exists, and value are the same as the one compared with'
    }
    else {    
        [string] $Script:PathDirTemp = ('{0}\Temp\' -f ($env:windir))
        [string] $Script:PathFileTemp = ('{0}{1}' -f ($Script:PathDirTemp,$RegFile[0]))
        $null = Remove-Item -Path $Script:PathFileTemp -Force -ErrorAction SilentlyContinue
        FileOut-FromBase64 -InstallDir $Script:PathDirTemp -FileName $RegFile[0] -File $RegFile[1] -Encoding default

        if (-not(Test-Path -Path $Script:PathFileTemp)) {
            Write-DebugIfOn -In ('- Error: Could create "{0}".' -f ($Script:PathFileTemp))
        }
        else {  
            If (-not($ReadOnly)) {
                Write-DebugIfOn -In ('   $ReadOnly is false, attempting to write new value')
                $RegStatus = reg.exe import ('{0}' -f $Script:PathFileTemp) 2>&1
    
                If (-not(($RegStatus -Like '*completed successfully*') -or ($RegStatus -Like '*operasjonen er utf?rt*'))) {
                    Write-DebugIfOn -In ('      Error reg.exe')  
                    Write-DebugIfOn -In ('      Reg.exe output:' + "`r`n" + $RegStatus + "`r`n" + ($Error | Select * ) + "`r`n")    
                }  
                Else {
                    If (Test-RegistryValue -PathToCheck $CheckRegPath -ValueToCompare $CheckRegValue) {
                        Write-DebugIfOn -In ('      Success, ' + $WhatToConfig + ' was written to registry')
                    }
                    Else {
                        Write-DebugIfOn -In ('      Error, ' + $WhatToConfig + ' was not written to registry.')
                    }
                }
            }
            Else {
                Write-DebugIfOn -In ('   $ReadOnly, won`t attempt to write new registry value')
            }
        }
    }
#endregion Main



#region Debug
If ($Script:DebugLogFile) {
    If ([String]::IsNullOrEmpty($Script:DebugStr)) {
        $Script:DebugStr = 'Everything failed'
    }

    ### Write Output
    # Get variables
    If ($Script:DeviceScope) {
         $Local:DirLog = ('{0}\Program Files\IronstoneIT\Intune\DeviceConfiguration\' -f ($env:SystemDrive))
    }
    Else {
        $Local:DirLog = ('{0}\IronstoneIT\Intune\DeviceConfiguration\' -f ($env:APPDATA))
    }     
    $Local:NameScriptFile = $Script:WhatToConfig
    $Local:CurTime = Get-Date -Uformat '%y%m%d%H%M%S'
    

    # Create log file name
    $Local:DebugFileName = ('{0}_{1}.txt' -f ($Local:NameScriptFile,$Local:CurTime))
    

    # Check if log destination exists, or else: Create it
    If (-not(Test-Path -Path $DirLog)) {
        $null = New-Item -Path $DirLog -Force -ItemType Directory
    }
    
    
    # Out-File the Log
    $Script:DebugStr | Out-File -FilePath ($Local:DirLog + $Local:DebugFileName) -Encoding 'utf8'
}
#endregion Debug
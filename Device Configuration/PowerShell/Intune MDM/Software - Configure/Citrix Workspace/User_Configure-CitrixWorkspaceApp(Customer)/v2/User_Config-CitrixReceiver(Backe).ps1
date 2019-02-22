<#
    .SYNOPSIS
    Configures Citrix Receiver. Will work with both Citrix Receiver .EXE installer, and Citrix Receiver from Microsoft Store.


    .DESCRIPTION
    Configures Citrix Receiver. Will work with both Citrix Receiver .EXE installer, and Citrix Receiver from Microsoft Store.


    .USAGE
    * Export values from registry to .reg file
    * Convert to base64 (https://www.base64encode.org/)
    * Insert to variable $RegFile 


    .RESOURCES
    * Citrix Receiver .EXE Installer:  https://www.citrix.com/products/receiver/
    * Citrix Receiver Microsoft Store: https://www.microsoft.com/store/apps/9wzdncrfj2kj
    * https://stackoverflow.com/questions/5648931/test-if-registry-value-exists
    * https://stackoverflow.com/questions/29804234/run-registry-file-remotely-with-powershell
    * https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/out-file?view=powershell-5.1
    * https://docs.microsoft.com/en-us/intune/intune-management-extension

    .TODO
    Cleaner execution with reg.exe. Something like
        Working:
            $null = & cmd /c ('"{0}\reg.exe" IMPORT "{1}" /reg:64' -f ([System.Environment]::SystemDirectory,$Script:PathFileTemp)) 2>&1
            [byte] $ExitCode = (Start-Process -FilePath ('{0}\reg.exe' -f ([System.Environment]::SystemDirectory)) -ArgumentList ('IMPORT "{0}" /reg:64' -f ($Script:PathFileTemp)) -NoNewWindow -Wait -PassThru).ExitCode
        Ideas:
            Invoke-Command -FilePath ('{0}\reg.exe' -f ([System.Environment]::SystemDirectory)) -ArgumentList ('IMPORT "{0}" /reg:644' -f ($Script:PathFileTemp))
            $ImportReg = Start-Process -FilePath ('{0}\reg.exe' -f ([System.Environment]::SystemDirectory)) -ArgumentList ('IMPORT "{0}" /reg:644' -f ($Script:PathFileTemp)) -NoNewWindow             
            Invoke-Command -ScriptBlock {Start-Process -FilePath ('{0}\reg.exe' -f ([System.Environment]::SystemDirectory)) -ArgumentList ('IMPORT "{0}" /reg:644' -f ($Script:PathFileTemp)) -NoNewWindow}
    
#>


# Script Variables
[bool]   $DeviceContext = $false
[string] $NameScript    = 'Config-CitrixReceiver(Backe)'

# Settings - PowerShell - Output Preferences
$DebugPreference       = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$VerbosePreference     = 'SilentlyContinue'
$WarningPreference     = 'Continue'


#region    Don't Touch This
# Settings - PowerShell - Interaction
$ConfirmPreference     = 'None'
$ProgressPreference    = 'SilentlyContinue'

# Settings - PowerShell - Behaviour
$ErrorActionPreference = 'Continue'

# Dynamic Variables - Process & Environment
[string] $NameScriptFull      = ('{0}_{1}' -f ($(if($DeviceContext){'Device'}else{'User'}),$NameScript))
[string] $NameScriptVerb      = $NameScript.Split('-')[0]
[string] $NameScriptNoun      = $NameScript.Split('-')[-1]
[string] $ProcessArchitecture = $(if([System.Environment]::Is64BitProcess){'64'}else{'32'})
[string] $OSArchitecture      = $(if([System.Environment]::Is64BitOperatingSystem){'64'}else{'32'})

# Dynamic Variables - User
[string] $StrIsAdmin       = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
[string] $StrUserName      = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
[string] $SidCurrentUser   = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
[string] $SidSystemUser    = 'S-1-5-18'
[bool] $CurrentUserCorrect = $(
    if($DeviceContext -and $SIDCurrentUser -eq $SIDSystemUser){$true}
    elseif (-not($DeviceContext) -and $SIDCurrentUser -ne $SIDSystemUser){$true}
    else {$false}
)

# Dynamic Logging Variables
$Timestamp    = [DateTime]::Now.ToString('yyMMdd-HHmmssffff')
$PathDirLog   = ('{0}\IronstoneIT\Intune\DeviceConfiguration\' -f ($(if($DeviceContext -and $CurrentUserCorrect){$env:ProgramW6432}else{$env:APPDATA})))
$PathFileLog  = ('{0}{1}-{2}bit-{3}.txt' -f ($PathDirLog,$NameScriptFull,$ProcessArchitecture,$Timestamp))

# Start Transcript
if (-not(Test-Path -Path $PathDirLog)) {New-Item -ItemType 'Directory' -Path $PathDirLog -ErrorAction 'Stop'}
Start-Transcript -Path $PathFileLog

# Output User Info, Exit if not $CurrentUserCorrect
Write-Output -InputObject ('Running as user "{0}". Has admin privileges? {1}. $DeviceContext = {2}. Running as correct user? {3}.' -f ($StrUserName,$StrIsAdmin,$DeviceContext.ToString(),$CurrentUserCorrect.ToString()))
if (-not($CurrentUserCorrect)){Throw 'Not running as correct user!'} 

# Output Process and OS Architecture Info
Write-Output -InputObject ('PowerShell is running as a {0} bit process on a {1} bit OS.' -f ($ProcessArchitecture,$OSArchitecture))


# Wrap in Try/Catch, so we can always end the transcript
Try {    
    # If OS is 64 bit, and PowerShell got launched as x86, relaunch as x64
    if ( (-not([System.Environment]::Is64BitProcess))  -and [System.Environment]::Is64BitOperatingSystem) {
        write-Output -InputObject (' * Will restart this PowerShell session as x64.')
        if ($myInvocation.Line) {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
        }
        else {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -File ('{0}' -f ($myInvocation.InvocationName)) $args
        }
        exit $lastexitcode
    }
    
    # End the Initialize Region
    Write-Output -InputObject ('**********************')
#endregion Don't Touch This
################################################
#region    Your Code Here
################################################


    #region    ONLY EDIT THESE VALUES
        [string] $CheckRegPath  = 'HKCU:\Software\Citrix\Dazzle\Sites\backegrupp-ea578b8b\configUrl'                # EXAMPLE 'HKCU:\Software\Citrix\Dazzle\Sites\backegrupp-ea578b8b\configUrl'
        [string] $CheckRegValue = 'https://storefront.backe.no/Citrix/BackeGruppen/discovery'                # EXAMPLE 'https://storefront.backe.no/Citrix/BackeGruppen/discovery'

        # Settings
        [bool] $ReadOnly   = $false
        $VerbosePreference = 'Continue'

        #region    Registry file @('Filename.ext','BASE64-encoded-string')
        [string[]] $RegFile = @('TempRegFile.reg','V2luZG93cyBSZWdpc3RyeSBFZGl0b3IgVmVyc2lvbiA1LjAwCgpbSEtFWV9DVVJSRU5UX1VTRVJcU29mdHdhcmVcQ2l0cml4XQoKW0hLRVlfQ1VSUkVOVF9VU0VSXFNvZnR3YXJlXENpdHJpeFxEYXp6bGVdCiJDdXJyZW50QWNjb3VudCI9ImJhY2tlZ3J1cHAtZWE1NzhiOGIiCgpbSEtFWV9DVVJSRU5UX1VTRVJcU29mdHdhcmVcQ2l0cml4XERhenpsZVxTaXRlc10KCltIS0VZX0NVUlJFTlRfVVNFUlxTb2Z0d2FyZVxDaXRyaXhcRGF6emxlXFNpdGVzXGJhY2tlZ3J1cHAtZWE1NzhiOGJdCiJ0eXBlIj0iRFMiCiJuYW1lIj0iQmFja2VHcnVwcGVuIgoiY29uZmlnVXJsIj0iaHR0cHM6Ly9zdG9yZWZyb250LmJhY2tlLm5vL0NpdHJpeC9CYWNrZUdydXBwZW4vZGlzY292ZXJ5IgoiQ29uZmlndXJlZEJ5QWRtaW5pc3RyYXRvciI9IkZhbHNlIgoiZW5hYmxlZEJ5QWRtaW4iPSJUcnVlIgoic2VydmljZVJlY29yZElkIj0iMzUwOTg3MjkxMyIKInJlc291cmNlc1VybCI9Imh0dHBzOi8vc3RvcmVmcm9udC5iYWNrZS5uby9DaXRyaXgvQmFja2VHcnVwcGVuL3Jlc291cmNlcy92MiIKInNlc3Npb25VcmwiPSJodHRwczovL3N0b3JlZnJvbnQuYmFja2Uubm8vQ2l0cml4L0JhY2tlR3J1cHBlbi9zZXNzaW9ucy92MS9hdmFpbGFibGUiCiJhdXRoRW5kcG9pbnRVcmwiPSJodHRwczovL3N0b3JlZnJvbnQuYmFja2Uubm8vQ2l0cml4L0F1dGhlbnRpY2F0aW9uL2VuZHBvaW50cy92MSIKInRva2VuVmFsaWRhdGlvblVybCI9Imh0dHBzOi8vc3RvcmVmcm9udC5iYWNrZS5uby9DaXRyaXgvQXV0aGVudGljYXRpb24vYXV0aC92MS90b2tlbi92YWxpZGF0ZS8iCiJ0b2tlblNlcnZpY2VVcmwiPSJodHRwczovL3N0b3JlZnJvbnQuYmFja2Uubm8vQ2l0cml4L0F1dGhlbnRpY2F0aW9uL2F1dGgvdjEvdG9rZW4iCgpbSEtFWV9DVVJSRU5UX1VTRVJcU29mdHdhcmVcQ2l0cml4XFJlY2VpdmVyXQoKW0hLRVlfQ1VSUkVOVF9VU0VSXFNvZnR3YXJlXENpdHJpeFxSZWNlaXZlclxDdHhBY2NvdW50XQoKW0hLRVlfQ1VSUkVOVF9VU0VSXFNvZnR3YXJlXENpdHJpeFxSZWNlaXZlclxDdHhBY2NvdW50XDIwMDY5ZGI0LThiMWEtNGYzZS04YjI0LTMyNTMyNTEwYWEyYl0KIk5hbWUiPSJCYWNrZUdydXBwZW4iCiJVcGRhdGVyVHlwZSI9Im5vbmUiCiJDb250ZW50SGFzaCI9IjE3MDAwMTMwMTkiCiJBY2NvdW50U2VydmljZVVybCI9Imh0dHBzOi8vc3RvcmVmcm9udC5iYWNrZS5uby9DaXRyaXgvUm9hbWluZy9BY2NvdW50cyIKIlRva2VuU2VydmljZVVybCI9Imh0dHBzOi8vc3RvcmVmcm9udC5iYWNrZS5uby9DaXRyaXgvQXV0aGVudGljYXRpb24vYXV0aC92MS90b2tlbiIKIklzUHVibGlzaGVkIj0idHJ1ZSIKIklzUHJpbWFyeSI9InRydWUiCiJJc0VuYWJsZWQiPSJ0cnVlIgoKW0hLRVlfQ1VSUkVOVF9VU0VSXFNvZnR3YXJlXENpdHJpeFxSZWNlaXZlclxTUl0KCltIS0VZX0NVUlJFTlRfVVNFUlxTb2Z0d2FyZVxDaXRyaXhcUmVjZWl2ZXJcU1JcU3RvcmVdCgpbSEtFWV9DVVJSRU5UX1VTRVJcU29mdHdhcmVcQ2l0cml4XFJlY2VpdmVyXFNSXFN0b3JlXDM1MDk4NzI5MTNdCiJOYW1lIj0iQmFja2VHcnVwcGVuIgoiQWRkciI9Imh0dHBzOi8vc3RvcmVmcm9udC5iYWNrZS5uby9DaXRyaXgvQmFja2VHcnVwcGVuL2Rpc2NvdmVyeSIKIlNSVHlwZSI9ZHdvcmQ6MDAwMDAwMDAKCltIS0VZX0NVUlJFTlRfVVNFUlxTb2Z0d2FyZVxDaXRyaXhcUmVjZWl2ZXJcU1JcU3RvcmVcMzUwOTg3MjkxM1xCZWFjb25zXQoKW0hLRVlfQ1VSUkVOVF9VU0VSXFNvZnR3YXJlXENpdHJpeFxSZWNlaXZlclxTUlxTdG9yZVwzNTA5ODcyOTEzXEJlYWNvbnNcRXh0ZXJuYWxdCgpbSEtFWV9DVVJSRU5UX1VTRVJcU29mdHdhcmVcQ2l0cml4XFJlY2VpdmVyXFNSXFN0b3JlXDM1MDk4NzI5MTNcQmVhY29uc1xFeHRlcm5hbFxBZGRyMF0KIkFkZHJlc3MiPSJodHRwczovL2NpdHJpeC5iYWNrZS5ubyIKIkRTY29uZmlybWVkIj1kd29yZDowMDAwMDAwMAoKW0hLRVlfQ1VSUkVOVF9VU0VSXFNvZnR3YXJlXENpdHJpeFxSZWNlaXZlclxTUlxTdG9yZVwzNTA5ODcyOTEzXEJlYWNvbnNcRXh0ZXJuYWxcQWRkcjFdCiJBZGRyZXNzIj0iaHR0cDovL3d3dy5jaXRyaXguY29tIgoiRFNjb25maXJtZWQiPWR3b3JkOjAwMDAwMDAwCgpbSEtFWV9DVVJSRU5UX1VTRVJcU29mdHdhcmVcQ2l0cml4XFJlY2VpdmVyXFNSXFN0b3JlXDM1MDk4NzI5MTNcQmVhY29uc1xJbnRlcm5hbF0KCltIS0VZX0NVUlJFTlRfVVNFUlxTb2Z0d2FyZVxDaXRyaXhcUmVjZWl2ZXJcU1JcU3RvcmVcMzUwOTg3MjkxM1xCZWFjb25zXEludGVybmFsXEFkZHIwXQoiQWRkcmVzcyI9Imh0dHBzOi8vc3RvcmVmcm9udC5iYWNrZS5uby8iCiJEU2NvbmZpcm1lZCI9ZHdvcmQ6MDAwMDAwMDAKCltIS0VZX0NVUlJFTlRfVVNFUlxTb2Z0d2FyZVxDaXRyaXhcUmVjZWl2ZXJcU1JcU3RvcmVcMzUwOTg3MjkxM1xHYXRld2F5c10KCltIS0VZX0NVUlJFTlRfVVNFUlxTb2Z0d2FyZVxDaXRyaXhcUmVjZWl2ZXJcU1JcU3RvcmVcMzUwOTg3MjkxM1xHYXRld2F5c1w5OXggTmV0c2NhbGVyXQoiTG9nb25Qb2ludCI9Imh0dHBzOi8vY2l0cml4LmJhY2tlLm5vIgoiRWRpdGlvbiI9ZHdvcmQ6MDAwMDAwMDIKIkF1dGgiPWR3b3JkOjAwMDAwMDAyCiJBR01vZGUiPWR3b3JkOjAwMDAwMDAwCiJUcnVzdGVkQnlVc2VyIj1kd29yZDowMDAwMDAwMAoiVHJ1c3RlZEJ5RFMiPWR3b3JkOjAwMDAwMDAwCiJJc0RlZmF1bHQiPWR3b3JkOjAwMDAwMDAxCgo=')
        #endregion Registry file @('Filename.ext','BASE64-encoded-string')
    #endregion ONLY EDIT THESE VALUES




    #region Functions
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
            if (Test-Path -Path $Dir) {
                $CurrentValue = (Get-ItemProperty -Path $Dir -Name $Key).$Key
                if ($CurrentValue -eq $ValueToCompare) {
                    Return $true
                }
            }
            Return $false
        }
        #endregion Test-RegistryValue


        #region    FileOut-FromBase64
            Function FileOut-FromBase64 {
                [CmdLetBinding()]

                # Parameters
                Param(
                    [Parameter(Mandatory=$true)]
                    [ValidateNotNullOrEmpty()]
                    [string] $PathDirOut,
            
                    [Parameter(Mandatory=$true)]
                    [ValidateNotNullOrEmpty()]
                    [string] $NameFileOut,
            
                    [Parameter(Mandatory=$true)]
                    [ValidateNotNullOrEmpty()]
                    [string] $ContentFileOut, 
            
                    [Parameter(Mandatory=$true)]
                    [ValidateSet('utf8','default')]
                    [string] $EncodingFileOut,

                    [Parameter(Mandatory=$false)]
                    [Switch] $Force
                )

                # Output Debug Info
                [byte] $SubstringLength = $(if($ContentFileOut.Length -lt 10){$ContentFileOut.Length}else{10})
                Write-Debug -Message ('FileOut-FromBase64 -PathDirOut "{0}" -NameFileOut "{1}" -ContentFileOut "{2}" -EncodingFileOut "{3}"' -f ($PathDirOut,$NameFileOut,($ContentFileOut.Substring(0,$SubstringLength)+'...'),$EncodingFileOut))
        

                # If writing to Program Files, and not admin
                if ($PathDirOut -like '*Program Files\*' -and (-not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
                    Throw ('Cannot write to "{0}" without admin rights!' -f ($PathDirOut))
                }
                else {
                    # Create Install Dir if not exist
                    if(-not(Test-Path -Path $PathDirOut)){New-Item -Path $PathDirOut -ItemType 'Directory' -Force}
                
                    # Continue only if Install Dir exist    
                    if (Test-Path -Path $PathDirOut) {
                        [string] $Local:PathFileOut = ('{0}{1}{2}' -f ($PathDirOut,($(if($PathDirOut[-1] -ne '\'){'\'})) + $NameFileOut)).Replace('\\','\')
                        Write-Verbose -Message ('   Path exists, trying to write the file (File alrady exists? {0}).' -f (Test-Path -Path $Local:PathFileOut))
                        if (-not($ReadOnly)) {
                            Out-File -FilePath $Local:PathFileOut -Encoding $EncodingFileOut -InputObject ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($ContentFileOut))) -Force:$Force
                            Write-Verbose -Message ('      Success? {0}.' -f ($?))
                            Write-Verbose -Message ('         Does file actually exist? {0}.' -f (Test-Path -Path $Local:PathFileOut -ErrorAction 'SilentlyContinue'))
                        }
                    }
                    else {
                        Throw ('ERROR: Install Path does not exist.')
                    }
                }
            }
        #endregion FileOut-FromBase64


        #region Query-Registry
        function Query-Registry {
            Param ([Parameter(Mandatory=$true)] [String] $Dir)
            $Local:Out = [String]::Empty
            [string] $Local:Key = $Dir.Split('{\}')[-1]
            [string] $Local:Dir = $Dir.Replace($Local:Key,'')
        
            $Local:Exists = Get-ItemProperty -Path ('{0}' -f $Dir) -Name ('{0}' -f $Local:Key) -ErrorAction 'SilentlyContinue'
            if ($Exists) {
                $Local:Out = $Local:Exists.$Local:Key
            }
            return $Local:Out
        }
        #endregion Query-Registry
    #endregion Functions




    #region Main
        # Check if value exists
        if (Test-RegistryValue -PathToCheck $CheckRegPath -ValueToCompare $CheckRegValue) {
            Write-Verbose -Message 'Reg dir already exists, and value are the same as the one compared with'
        }
        else {    
            [string] $Script:PathDirTemp = ('{0}\Temp' -f ($env:windir))
            [string] $Script:PathFileTemp = ('{0}\{1}' -f ($Script:PathDirTemp,$RegFile[0]))
            $null = Remove-Item -Path $Script:PathFileTemp -Force -ErrorAction 'SilentlyContinue'
            FileOut-FromBase64 -PathDirOut $Script:PathDirTemp -NameFileOut $RegFile[0] -ContentFileOut $RegFile[1] -EncodingFileOut 'default'

            if (-not(Test-Path -Path $Script:PathFileTemp)) {
                Write-Verbose -Message ('- Error: Could create "{0}".' -f ($Script:PathFileTemp))
            }
            else {  
                if (-not($ReadOnly)) {
                    Write-Verbose -Message ('   $ReadOnly is false, attempting to write new value')
                    [byte] $ExitCode = (Start-Process -FilePath ('{0}\reg.exe' -f ([System.Environment]::SystemDirectory)) -ArgumentList ('IMPORT "{0}" /reg:64' -f ($Script:PathFileTemp)) -NoNewWindow -Wait -PassThru).ExitCode
                    $null = & cmd /c ('"{0}\reg.exe" IMPORT "{1}" /reg:64' -f ([System.Environment]::SystemDirectory,$Script:PathFileTemp)) 2>&1
                    #$RegStatus = reg.exe import ('{0}' -f $Script:PathFileTemp) 2>&1
    
                    if (-not(($RegStatus -Like '*completed successfully*') -or ($RegStatus -Like '*operasjonen er utf?rt*'))) {
                        Write-Verbose -Message ('      Error reg.exe')  
                        Write-Verbose -Message ('      Reg.exe output:' + "`r`n" + $RegStatus + "`r`n" + ($Error | Select-Object -Property * ) + "`r`n")    
                    }  
                    else {
                        if (Test-RegistryValue -PathToCheck $CheckRegPath -ValueToCompare $CheckRegValue) {
                            Write-Verbose -Message ('      Success, Citrix config was written to registry')
                        }
                        else {
                            Write-Verbose -Message ('      Error, Citrix config was not written to registry.')
                        }
                    }
                }
                else {
                    Write-Verbose -Message ('   $ReadOnly, won`t attempt to write new registry value')
                }
            }
        }
    #endregion Main


################################################
#endregion Your Code Here
################################################   
#region    Don't touch this
}
Catch {
    # Construct Message
    $ErrorMessage = ('{0} finished with errors:' -f ($NameScriptFull))
    $ErrorMessage += " `n"
    $ErrorMessage += 'Exception: '
    $ErrorMessage += $_.Exception
    $ErrorMessage += " `n"
    $ErrorMessage += 'Activity: '
    $ErrorMessage += $_.CategoryInfo.Activity
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error Category: '
    $ErrorMessage += $_.CategoryInfo.Category
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error Reason: '
    $ErrorMessage += $_.CategoryInfo.Reason
    Write-Error -Message $ErrorMessage
}
Finally {
    Stop-Transcript
}
#endregion Don't touch this
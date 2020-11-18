#Requires -RunAsAdministrator

[string] $Path  = 'HKLM:\SOFTWARE\Wow6432Node\Lenovo\System Update'
[string] $Name  = 'DefaultLanguage'
[string] $Value = 'EN' 
[string] $Type  = 'String'
[uint16] $Times = 500

Write-Output -InputObject ('Set-ItemProperty {0} times takes {1} seconds.' -f ($Times,(
    (Measure-Command -Expression {[uint16[]]@(1..$Times) | ForEach-Object {$null = Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force}}).TotalSeconds)))


Write-Output -InputObject ('Checking value before Set-ItemProperty {0} times takes {1} seconds.' -f ($Times,(
    (Measure-Command -Expression {[uint16[]]@(1..$Times) | ForEach-Object {
        if ((Get-ItemProperty -Path $Path -Name $Name | Select-Object -ExpandProperty $Name) -ne $Value){
            $null = Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force}}}).TotalSeconds)))
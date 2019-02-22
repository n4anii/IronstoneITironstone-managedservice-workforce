# Test Metier
# Automate - Check File Paths
# PowerShell
~(Get-ChildItem -Path ('{0}\Users\Public' -f ($env:SystemDrive)) -Directory -Recurse:$false -Force)
~(Get-ChildItem -Path ('{0}\Users\Public\OfficeTemplates' -f ($env:SystemDrive)) -File -Recurse:$false -Force)

# CMD
dir "C:\Users\Public\OfficeTemplateMO"


# Automate - Check Registry Entries
~(Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Office\16.0\Word\Options' -f ([System.Security.Principal.NTAccount]::new(@(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value)))
~(Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Office\16.0\Word\Options' -f ([System.Security.Principal.NTAccount]::new(@(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value)) -Name 'PersonalTemplates' | Select-Object -ExpandProperty 'PersonalTemplates')

	
# Automate - Check PowerShell from Intune Logs
# PowerShell
~(Get-Content -Path (Get-ChildItem -Path ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f ($env:ProgramW6432)) -File | Where-Object {$_.Name -like ('Device_Install-IronSync*-64bit*')} | Sort-Object -Property 'LastWriteTime' | Select-Object -Last 1 -ExpandProperty 'FullName') -Raw)

<#
    INFO
        Group 
	        * MDM Win10 - Conf Dev - Office365 Templates (olavb@ironstoneit.com)	bb563fec-77df-4c89-8545-e72d7cb335cf
	
        Users
	        * Disa Magnusdottir 	disa.magnusdottir@metier.no
		        * Device: 			DESKTOP-DQTMN4V									54348cae-1e08-4227-b15c-c774d4555f93
	
	        * Geir Bergersen		geir.bergersen@metier.no						3786fd82-da7b-477d-8107-7882fdd56708
		        * Device:			DESKTOP-FKN1OPR 								535f8e12-565a-4d69-b5aa-a20bfad39cfc
#>
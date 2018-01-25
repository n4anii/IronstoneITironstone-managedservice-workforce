#$ErrorActionPreference = "SilentlyContinue"
start-transcript c:\tepiut2.txt

$Logsource = 'Ironstone-Intune'
$LogNAme = 'Application'
$RegistryPath = 'HKLM:\SOFTWARE\IronstoneIT\Intune\'
$RegistryKeyName = 'Disablesmb1protocol'

#Check if log source exist, else create it
$log = [Diagnostics.EventLog]::SourceExists($Logsource)
if ($log -eq $false) 
{
    New-EventLog -LogName Application -Source $Logsource
}

#Check if the script has ran previously
$RegistryKeyExists = Get-ItemProperty -Path $RegistryPath -Name $RegistryKeyName -ErrorAction SilentlyContinue
If ([string]::IsNullOrWhiteSpace($RegistryKeyExists))
{
    $Message = 'Exiting. Disable SMB1 has already run'
    Write-EventLog -Source $Logsource -LogName $LogName -EventId 1 -EntryType information -Message $Message
    #Exit
}


Disable-WindowsOptionalFEature -Online -FeatureName smb1protocol -Norestart
Get-AppxPackage "*D5EA27B7.Duolingo-LearnLanguagesforFree*"  | Remove-AppxPackage 
Get-AppxPackage "*46928bounde.EclipseManager*"  | Remove-AppxPackage 
Get-AppxPackage "Microsoft.Office.OneNote"  | Remove-AppxPackage 
Get-AppxPackage "*Minecraft*"  | Remove-AppxPackage 
Get-AppxPackage "*DrawboardPDF*"  | Remove-AppxPackage 
Get-AppxPackage "*FarmVille2CountryEscape*"  | Remove-AppxPackage 
Get-AppxPackage "*Asphalt8Airborne*"  | Remove-AppxPackage 
Get-AppxPackage "*PandoraMediaInc*"  | Remove-AppxPackage 
Get-AppxPackage "*CandyCrushSodaSaga*"  | Remove-AppxPackage 
Get-AppxPackage "*MicrosoftSolitaireCollection*"  | Remove-AppxPackage 
Get-AppxPackage "*Twitter*"  | Remove-AppxPackage 
Get-AppxPackage "*bingsports*"  | Remove-AppxPackage 
Get-AppxPackage "*bingfinance*"  | Remove-AppxPackage 
Get-AppxPackage "*BingNews*"  | Remove-AppxPackage 
Get-AppxPackage "*windowsphone*"  | Remove-AppxPackage 
Get-AppxPackage "*Netflix*"  | Remove-AppxPackage 
Get-AppxPackage "*ZuneVideo*"  | Remove-AppxPackage 
Get-AppxPackage "*Facebook*"  | Remove-AppxPackage 
Get-AppxPackage "*Microsoft.SkypeApp*"  | Remove-AppxPackage 
Get-AppxPackage "*SkypeApp*"  | Remove-AppxPackage 
Get-AppxPackage "*ZuneMusic*"  | Remove-AppxPackage 
Get-AppxPackage "*Microsoft.MinecraftUWP*"  | Remove-AppxPackage 
Get-AppxPackage "*MarchofEmpires*"  | Remove-AppxPackage 
Get-AppxPackage "*RoyalRevolt2*"  | Remove-AppxPackage 
Get-AppxPackage "*AdobePhotoshopExpress*"  | Remove-AppxPackage 
Get-AppxPackage "*ActiproSoftwareLLC*"  | Remove-AppxPackage 
Get-AppxPackage "*Duolingo-LearnLanguagesforFree*"  | Remove-AppxPackage 
Get-AppxPackage "*EclipseManager*"  | Remove-AppxPackage 
Get-AppxPackage "*KeeperSecurityInc.Keeper*"  | Remove-AppxPackage 
Get-AppxPackage "*king.com.BubbleWitch3Sag*"  | Remove-AppxPackage 
Get-AppxPackage "*89006A2E.AutodeskSketchBook*"  | Remove-AppxPackage 
Get-AppxPackage "*CAF9E577.Plex*"  | Remove-AppxPackage 
Get-AppxPackage "*Microsoft.Office.Onenote*"  | Remove-AppxPackage 

Write-output "test output"
Write-Verbose "Test verbose" -verbose
  New-Item -Path 'HKLM:\SOFTWARE\IronstoneIT\Intune\' -force
New-ItemProperty -Path $RegistryPath -Name $RegistryKeyName  -PropertyType String -Value 'True' -force


stop-transcript
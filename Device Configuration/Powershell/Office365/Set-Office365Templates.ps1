#Variables
$ScriptVersion = '16'
$MyInvocationPath = $MyInvocation.MyCommand.Path
$RegistryPath = 'HKCU:\SOFTWARE\IronstoneIT\Intune\'
$RegistryKeyName = ('Office365TemplatesV{0}' -f $scriptversion)
$LogLocation = "$env:HOMEDRIVE\temp\"
$LogLocationFullName = ('{0}Set-Office365Templates_log{1}.txt' -f $LogLocation, $scriptversion)
$ScheduledTaskName = 'Configure Office 365 Templates'

#Must be done here, because of permissions
if (!(test-path -Path $LogLocationFullName)) {
	New-item -ItemType Directory -Path $LogLocation -force
	New-item -ItemType file -Path $LogLocationFullName  
	Add-Content -Value 'Time,PID,Message' -Path $LogLocationFullName
}

copy-item -Path $MyInvocationPath -Destination ('{0}\set-office365templates.ps1' -f $LogLocation) -Force

#Kickoff the process as 64 bit
if ($env:PROCESSOR_ARCHITEW6432 -eq 'AMD64') {
    #write-error "Y'arg Matey, we're off to the 64-bit land....." -erroraction continue
    if ($myInvocation.Line) {
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
    }else{
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file ('{0}' -f $myInvocation.InvocationName) $args
    }
exit $lastexitcode
}

Function Write-Customlog {
    Param(
      [String]$message,
      [string]$logname
    )
	[string]$output = $(Get-date -format HH:mm:ss)
    $output += ','
	$output += $Pid
	$output +=  ','
    $output += $message
	
    Add-Content -Value $output -Path $logname

}

Write-Customlog -message ('version {0}' -f $scriptversion) -logname $LogLocationFullName


#Check if the script has ran previously
$RegistryKeyExists = Get-ItemProperty -Path $RegistryPath -Name $RegistryKeyName -ErrorAction SilentlyContinue
If ([string]::IsNullOrWhiteSpace($RegistryKeyExists))
{

  Write-Customlog -message 'Setting registry keys and copying invocation script' -logname $LogLocationFullName

  
  New-Item -Path $RegistryPath -force
  New-ItemProperty -Path $RegistryPath -Name $RegistryKeyName  -PropertyType String -Value 'True' -force

   Write-Customlog -message 'Creating scheduled task' -logname $LogLocationFullName
  $Argument = ("-NoProfile -WindowStyle Hidden -command `"if ((Get-ExecutionPolicy) -eq `'Restricted`' ){{Set-ExecutionPolicy RemoteSigned -Scope Process -Force }};& {0}set-office365templates.ps1`"" -f ($Loglocation))
  $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $Argument
  $trigger =  New-ScheduledTaskTrigger -once -At 9am
  Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $ScheduledTaskName -Description $ScheduledTaskName
  Write-Customlog -message 'Starting scheduled task' -logname $LogLocationFullName
  Start-ScheduledTask -TaskName $ScheduledTaskName
  

  $timeout = 120 ##  seconds
  $timer =  [Diagnostics.Stopwatch]::StartNew()
  Write-Customlog -message 'waiting for scheduled task' -logname $LogLocationFullName
  while (((Get-ScheduledTask -TaskName $ScheduledTaskName).State -ne  'Ready') -and  ($timer.Elapsed.TotalSeconds -lt $timeout)) {    

    Start-Sleep -Seconds  10  
    Write-Customlog -message ('Waited for {0}' -f $timer.elapsed) -logname $LogLocationFullName
  }

  $timer.Stop()
 # Unregister-ScheduledTask -TaskName $ScheduledTaskName -Confirm:$false
  remove-item -Path "$env:HOMEDRIVE\temp\set-office365templates.ps1" -Force
  Write-Customlog -message 'scheduled task completed. Exiting' -logname $LogLocationFullName

 
  exit

}
else {

  Write-Customlog -message 'start of part 2' -logname $LogLocationFullName
  #Variables
  $RegistryPathPowerPoint = 'HKCU:\Software\Microsoft\Office\16.0\PowerPoint\Options'
  $RegistryPathWord = 'HKCU:\Software\Microsoft\Office\16.0\Word\Options'
  $RegistryPathExcel = 'HKCU:\Software\Microsoft\Office\16.0\Excel\Options'
  $RegistryKeyName = 'PersonalTemplates'
  $SharepointSite = 'metiero365.sharepoint.com/sites/MetierOECIntranet/Maler'
  $TrustedSite = 'metiero365'
  $SiteUrl = ('https://{0}' -f $SharepointSite)

  #Functions
  function Add-SiteToIEZone{
    Param(
      [String]$siteUrl
    )
    try{
      $components = $siteUrl.Split('.')
      $count = $components.Count
      if($count -gt 3){
        $old = $components
        $components = @()
        $subDomainString = ''
        for($i=0;$i -le $count-3;$i++){
          if($i -lt $count-3){$subDomainString += ('{0}.' -f ($old[$i]))}else{$subDomainString += ('{0}' -f ($old[$i]))}
        }
        $components += $subDomainString
        $components += $old[$count-2]
        $components += $old[$count-1]    
      }
      if($count -gt 2){
        $Null = New-Item -Path ('hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}' -f ($components[1]), ($components[2])) -ErrorAction SilentlyContinue 
        $Null = New-Item -Path ('hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}\{2}' -f ($components[1]), ($components[2]), ($components[0])) -ErrorAction SilentlyContinue
        $Null = New-ItemProperty -Path ('hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}\{2}' -f ($components[1]), ($components[2]), ($components[0])) -Name 'https' -Value 2 -ErrorAction Stop
      }else{
        $Null = New-Item -Path ('hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}' -f ($components[0]), ($components[1])) -ErrorAction SilentlyContinue 
        $Null = New-ItemProperty -Path ('hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}' -f ($components[0]), ($components[1])) -Name 'https' -Value 2 -ErrorAction Stop
      }
    }catch{
      Return $_
    }
    return $True
  }

  #Code
  Write-Customlog -message 'Adding sites to IE zones' -logname $LogLocationFullName
  Add-SiteToIEZone -siteUrl ('{0}.sharepoint.com' -f $TrustedSite)
  Add-SiteToIEZone -siteUrl ('{0}-files.sharepoint.com' -f $TrustedSite)
  Add-SiteToIEZone -siteUrl ('{0}-my.sharepoint.com' -f $TrustedSite)
  Add-SiteToIEZone -siteUrl ('{0}-myfiles.sharepoint.com' -f $TrustedSite)

#Open Google
      Write-Customlog -message 'Opening Browser and navigating to google.no' -logname $LogLocationFullName
	  
     Start-Process -FilePath 'iexplore.exe' -ArgumentList 'https://google.no'

	 #######
#Google
########
	 
# Text to match in element
$elementMatchText = "Google"
$timeoutMilliseconds = 50000 
$timeStart = Get-Date
$exitFlag = $false 

do {
    Start-Sleep -milliseconds 500
    $ie2 = (New-Object -ComObject 'Shell.Application').Windows() | Where-Object { $_.Name -eq 'Internet Explorer' -and $_.LocationURL -eq "https://www.google.no/" }
    if ( $ie2.ReadyState -eq 4 ) {
      
        $elementText = $ie2.document.body.outerHTML
        $elementMatch = $elementText -match $elementMatchText
        if ( $elementMatch ) { $loadTime = (Get-Date).subtract($timeStart) }
    }
  Write-Customlog -message "IE REadySTate: $($ie2.ReadyState)" -logname $LogLocationFullName
    $timeout = ((Get-Date).subtract($timeStart)).TotalMilliseconds -gt $timeoutMilliseconds
    $exitFlag = $elementMatch -or $timeout
} until ( $exitFlag )

    Start-Sleep -Seconds 2
$elementText | out-file c:\temp\body_google.txt
Write-Customlog -message "Match element found: $($elementMatch)"  -logname $LogLocationFullName
Write-Customlog -message "Timeout: $($timeout)"  -logname $LogLocationFullName
Write-Customlog -message "Load Time: $($loadTime)"  -logname $LogLocationFullName

#######
#Metier OEC
#########
	  
# Text to match in element
$elementMatchText = "Metier OEC Intranet"
Write-Customlog -message ('Opening {0} in IE' -f ($siteurl)) -logname $LogLocationFullName
$navOpenInBackgroundTab = 65536
$ie = $null
#Write-Output "IE is running"
$ie = (New-Object -ComObject 'Shell.Application').Windows() | Where-Object { $_.Name -eq 'Internet Explorer' }
Start-sleep -milliseconds 100
$ie.Navigate2($SiteUrl, $navOpenInBackgroundTab)
$timeStart = Get-Date
$timeout = $null
$exitFlag = $false
$elementMatch = $false
do {
        Start-Sleep -milliseconds 500
    $ie3 = (New-Object -ComObject 'Shell.Application').Windows() | Where-Object { $_.Name -eq 'Internet Explorer' -and $_.LocationURL -match $siteurl}
	 Write-Customlog -message "IE3 object: $($ie3.LocationURL)" -logname $LogLocationFullName
    if ( $ie3.ReadyState -eq 4 ) {
      
        $elementText = $ie3.document.body.outerHTML
        $elementMatch = $elementText -match $elementMatchText
        if ( $elementMatch ) { $loadTime = (Get-Date).subtract($timeStart) }
    }
	Write-Customlog -message "IE REadySTate: $($ie3.ReadyState)" -logname $LogLocationFullName
    $timeout = ((Get-Date).subtract($timeStart)).TotalMilliseconds -gt $timeoutMilliseconds
    $exitFlag = $elementMatch -or $timeout
} until ( $exitFlag )

$elementText | out-file c:\temp\metier.txt
(New-Object -ComObject 'Shell.Application').Windows() | out-file c:\temp\comobjectdebug.txt
Write-Customlog -message "Match element found: $($elementMatch)"  -logname $LogLocationFullName
Write-Customlog -message "Timeout: $($timeout)"  -logname $LogLocationFullName
Write-Customlog -message "Load Time: $($loadTime)"  -logname $LogLocationFullName
	  
	  
#cleanup IE
Write-Customlog -message 'Cleaning up' -logname $LogLocationFullName
(New-Object -COM 'Shell.Application').Windows() | Where-Object {
$_.Name -like '*Internet Explorer*'
} | ForEach-Object {
	$_.Quit()
	[Runtime.Interopservices.Marshal]::ReleaseComObject($_)
}
Write-Customlog -message 'GB done' -logname $LogLocationFullName

[GC]::Collect()
[GC]::WaitForPendingFinalizers()

  #Map drive and get drive letter
  # DO NOT CONFIGURE a drive letter manually, as it will never show up in file explorer, even with a restart of file explorer
  Write-Customlog -message 'Mapping onedrive share' -logname $LogLocationFullName
  [string]$drive = & "$env:windir\system32\net.exe" use * $siteUrl /persistent:yes
  $Driveletter = ($drive | Select-string -pattern '(.*)([d-zD-Z]:) (.*)'  | ForEach-Object {$_.matches}).groups[2].value


  Write-Customlog -message 'Setting Office regkeys' -logname $LogLocationFullName
  #Set PersonalTemplate value for PPT
  if(!(Test-path -Path $RegistryPathPowerPoint))
  {
    $null = New-Item -Path $RegistryPathPowerPoint -Force
    $null = New-ItemProperty -Path $RegistryPathPowerPoint -Name $RegistryKeyName -Value $DriveLetter -PropertyType Expandstring -Force
  }
  ELSE 
  {
    $null = New-ItemProperty -Path $RegistryPathPowerPoint -Name $RegistryKeyName -Value $DriveLetter -PropertyType Expandstring -Force
  }
  #Set PersonalTemplate  value for Word
  if(!(Test-path -Path $RegistryPathWord))
  {
    $null = New-Item -Path $RegistryPathWord -Force
    $null = New-ItemProperty -Path $RegistryPathWord -Name $RegistryKeyName -Value $DriveLetter -PropertyType Expandstring -Force
  }
  ELSE 
  {
    $null = New-ItemProperty -Path $RegistryPathWord -Name $RegistryKeyName -Value $DriveLetter -PropertyType Expandstring -Force
  }
  #Set PersonalTemplate  value for Excel
  if(!(Test-path -Path $RegistryPathExcel))
  {
    $null = New-Item -Path $RegistryPathExcel -Force
    $null = New-ItemProperty -Path $RegistryPathExcel -Name $RegistryKeyName -Value $DriveLetter -PropertyType Expandstring -Force
  }
  ELSE 
  {
    $null = New-ItemProperty -Path $RegistryPathExcel -Name $RegistryKeyName -Value $DriveLetter -PropertyType Expandstring -Force
  }

  Write-Customlog -message 'Completed, exiting.' -logname $LogLocationFullName
}
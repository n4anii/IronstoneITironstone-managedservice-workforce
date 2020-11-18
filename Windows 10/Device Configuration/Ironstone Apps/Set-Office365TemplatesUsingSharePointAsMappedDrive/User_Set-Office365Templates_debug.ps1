@@ -0,0 +1,368 @@
﻿<#

    .SYNOPSIS
    Removes all specified pre-installed applications from the users profile.

    .DESCRIPTION
    Removes all specified pre-installed applications from the users profile. This script MUST be deployed together with Device_Uninstall-Bloatware.ps1, else the apps will come back.

    .NOTES
    You need to run this script in the USER context in Intune.

    .todo
    - Registry key to check if intranet sites are already set
    - Output logging of office keys  

#>
$AppName = 'User_set-Office365Templates'
$Timestamp = Get-Date -Format 'HHmmssffff'
$LogDirectory = ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f $env:APPData)
$Transcriptname = ('{2}\{0}_{1}.txt' -f $AppName, $Timestamp, $LogDirectory)
$RegistryPathIntranet = 'HKCU:\SOFTWARE\IronstoneIT\Intune\DeviceConfiguration'
$ErrorActionPreference = 'continue'

if (!(Test-Path -Path $LogDirectory)) {
  New-Item -ItemType Directory -Path $LogDirectory -ErrorAction Stop
}
Start-Transcript -Path $Transcriptname


#Wrap in a try/catch, so we can always end the transcript
Try {

  #64-bit invocation
  if ($env:PROCESSOR_ARCHITEW6432 -eq 'AMD64') {
    write-Output -InputObject "Y'arg Matey, we're off to the 64-bit land....."
    if ($myInvocation.Line) {
      &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
    }else{
      &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file ('{0}' -f $myInvocation.InvocationName) $args
    }
    exit $lastexitcode
  }


  #Variables
  $RegistryPathPowerPoint = 'HKCU:\Software\Microsoft\Office\16.0\PowerPoint\Options'
  $RegistryPathWord = 'HKCU:\Software\Microsoft\Office\16.0\Word\Options'
  $RegistryPathExcel = 'HKCU:\Software\Microsoft\Office\16.0\Excel\Options'
  $RegistryKeyName = 'PersonalTemplates'
  $SharepointSite = 'metiero365.sharepoint.com/sites/MetierOECIntranet/Maler'
  $TrustedSite = 'metiero365'
  $SiteUrl = ('https://{0}' -f $SharepointSite)
	
  $DriveLetter = 'K:'
	
  $FirstSiteURL = 'https://www.google.no'
  $FirstSiteelementMatchText = 'Google'
  $SecondSiteURL = $siteurl
  $SecondSiteelementMatchText = 'Metier OEC Intranet'
	

  #Functions
  function Add-SiteToIEZone {
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
        if (!(Test-path -Path ('hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}' -f ($components[1]), ($components[2])))) {
          New-Item -Path ('hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}' -f ($components[1]), ($components[2])) -ErrorAction Stop 
          Write-Output -InputObject ('Created item [hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}].' -f ($components[1]), ($components[2]))
        }
        if (!(test-path -Path ('hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}\{2}' -f ($components[1]), ($components[2]), ($components[0])))) {
          New-Item -Path ('hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}\{2}' -f ($components[1]), ($components[2]), ($components[0])) -ErrorAction SilentlyContinue
          Write-Output -InputObject ('Created item [hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}\{2}].' -f ($components[1]), ($components[2]), ($components[0]))
        }
        if (!(test-path -Path ('hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}\{2}' -f ($components[1]), ($components[2]), ($components[0])))) {
          New-ItemProperty -Path ('hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}\{2}' -f ($components[1]), ($components[2]), ($components[0])) -Name 'https' -Value 2 -ErrorAction Stop
          Write-Output -InputObject ('Created itemproperty named https at [hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}\{2}]' -f ($components[1]), ($components[2]), ($components[0]))
        }
          
      }else{
        if (!(test-path -Path ('hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}' -f ($components[0]), ($components[1])))) {
          New-Item -Path ('hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}' -f ($components[0]), ($components[1])) -ErrorAction SilentlyContinue
          Write-Output -InputObject ('Created item [hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}].' -f ($components[0]), ($components[1]))
        }
        if (!(test-path -Path ('hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}' -f ($components[0]), ($components[1])))) {
          New-ItemProperty -Path ('hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}' -f ($components[0]), ($components[1])) -Name 'https' -Value 2 -ErrorAction Stop
          Write-Output -InputObject ('Created itemproperty named https at [hkcu:\software\microsoft\windows\currentversion\internet settings\zonemap\domains\{0}.{1}]' -f ($components[0]), ($components[1]))
        }
      }
     
    }catch{
      Return $_
    }
    return $True
  }
  
  $BrowseSitesWithIE = $false
  
  $Zone1 = ('IntranetBrowsedWithIE_{0}.sharepoint.com' -f $TrustedSite)
  $Zone2 = ('IntranetBrowsedWithIE_{0}-files.sharepoint.com' -f $TrustedSite)
  $Zone3 = ('IntranetBrowsedWithIE_{0}-my.sharepoint.com' -f $TrustedSite)
  $Zone4 = ('IntranetBrowsedWithIE_{0}-myfiles.sharepoint.com' -f $TrustedSite)
    

  #Code
  

  if (!(Get-ItemPropertyValue -Path $RegistryPathIntranet -Name $Zone1)) {
    Write-output "zone 1"
    $Null = Add-SiteToIEZone -siteUrl ('{0}.sharepoint.com' -f $TrustedSite)
    $BrowseSitesWithIE = $true
  }
  else {
    Write-Output -InputObject ('IE Zone [{0}] already set.' -f ('{0}.sharepoint.com' -f $TrustedSite))
  }
    if (!(Get-ItemPropertyValue -Path $RegistryPathIntranet -Name $Zone2)) {
    Write-output "zone 2"
    $Null = Add-SiteToIEZone -siteUrl ('{0}-files.sharepoint.com' -f $TrustedSite)
    $BrowseSitesWithIE = $true
  }
  else {
    Write-Output -InputObject ('IE Zone [{0}] already set.' -f ('{0}-files.sharepoint.com' -f $TrustedSite))
  }
    if (!(Get-ItemPropertyValue -Path $RegistryPathIntranet -Name $Zone3)) {
    Write-output "zone 3"
    $Null = Add-SiteToIEZone -siteUrl ('{0}-my.sharepoint.com' -f $TrustedSite)
    $BrowseSitesWithIE = $true
  }
  else {
    Write-Output -InputObject ('IE Zone [{0}] already set.' -f ('{0}-my.sharepoint.com' -f $TrustedSite))
  }
    if (!(Get-ItemPropertyValue -Path $RegistryPathIntranet -Name $Zone4)) {
    Write-output "zone 4"
    $Null = Add-SiteToIEZone -siteUrl ('{0}-myfiles.sharepoint.com' -f $TrustedSite)
    $BrowseSitesWithIE = $true
  }
  else {
    Write-Output -InputObject ('IE Zone [{0}] already set.' -f ('{0}-myfiles.sharepoint.com' -f $TrustedSite))
  }
  
  
  #If the sites have been loaded in IE before, skip to the adding driveletter part
  if ($BrowseSitesWithIE) {

    #Open first site
    Write-Output -InputObject ('Opening Internet explorer and navigating to [{0}].' -f $FirstSiteURL)
    Start-Process -FilePath 'iexplore.exe' -ArgumentList $FirstSiteURL

  
    $timeoutMilliseconds = 5000 
    $timeStart = Get-Date
    $exitFlag = $false 

    do
    {
      Start-Sleep -milliseconds 500
      $ie2 = (New-Object -ComObject 'Shell.Application').Windows() | Where-Object { $_.Name -eq 'Internet Explorer' -and $_.LocationURL -match $FirstSiteURL }

      if ( $ie2.ReadyState -eq 4 ) {
        $elementText = $ie2.document.body.outerHTML
        $elementMatch = $elementText -match $FirstSiteelementMatchText
        if ( $elementMatch ) { 
          $loadTime = (Get-Date).subtract($timeStart) 
          Start-sleep -milliseconds 100
        }
      }
    
      Write-Output -InputObject ('Site [{1}] Readystate [{0}].' -f $ie2.ReadyState, $FirstSiteURL)
    
      $timeout = ((Get-Date).subtract($timeStart)).TotalMilliseconds -gt $timeoutMilliseconds
      $exitFlag = $elementMatch -or $timeout
    } until ( $exitFlag )

    #$elementText | out-file -FilePath $env:HOMEDRIVE\temp\metier.txt
    #(New-Object -ComObject 'Shell.Application').Windows() | out-file -FilePath $env:HOMEDRIVE\temp\comobjectdebug.txt

    Write-Output -InputObject ('Match element [{0}]' -f ($FirstSiteelementMatchText)) 
    Write-Output -InputObject ('Timeout [{0}]' -f ($timeout)) 
    Write-Output -InputObject ('Load Time [{0}]' -f ($loadTime)) 



    #Open the second site
  
    Write-Output -InputObject ('Opening [{0}] in new internet explorer tab' -f ($siteurl))
  
    $navOpenInBackgroundTab = 65536
    $ie = $null
    $ie = (New-Object -ComObject 'Shell.Application').Windows() | Where-Object { $_.Name -eq 'Internet Explorer' }
    Start-sleep -milliseconds 100
  
    $ie.Navigate2($SiteUrl, $navOpenInBackgroundTab)
  
    $timeStart = Get-Date
    $timeout = $null
    $exitFlag = $false
    $elementMatch = $false
  
    do {
      Start-Sleep -milliseconds 500
      $ie3 = (New-Object -ComObject 'Shell.Application').Windows() | Where-Object { $_.Name -eq 'Internet Explorer' -and $_.LocationURL -match $SecondSiteURL}
      if ( $ie3.ReadyState -eq 4 ) {
      
        $elementText = $ie3.document.body.outerHTML
        $elementMatch = $elementText -match $SecondSiteelementMatchText
        if ( $elementMatch ) { $loadTime = (Get-Date).subtract($timeStart) }
      }
      Write-Output -InputObject ('Site [{1}] Readystate [{0}].' -f $ie2.ReadyState, $SecondSiteURL)
      $timeout = ((Get-Date).subtract($timeStart)).TotalMilliseconds -gt $timeoutMilliseconds
      $exitFlag = $elementMatch -or $timeout
    } until ( $exitFlag )

    #$elementText | out-file -FilePath $env:HOMEDRIVE\temp\metier.txt
    #(New-Object -ComObject 'Shell.Application').Windows() | out-file -FilePath $env:HOMEDRIVE\temp\comobjectdebug.txt
  
    Write-Output -InputObject ('Match element [{0}]' -f ($SecondSiteelementMatchText)) 
    Write-Output -InputObject ('Timeout [{0}]' -f ($timeout)) 
    Write-Output -InputObject ('Load Time [{0}]' -f ($loadTime)) 
	  
	  
    #cleanup IE
    Write-Output -InputObject 'Garbage procedure start'
    (New-Object -ComObject 'Shell.Application').Windows() | Where-Object {$_.Name -like '*Internet Explorer*' -and ($_.LocationURL -match $SecondSiteURL -or $_.LocationURL -match $FirstSiteURL )} | ForEach-Object {
      $_.Quit()
      [Runtime.Interopservices.Marshal]::ReleaseComObject($_)
    }
   

    [GC]::Collect()  
    [GC]::WaitForPendingFinalizers()
  
    Write-Output -InputObject 'Garbage procedure completed'
  
  
    #Add registry paths for the sites
  
    if (!(test-path -Path $RegistryPathIntranet)) {
      $Null = New-Item -Path $RegistryPathIntranet -force
    }
    
      if (!(Get-ItemPropertyValue -Path $RegistryPathIntranet -Name $Zone1)) {
      $Null = New-ItemProperty -Path $RegistryPathIntranet -Name $Zone1  -PropertyType String -Value 'True' -force
    }
    
      if (!(Get-ItemPropertyValue -Path $RegistryPathIntranet -Name $Zone2)) {
      $Null = New-ItemProperty -Path $RegistryPathIntranet -Name $Zone2  -PropertyType String -Value 'True' -force
    }
    
      if (!(Get-ItemPropertyValue -Path $RegistryPathIntranet -Name $Zone3)) {
      $Null = New-ItemProperty -Path $RegistryPathIntranet -Name $Zone3  -PropertyType String -Value 'True' -force   
    }
    
      if (!(Get-ItemPropertyValue -Path $RegistryPathIntranet -Name $Zone4)) {
      $Null = New-ItemProperty -Path $RegistryPathIntranet -Name $Zone4  -PropertyType String -Value 'True' -force  
    }
  }
  else
  {
    Write-Output -InputObject ('Intranet sites already opened in IE.')
  }
  #Map drive and get drive letter  
  
  $WebdavURl = $SiteURL -replace 'https://','\\' -replace '/','\' -replace '.com','.com@SSL\DavWWWRoot'
  $Psdrive = Get-PSDrive -name ($DriveLetter -replace ':','') -ErrorAction SilentlyContinue
  if ($Psdrive | where-object {$_.DisplayRoot -eq $WebdavURl} )
  {
    Write-Output -InputObject ('[{0}] is already mapped against driveletter [{1}]' -f $Siteurl, $DriveLetter)
  }
  elseif ($Psdrive) {
    Write-Output -InputObject ('Driveletter [{1}] is already mapped against [{1}] deleting driveletter befor mapping against correct site .' -f $Siteurl, $Psdrive.DisplayRoot)
    try{$del = & "$env:windir\system32\net.exe" USE $DriveLetter /DELETE /Y 2>&1}catch{$Null}
      if (Get-PSDrive -name ($DriveLetter -replace ':','')) {
         Write-error -Exception ('failed to delete drive [{0}]. Error [{1}] Exiting' -f $DriveLetter, $del) -ErrorAction Stop
      }
  }
  Else 
  {
    Write-Output -InputObject ('Mapping siteurl [{0}] against driveletter [{1}]' -f $Siteurl, $DriveLetter)   
    try{$out = & "$env:windir\system32\net.exe" USE $DriveLetter $siteUrl /PERSISTENT:YES 2>&1}catch{$Null}
    Write-Output -InputObject ('Last exitcode {0}' -f ($LASTEXITCODE)) 
    if($out -like '*error 67*'){
      Write-error -Exception "ERROR: detected string error 67 in return code of net use command, this usually means the WebClient isn't running"  -ErrorAction Stop
    }
    if($out -like '*error 224*'){
      Write-error -Exception 'ERROR: detected string error 224 in return code of net use command, this usually means your trusted sites are misconfigured or KB2846960 is missing'  -ErrorAction Stop
    }
    if($LASTEXITCODE -ne 0){ 
      Write-error -Exception ('Failed to map {0} to {1}, error: {2} {3}' -f ($DriveLetter), ($siteUrl), ($LASTEXITCODE), ($out))  -ErrorAction Stop 
    } 
    if([IO.Directory]::Exists($DriveLetter)){ 
      #set drive label 
      Write-Output -InputObject ("{0} mapped successfully`n" -f ($DriveLetter)) 
    }else{ 
      Write-error -Exception ('failed to contact {0} after mapping it to {1}, check if the URL is valid. Error: {2} {3}' -f ($DriveLetter), ($siteUrl), ($error[0]), $out) -ErrorAction Stop
    }
  }
    
  Write-Output -InputObject 'Setting Office regkeys'
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
	
  Write-Output -InputObject 'Completed, exiting.'
}
Catch {
  # Construct Message
  $ErrorMessage = 'Unable to map sharepoint drive.'
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
Finally
{
  Stop-Transcript
}
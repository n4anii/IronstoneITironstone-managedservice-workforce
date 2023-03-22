<#

    .SYNOPSIS
    Configures office 365 templates directory

    .DESCRIPTION
    Configures office 365 templates directory by setting internet explorer intranet zones, starting IE and browsing the correct zone, mapping a new network drive, then setting registry keys for office templates.

    .NOTES
    You need to run this script in the USER context in Intune.

    .Change history
    28.01.2018 - Initial relase

#>


#Transcript variables
$AppName = 'User_Set-Office365Templates_ict'
$Timestamp = Get-Date -Format 'HHmmssffff'
$LogDirectory = ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f $env:APPData)
$Transcriptname = ('{2}\{0}_{1}.txt' -f $AppName, $Timestamp, $LogDirectory)
$ErrorActionPreference = 'continue'

#Start transcript
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
        }
        else {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file ('{0}' -f $myInvocation.InvocationName) $args
        }
        exit $lastexitcode
    }

    #Variables
    #Driveletter to Map
    $DriveLetter = 'I:'
    #First webpage to load. This should be a small and light page. Must be loaded first, else we won't be able to load sharepoint sites correctly
    $FirstSiteURL = 'https://www.google.no'
    #Text element inside the first site to match against. this way, we know we have loaded the site correctly. 
    $FirstSiteelementMatchText = 'Google'
    #Name of the root Sharepoint site of the customer
    $TrustedSite = 'metiero365'
    #Second webpage to load. This is normally the customers sharepoint site where the office 365 templates are located
    $SharepointSite = 'metiero365.sharepoint.com/sites/MOICT/Delte%20dokumenter'
    #Text element inside the second site to match against. this way, we know we have loaded the site correctly.
    $SecondSiteelementMatchText = 'Documents'
   
    #Do not alter! 
    #URL to open for the second time
    $SecondSiteURL = ('https://{0}' -f $SharepointSite)
    #Sharepoint domains that must be added to intranet zones
    [array]$IntranetZones = ".sharepoint.com", "-files.sharepoint.com", "-my.sharepoint.com", "-myfiles.sharepoint.com"
    #Timeout on loading sites in IE
    $timeoutMilliseconds = 120000
    #Registry path used to store configuration settings preventing IE from starting unnecessary 
    $RegistryPathIntranet = 'HKCU:\SOFTWARE\IronstoneIT\Intune\DeviceConfiguration'
    #Office 365 registry paths. Used to set personaltemplates 
    [array]$RegistryPathsOffice = 'HKCU:\Software\Microsoft\Office\16.0\Excel\Options', 'HKCU:\Software\Microsoft\Office\16.0\Word\Options', 'HKCU:\Software\Microsoft\Office\16.0\PowerPoint\Options'
    #Comnputer registry path
    $ComputerRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains"

   
    #Foreach of the sharepoint intranet zones we have to set
    $BrowseSitesWithIE = $false
    foreach ($IntranetZone in $IntranetZones) {

        #Add the zone to registry if it's not present.
        $IntraNetZoneName = ('{0}{1}' -f $TrustedSite, $IntranetZone)
        $IntraNetZoneRegistryName = ('IntranetBrowsedWithIE_{0}' -f $IntraNetZoneName)        
        if (!(Test-Path -Path ('{0}\{1}' -f $RegistryPathIntranet, $IntraNetZoneRegistryName))) {
            Write-Output -InputObject ('Configuring IE Zone [{0}].' -f $IntraNetZoneName)
            
            [string]$PrimaryDomain = $IntranetZone.Split('.')[1..10] -join '.'
            [string]$SubDomain = $IntranetZone.Split('.')[0]
            $null = New-Item -Path "$ComputerRegPath" -ItemType File -Name "$PrimaryDomain" -ErrorAction SilentlyContinue
            $null = New-Item -Path "$ComputerRegPath\$PrimaryDomain" -ItemType File -Name "$TrustedSite$SubDomain" -ErrorAction SilentlyContinue
            $null = New-ItemProperty -Path "$ComputerRegPath\$PrimaryDomain\$TrustedSite$SubDomain" -Name "http" -Value 2 -ErrorAction SilentlyContinue
            $null = New-ItemProperty -Path "$ComputerRegPath\$PrimaryDomain\$TrustedSite$SubDomain" -Name "https" -Value 2 -ErrorAction SilentlyContinue 
            $BrowseSitesWithIE = $true 

        }
        else {
            Write-Output -InputObject ('IE Zone [{0}] already set.' -f $IntraNetZoneName)
        }

    }

    #If the sites have been loaded in IE before, skip to the adding driveletter part
    if ($BrowseSitesWithIE) {

        #Open first site using Start-Process, else the next tab will never load.
        #Just opening the sharepoint site does not work. It will just give a blank page while loading login.microsoft....
        Write-Output -InputObject ('Opening Internet explorer and navigating to [{0}].' -f $FirstSiteURL)
        Start-Process -FilePath 'iexplore.exe' -ArgumentList $FirstSiteURL

        #Wait for the page to actually load
        $timeStart = Get-Date
        $exitFlag = $false 
        do {
            Start-Sleep -milliseconds 500
            $ie2 = (New-Object -ComObject 'Shell.Application').Windows() | Where-Object { $_.Name -eq 'Internet Explorer' -and $_.LocationURL -match $FirstSiteURL }

            if ( $ie2.ReadyState -eq 4 ) {
                $elementText = $ie2.document.body.outerHTML
                $elementMatch = $elementText -match $FirstSiteelementMatchText
                if ( $elementMatch ) { 
                    $loadTime = (Get-Date).subtract($timeStart) 
                    Start-sleep -milliseconds 100
                    Write-Output -InputObject ('Site [{1}] Readystate [{0}] and element matched.' -f $ie2.ReadyState, $FirstSiteURL)
                }
                else {
                    Write-Output -InputObject ('Site [{1}] Readystate [{0}] but no element match.' -f $ie2.ReadyState, $FirstSiteURL)
                }
            } 
            else {
                Write-Output -InputObject ('Site [{1}] Readystate [{0}].' -f $ie2.ReadyState, $FirstSiteURL)
            }
     
            $timeout = ((Get-Date).subtract($timeStart)).TotalMilliseconds -gt $timeoutMilliseconds
            $exitFlag = $elementMatch -or $timeout
        } until ( $exitFlag )
        $elementText | out-file -FilePath $LogDirectory\google.txt
        Write-Output -InputObject ('Match element [{0}]' -f ($FirstSiteelementMatchText)) 
        Write-Output -InputObject ('Timeout [{0}]' -f ($timeout)) 
        Write-Output -InputObject ('Load Time [{0}]' -f ($loadTime))  



        #Open a new IE tab and navigate to the sharepoint templates site. 
        #This must be done using the comobject, else intranet sites won't work correctly.
  
        Write-Output -InputObject ('Opening [{0}] in new internet explorer tab' -f ($SecondSiteURL))

        $navOpenInBackgroundTab = 65536
        $ie = $null
        $ie = (New-Object -ComObject 'Shell.Application').Windows() | Where-Object { $_.Name -eq 'Internet Explorer' }
        Start-sleep -milliseconds 100
  
        $ie.Navigate2($SecondSiteURL, $navOpenInBackgroundTab)
  
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

                if ( $elementMatch ) { 
                    $loadTime = (Get-Date).subtract($timeStart) 
                    Start-sleep -milliseconds 100
                    Write-Output -InputObject ('Site [{1}] Readystate [{0}] and element matched.' -f $ie3.ReadyState, $SecondSiteURL)
                }
                else {
                    Write-Output -InputObject ('Site [{1}] Readystate [{0}] but no element match.' -f $ie3.ReadyState, $SecondSiteURL)
                }
            } 
            else {
                Write-Output -InputObject ('Site [{1}] Readystate [{0}].' -f $ie3.ReadyState, $SecondSiteURL)
            }

            $timeout = ((Get-Date).subtract($timeStart)).TotalMilliseconds -gt $timeoutMilliseconds
            $exitFlag = $elementMatch -or $timeout
        } until ( $exitFlag )
        $elementText | out-file -FilePath $LogDirectory\metier.txt
        Write-Output -InputObject ('Match element [{0}]' -f ($SecondSiteelementMatchText)) 
        Write-Output -InputObject ('Timeout [{0}]' -f ($timeout)) 
        Write-Output -InputObject ('Load Time [{0}]' -f ($loadTime)) 
	  
	  
        #cleanup the tabs we have opened, but do not close any other tabs
        Write-Output -InputObject 'Garbage procedure start'
        (New-Object -ComObject 'Shell.Application').Windows() | Where-Object {$_.Name -like '*Internet Explorer*' -and ($_.LocationURL -match $SecondSiteURL -or $_.LocationURL -match $FirstSiteURL )} | ForEach-Object {
            $_.Quit()
            [Runtime.Interopservices.Marshal]::ReleaseComObject($_)
        }
        [GC]::Collect()  
        [GC]::WaitForPendingFinalizers()
        Write-Output -InputObject 'Garbage procedure completed'
  
  
        #Add registry paths for the sites, so we don't have to reopen Ie in the future
        if (!(test-path -Path $RegistryPathIntranet)) {
            Write-Output -InputObject ('Creating registry key [{0}].' -f $RegistryPathIntranet)
            $Null = New-Item -Path $RegistryPathIntranet -force 
        }
        else {
            Write-Output -InputObject ('Registry key [{0}] already set.' -f $RegistryPathIntranet)
        }
    
        foreach ($IntranetZone in $IntranetZones) {
            $IntraNetZoneName = ('{0}{1}' -f $TrustedSite, $IntranetZone)
            $IntraNetZoneRegistryName = ('IntranetBrowsedWithIE_{0}' -f $IntraNetZoneName)
        
            if (!(Test-Path -Path ('{0}\{1}' -f $RegistryPathIntranet, $IntraNetZoneRegistryName))) {
                Write-Output -InputObject ('Creating registry key [{0}].' -f $IntraNetZoneRegistryName)
                $Null = New-Item -Path ('{0}\{1}' -f $RegistryPathIntranet, $IntraNetZoneRegistryName) -force
                
            }
            else {
                Write-Output -InputObject (' Registry key [{0}] already set.' -f $IntraNetZoneName)
            }
        }
    }
    else {
        Write-Output -InputObject ('Intranet sites already opened in IE.')
    }


    #Map drive and get drive letter  
    $WebdavURl = $SecondSiteURL -replace 'www.', '' -replace 'https://', '\\' -replace '/', '\' -replace '.com', '.com@SSL\DavWWWRoot'
    $Psdrive = Get-PSDrive -name ($DriveLetter -replace ':', '') -ErrorAction SilentlyContinue
    $MapDrive = $true
    if ($Psdrive.DisplayRoot -eq $WebdavURl) {
        Write-Output -InputObject ('[{0}] is already mapped against driveletter [{1}]' -f $SecondSiteURL, $DriveLetter)
        $MapDrive = $false
    }
    elseif ($Psdrive.DisplayRoot -ne $WebdavURl) {
        Write-Output -InputObject ('Driveletter [{1}] is already mapped against [{1}] deleting driveletter befor mapping against correct site .' -f $SecondSiteURL, $Psdrive.DisplayRoot)
        try {$del = & "$env:windir\system32\net.exe" USE $DriveLetter /DELETE /Y 2>&1}catch {$Null}
        $Drive = Get-PSDrive -name ($DriveLetter -replace ':', '') -ErrorAction SilentlyContinue
        if ($Drive) {
            Write-error -Exception ('failed to delete drive [{0}]. Error [{1}] Exiting' -f $DriveLetter, $del) -ErrorAction Stop
        }
        else {
            Write-Output -InputObject "Successfully deleted drive"
        }
    }
    if ($MapDrive) {
        Write-Output -InputObject ('Mapping siteurl [{0}] against driveletter [{1}]' -f $SecondSiteURL, $DriveLetter)   
        try {$out = & "$env:windir\system32\net.exe" USE $DriveLetter $SecondSiteURL /PERSISTENT:YES 2>&1}catch {$Null}
        Write-Output -InputObject ('Last exitcode {0}' -f ($LASTEXITCODE)) 
        if ($out -like '*error 67*') {
            Write-error -Exception "ERROR: detected string error 67 in return code of net use command, this usually means the WebClient isn't running"  -ErrorAction Stop
        }
        if ($out -like '*error 224*') {
            Write-error -Exception 'ERROR: detected string error 224 in return code of net use command, this usually means your trusted sites are misconfigured or KB2846960 is missing'  -ErrorAction Stop
        }
        if ($LASTEXITCODE -ne 0) { 
            Write-error -Exception ('Failed to map {0} to {1}, error: {2} {3}' -f ($DriveLetter), ($SecondSiteURL), ($LASTEXITCODE), ($out))  -ErrorAction Stop 
        } 
        if ([IO.Directory]::Exists($DriveLetter)) { 
            #set drive label 
            Write-Output -InputObject ("{0} mapped successfully`n" -f ($DriveLetter)) 
        }
        else { 
            Write-error -Exception ('failed to contact {0} after mapping it to {1}, check if the URL is valid. Error: {2} {3}' -f ($DriveLetter), ($SecondSiteURL), ($error[0]), $out) -ErrorAction Stop
        }
    }
    

    #Add the office 365 registry keys to set personaltemplates
    foreach ($RegistryPathOffice in $RegistryPathsOffice) {
        if (!(Test-path -Path $RegistryPathOffice)) {
            $null = New-Item -Path $RegistryPathOffice -Force
            Write-Output -InputObject ('Setting registry key [{0}].' -f $RegistryPathOffice)
            $null = New-ItemProperty -Path $RegistryPathOffice -Name 'PersonalTemplates' -Value $DriveLetter -PropertyType Expandstring -Force
            Write-Output -InputObject ('Setting registry key [{0}] item property [Personaltemplates] to [{1}] .' -f $RegistryPathOffice, $DriveLetter )
        }
        ELSE {
            $null = New-ItemProperty -Path $RegistryPathOffice -Name 'PersonalTemplates' -Value $DriveLetter -PropertyType Expandstring -Force
            Write-Output -InputObject ('Setting registry key [{0}] item property [Personaltemplates] to [{1}] .' -f $RegistryPathOffice, $DriveLetter)
        }
    }
	
    Write-Output -InputObject 'Completed successfully.'
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
Finally {
    Stop-Transcript
}
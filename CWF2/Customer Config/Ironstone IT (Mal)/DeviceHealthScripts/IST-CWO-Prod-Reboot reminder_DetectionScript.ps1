$boottime = Get-CimInstance Win32_OperatingSystem | Select-Object LastBootUpTime
$time = Get-Date
$uptime = ($time - $boottime.LastBootUpTime).TotalDays

if ($uptime -gt 7) {
    #make sure assemblies are loaded
    $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
    $null = [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime]

    <# Base 64 encoding

    #Convert from file to Base64
    $Filepath = 'C:\temp\IRONSTONE_RGB-white-logoonly.png'
    $Base64_Code = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($Filepath));
    $Base64_Code | out-file c:\temp\string2.txt #Stringy thingy
    #>

    #Get fullname of logged in user
    $DisplayNAme = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\ -name LastLoggedOnDisplayName).LastLoggedOnDisplayName
    #Set companyname
    $CompanyName = 'Ironstone IT'
    #Set header
    $Header = "{0} days uptime" -f ([int]$uptime)

    #Base64 encoded placemnent logo
    $Base64placementLogo = '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'

    ## Convert from Base64 images to local files

    #Save placemnent image to temp folder
    $Base64placementImage_Path = "$env:TEMP\Base64placementLogo.png"
    # Convert ServiceUI from Base64 to EXE
    [byte[]]$Bytes = [convert]::FromBase64String($Base64placementLogo)
    [System.IO.File]::WriteAllBytes($Base64placementImage_Path, $Bytes)

    [xml]$Toast = @"
<toast scenario="reminder">
    <visual>
        <binding template="ToastGeneric">
            <image id="1" placement="appLogoOverride" hint-crop="circle" src="file:///$Base64placementImage_Path" />
            <text placement="attribution">$CompanyName</text>
            <Signature>Sent on behalf of the Ironstone IT Service Desk</Signature>
            <text>Hi $DisplayNAme</text>
            <group>
                <subgroup>
                    <text hint-style="title" hint-wrap="true">$Header</text>
                </subgroup>
            </group>
            <group>
                <subgroup>
                    <text hint-style="body" hint-wrap="true">We have detected that it's more than a week since you last rebooted your computer</text>
                </subgroup>
            </group>
            <group>
                <subgroup>
                    <text hint-style="body" hint-wrap="true">We recomend rebooting the computer at least once a week</text>
                </subgroup>
            </group>

        </binding>
    </visual>
    <actions>
        <action activationType="protocol" arguments="https://support.ironstoneit.com/a/solutions/articles/51000027447?language=en" content="Learn more" />
        <action activationType="system" arguments="dismiss" content="Dismiss" />
    </actions>
</toast>
"@

    #[System.Reflection.Assembly]::LoadWithPartialName('Windows.Data.Xml.Dom')
    $ToastXml = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
    $ToastXml.LoadXml($Toast.OuterXml)

    # Display the toast notification
    $LauncherID = 'MSEdge'
    #$LauncherID = "Microsoft.SoftwareCenter.DesktopToasts"
    #$LauncherID = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($LauncherID).Show($ToastXml)
    Exit 1
}
Exit 0
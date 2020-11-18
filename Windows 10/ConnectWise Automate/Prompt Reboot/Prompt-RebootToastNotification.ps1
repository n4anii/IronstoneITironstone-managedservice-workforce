#Requires -Version 5.1 -RunAsAdministrator 

<#
    Display Toast Notifications on Windows 10 1709 and newer

    .RESOURCES
        Microsoft Docs | "The toast template catalog (Windows Runtime apps)"
            https://docs.microsoft.com/en-us/previous-versions/windows/apps/hh761494(v=win.10)

        Microsoft Docs | Toash schema \ Image
            https://docs.microsoft.com/en-us/uwp/schemas/tiles/toastschema/element-image

        Burnt Toast
            https://github.com/Windos/BurntToast

        "PowerShell can I use balloons, toasts and notifications?"
            https://deploywindows.com/2015/12/01/powershell-can-i-use-balloons-toasts-and-notifications/
        1709
            https://gist.github.com/Windos/9aa6a684ac583e0d38a8fa68196bc2dc
            https://stackoverflow.com/questions/46814858/toast-notification-not-working-on-windows-fall-creators-update/46817674#46817674
        Pre 1709
            https://gist.github.com/altrive/72594b8427b2fff16431
            http://www.systanddeploy.com/2017/02/display-windows-10-notifications-with.html

    .USEFUL
        Get all AppIDs
            Get-StartApps | Sort-Object -Property Name
#>


#region    AddIDs
    $App = 'Microsoft.CompanyPortal_8wekyb3d8bbwe!App'
#endregion AppIDs



#region    Registry
    # Get current user
    [string] $CurrentUser         = (Get-Process -Name 'explorer' -IncludeUserName).UserName
    [string] $CurrentUserName     = $CurrentUser.Split('\')[-1]
    [string] $CurrentUserRegValue = (New-Object -TypeName System.Security.Principal.NTAccount($CurrentUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

    # Set PS Drive
    If ((Get-PSDrive -Name 'HKU' -ErrorAction SilentlyContinue) -eq $null) {
        $null = New-PSDrive -PSProvider Registry -Name 'HKU' -Root 'HKEY_USERS'
    }

    # Variables
    [string] $PathDirReg   = ('HKU:\{0}\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\{1}\' -f ($CurrentUserRegValue,$App))
    [string] $NameValueReg = 'ShowInActionCenter'
    [byte]   $ValueReg     = 1

    # Create Path if it doesn't exist
    If (-not(Test-Path -Path $PathDirReg)) {
        $null = New-Item -Path $PathDirReg -ItemType 'Directory' -Force
    }
    # Else, get the existing value
    Else {
        $CurrentValue = Get-ItemProperty -Path $PathDirReg -Name $NameValueReg -ErrorAction SilentlyContinue
    }

    # Write new value if it does not exist, or if it's not equal to $ValueReg
    If (-not($CurrentValue -and $CurrentValue.$NameValueReg -eq $ValueReg)) {
        Set-ItemProperty -Path $PathDirReg -Name $NameValueReg -Value $ValueReg -Type 'DWord' -Force
    }
#endregion Registry




#region    Toast Notification
$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]

$Template = [Windows.UI.Notifications.ToastTemplateType]::ToastText02

#Gets the Template XML so we can manipulate the values
[xml] $ToastTemplate = ([Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent($Template).GetXml())

[xml] $ToastTemplate = (@'
<toast launch="app-defined-string">
    <visual>
        <binding template="ToastText02">
            <text id="1">Reboot Required</text>
            <text id="2">Your computer will reboot in 90 minutes, unless you reboot manually. Please save you work.</text>
        </binding>
    </visual>
    <actions>
        <action activationType="background" content="OK" arguments="OK"/>
    </actions>
</toast>
'@)



$ToastXml = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
$ToastXml.LoadXml($ToastTemplate.OuterXml)

$Notify = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($App)
$Notify.Show($ToastXml)
#endregion Toast Notification
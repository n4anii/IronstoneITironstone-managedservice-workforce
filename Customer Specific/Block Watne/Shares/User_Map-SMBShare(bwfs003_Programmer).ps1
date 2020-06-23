<#
    .SYNAPSIS
        Maps shares (SMB) to Windows 10 by providing a self driven process for the user triggered by a shortcut.
    
    .NOTES
        Author:           Jos Lieben (OGD)
        Author Company:   OGD (http://www.ogd.nl)
        Author Blog:      http://www.lieben.nu
        Date:             05-06-2018
        Purpose:          Configurable drivemapping to server shares with automatic querying for credentials
#>


### Settings - Share
$ShareLetter             = [string]$('P') # Change to desired driveletter (don't use double colon : )
$SharePath               = [string]$('\\bwfs003\Prog') # Change to desired server / share path
$shortCutTitle           = [string]$('Koble til ``Programmer´´') #this will be the name of the shortcut
$DesiredShortcutLocation = [string]$('{0}\Koble til fellesdisker' -f ([Environment]::GetFolderPath('Desktop'))) # You can also use MyDocuments or any other valid input for the GetFolderPath function

### Settings - Script behaviour
$AutosuggestLogin        = [bool]$($true) # Automatically prefills the login field of the auth popup with the user's O365 email (azure ad join)
$PersistantStorage       = [bool]$($true) # Persistant storage means Windows will remember the Share through reboots.

### Settings - Script location
$DesiredMapScriptFolder  = [string]$('{0}\IronstoneIT\Intune\Scripts\SMB' -f ($env:LOCALAPPDATA))
$DesiredMapScriptPath    = [string]$('{0}\SMBdriveMapper({1}).ps1' -f ($DesiredMapScriptFolder,$SharePath.Replace('\\','').Replace('$','').Replace('\','_')))

### Create required paths
[string[]]$($DesiredShortcutLocation,$DesiredMapScriptFolder) | ForEach-Object -Process {
    if (-not[System.IO.Directory]::Exists($_)) {
        $null = New-Item -Path $_ -Type 'Directory' -Force
    }
}

### Create script file
$ScriptContent = "
Param(
    `$driveLetter,
    `$sourcePath
)

`$driveLetter = `$driveLetter.SubString(0,1)

`$desiredMapScriptFolder = [string]`$('{0}\IronstoneIT\Intune\Scripts\SMB' -f (`$env:LOCALAPPDATA))

Start-Transcript -Path (Join-Path `$desiredMapScriptFolder -ChildPath `"SMBdriveMapper.log`") -Force
"
if($AutosuggestLogin){
    $ScriptContent+= "
try{
    `$objUser = New-Object System.Security.Principal.NTAccount(`$Env:USERNAME)
    `$strSID = (`$objUser.Translate([System.Security.Principal.SecurityIdentifier])).Value
    `$basePath = `"Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IdentityStore\Cache\`$strSID\IdentityCache\`$strSID`"
    if((test-path `$basePath) -eq `$False){
        `$userId = `$Null
    }
    `$userId = (Get-ItemProperty -Path `$basePath -Name UserName).UserName
    Write-Output `"Detected user id: `$userId`"
}catch{
    Write-Output `"Failed to auto detect user id, will query`" 
    `$Null
}
"
}else{
    $ScriptContent+= "
`$userId = `$null
    "
}

$ScriptContent+= "
`$serverPath = `"`$(([URI]`$sourcePath).Host)`"
#check if other mappings share the same path, in that case we shouldn't need credentials
`$authRequired = `$true
try{
     `$count = @(get-psdrive -PSProvider filesystem | where-object {`$_.DisplayRoot -and `$_.DisplayRoot.Replace('\','').StartsWith(`$serverPath)}).Count
}catch{`$Null}

if(`$count -gt 0){
    Write-Output `"A drivemapping to this server already exists, so authentication should not be required`"
    `$authRequired = `$False
}

[void] [System.Reflection.Assembly]::LoadWithPartialName(`"System.Drawing`") 
[void] [System.Reflection.Assembly]::LoadWithPartialName(`"System.Windows.Forms`")

if(`$authRequired){
    `$form = New-Object System.Windows.Forms.Form
    `$form.Text = `"Connect to `$driveLetter drive`"
    `$form.Size = New-Object System.Drawing.Size(300,200)
    `$form.StartPosition = 'CenterScreen'
    `$form.MinimizeBox = `$False
    `$form.MaximizeBox = `$False

    `$OKButton = New-Object System.Windows.Forms.Button
    `$OKButton.Location = New-Object System.Drawing.Point(75,120)
    `$OKButton.Size = New-Object System.Drawing.Size(75,23)
    `$OKButton.Text = 'OK'
    `$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    `$form.AcceptButton = `$OKButton
    `$form.Controls.Add(`$OKButton)

    `$CancelButton = New-Object System.Windows.Forms.Button
    `$CancelButton.Location = New-Object System.Drawing.Point(150,120)
    `$CancelButton.Size = New-Object System.Drawing.Size(75,23)
    `$CancelButton.Text = 'Cancel'
    `$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    `$form.CancelButton = `$CancelButton
    `$form.Controls.Add(`$CancelButton)

    `$label = New-Object System.Windows.Forms.Label
    `$label.Location = New-Object System.Drawing.Point(10,20)
    `$label.Size = New-Object System.Drawing.Size(280,20)
    `$label.Text = `"Username for `$driveLetter drive`"
    `$form.Controls.Add(`$label)

    `$textBox = New-Object System.Windows.Forms.TextBox
    `$textBox.Location = New-Object System.Drawing.Point(10,40)
    `$textBox.Size = New-Object System.Drawing.Size(260,20)
    `$textBox.Text = `$userId
    `$form.Controls.Add(`$textBox)

    `$label2 = New-Object System.Windows.Forms.Label
    `$label2.Location = New-Object System.Drawing.Point(10,60)
    `$label2.Size = New-Object System.Drawing.Size(280,20)
    `$label2.Text = 'Password:'
    `$form.Controls.Add(`$label2)

    `$textBox2 = New-Object System.Windows.Forms.MaskedTextBox
    `$textBox2.PasswordChar = '*'
    `$textBox2.Location = New-Object System.Drawing.Point(10,80)
    `$textBox2.Size = New-Object System.Drawing.Size(260,20)
    `$form.Controls.Add(`$textBox2)

    `$form.Topmost = `$true

    `$form.Add_Shown({`$textBox.Select()})
    `$result = `$form.ShowDialog()

    if (`$result -eq [System.Windows.Forms.DialogResult]::OK -and `$textBox2.Text.Length -gt 5 -and `$textBox.Text.Length -gt 4)
    {
        `$secpasswd = ConvertTo-SecureString `$textBox2.Text -AsPlainText -Force
        `$credentials = New-Object System.Management.Automation.PSCredential (`$textBox.Text, `$secpasswd)
    }else{
        `$OUTPUT= [System.Windows.Forms.MessageBox]::Show(`"`$driveLetter will not be available, as you did not enter credentials`", `"`$driveLetter error`" , 0) 
        Stop-Transcript
        Exit
    }
}
try{`Remove-PSDrive -Name `$driveLetter -Force}catch{`$Null}

try{
    if(`$authRequired){
        New-PSDrive -Name `$driveLetter -PSProvider FileSystem -Root `$sourcePath -Credential `$credentials -Persist:$(if($PersistantStorage){'$true'}else{'$false'}) -ErrorAction Stop
    }else{
        Throw
    }
}catch{
    try{
        New-PSDrive -Name `$driveLetter -PSProvider FileSystem -Root `$sourcePath -Persist:$(if($PersistantStorage){'$true'}else{'$false'}) -ErrorAction Stop
    }catch{
         `$OUTPUT= [System.Windows.Forms.MessageBox]::Show(`"Connection failed, technical reason: `$(`$Error[0])`", `"`$driveLetter error`" , 0) 
    }
}
Stop-Transcript
"

# Output script file
$null = $ScriptContent | Out-File -FilePath $DesiredMapScriptPath -Encoding 'utf8' -Force

# Create shortcut
$ShareLetter                 = $ShareLetter.SubString(0,1)
$WshShell                    = New-Object -ComObject 'WScript.Shell'
$Shortcut                    = $WshShell.CreateShortcut([string]$('{0}\{1}.lnk' -f ($DesiredShortcutLocation,$ShortCutTitle)))
$Shortcut.'TargetPath'       = [string]$('powershell.exe')
$Shortcut.'WorkingDirectory' = [string]$('%SystemRoot%\WindowsPowerShell\v1.0')
$Shortcut.'Arguments'        = [string]$('-WindowStyle Hidden -ExecutionPolicy ByPass -File "{0}" "{1}" "{2}"' -f ($DesiredMapScriptPath,$ShareLetter,$SharePath))
$Shortcut.'IconLocation'     = [string]$('explorer.exe ,0')
$shortcut.'WindowStyle'      = 7
$Shortcut.Save()
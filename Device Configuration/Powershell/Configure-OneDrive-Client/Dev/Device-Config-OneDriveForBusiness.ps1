#region    Settings
$ErrorActionPreference = 'Continue'
$VerbosePreference = 'Continue'
$WarningPreference = 'Continue'
#endregion Settings



#region    Get Current User
    # Get current user
    [string] $CurrentUser         = (Get-Process -Name 'explorer' -IncludeUserName).UserName
    [string] $CurrentUserName     = $CurrentUser.Split('\')[-1]
    [string] $CurrentUserRegValue = (New-Object -TypeName System.Security.Principal.NTAccount($CurrentUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
    [string] $PathDirReg          = ('HKU:\{0}\' -f ($CurrentUserRegValue))

    # Set PS Drive
    If ((Get-PSDrive -Name 'HKU' -ErrorAction SilentlyContinue) -eq $null) {
        New-PSDrive -PSProvider Registry -Name 'HKU' -Root HKEY_USERS
    }
#endregion Get Current User



#region    Registry Variables
[PSCustomObject[]] $RegValues = @(
    [PSCustomObject]@{Dir=[string]'HKCU:\SOFTWARE\Microsoft\OneDrive';          Key=[string]'EnableADAL';           Val=[byte]1; Type=[string]'DWord'},
    [PSCustomObject]@{Dir=[string]'HKLM:\Software\Policies\Microsoft\OneDrive'; Key=[string]'FilesOnDemandEnabled'; Val=[byte]1; Type=[string]'DWord'},
    [PSCustomObject]@{Dir=[string]'HKLM:\Software\Policies\Microsoft\OneDrive'; Key=[string]'SilentAccountConfig';  Val=[byte]1; Type=[string]'DWord'}
)
#endregion Registry Variables



#region    Set Registry Values
foreach ($Item in $RegValues) {
    [string] $TempPath = $Item.Dir
    if ($TempPath -like 'HKCU:\*') {
        $TempPath = $TempPath.Replace('HKCU:\',$PathDirReg)
    }
    Write-Verbose -Message ('{0}' -f ($TempPath))
    Write-Verbose -Message ('   Key: {0} | Value: {1} | Type: {2}' -f ($Item.Key,$Item.Val,$Item.Type))
    Set-ItemProperty -Path $Item.Dir -Name $Item.Key -Value $Item.Val -Type $Item.Type -Force
    Write-Verbose -Message ('   Success? {0}' -f ($?))
}
#endregion Set Registry Values
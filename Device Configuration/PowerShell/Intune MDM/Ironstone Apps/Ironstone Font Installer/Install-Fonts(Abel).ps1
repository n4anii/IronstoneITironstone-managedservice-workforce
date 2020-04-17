# Assets
$PathFontDir   = [string]$('{0}\Fonts' -f ($env:windir))
$PathRegDir    = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts')
$NameFileFonts = [PSCustomObject[]]$(
    [PSCustomObject]@{'Name'='Abel (TrueType)';           'FileName'='Abel-Regular.ttf'}
)


# Install
foreach ($Font in $NameFileFonts) {
    # Set Registry Value
    $null = Set-ItemProperty -Path $PathRegDir -Name $Font.'Name' -Value $Font.'FileName' -Type 'String' -Force -ErrorAction 'Stop'
}
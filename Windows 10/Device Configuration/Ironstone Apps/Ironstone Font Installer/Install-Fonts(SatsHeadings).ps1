# Assets
$PathFontDir   = [string]$('{0}\Fonts' -f ($env:windir))
$PathRegDir    = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts')
$NameFileFonts = [PSCustomObject[]]$(
    [PSCustomObject]@{'Name'='SATS Headline Bold (TrueType)';           'FileName'='SATSHeadline-Bold.otf'},
    [PSCustomObject]@{'Name'='SATS Headline Bold Italic (TrueType)';    'FileName'='SATSHeadline-BoldItalic.otf'},
    [PSCustomObject]@{'Name'='SATS Headline Italic (TrueType)';         'FileName'='SATSHeadline-RegularItalic.otf'},
    [PSCustomObject]@{'Name'='SATS Headline SemiBold Italic (TrueType)';'FileName'='SATSHeadline-SemiBoldItalic.otf'}
)


# Install
foreach ($Font in $NameFileFonts) {
    # Set Registry Value
    $null = Set-ItemProperty -Path $PathRegDir -Name $Font.'Name' -Value $Font.'FileName' -Type 'String' -Force -ErrorAction 'Stop'
}
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


# Uninstall
foreach ($Font in $NameFileFonts) {
    # Remove File
    $FilePath = [string]$('{0}\{1}' -f ($PathFontDir,$Font.'FileName'))
    if (Test-Path -Path $FilePath) {
        $null = Remove-Item -Path $FilePath -Force -ErrorAction 'Stop'
    }

    # Remove Registry Entry
    if ([bool]$($x = Get-ItemProperty -Path $PathRegDir -Name $Font.'Name' -ErrorAction 'SilentlyContinue';$?)){
        $null = Remove-ItemProperty -Path $PathRegDir -Name $Font.'Name' -Force -ErrorAction 'Stop'
    }
}
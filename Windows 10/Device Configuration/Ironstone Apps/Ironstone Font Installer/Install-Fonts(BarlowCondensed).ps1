# Assets
$PathFontDir   = [string]$('{0}\Fonts' -f ($env:windir))
$PathRegDir    = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts')
$NameFileFonts = [PSCustomObject[]]$(
    [PSCustomObject]@{'Name'='Barlow Condensed Black (TrueType)';             'FileName'='BarlowCondensed-Black.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed Black Italic (TrueType)';      'FileName'='BarlowCondensed-BlackItalic.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed Bold (TrueType)';              'FileName'='BarlowCondensed-Bold.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed Bold Italic (TrueType)';       'FileName'='BarlowCondensed-BoldItalic.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed Extra Bold (TrueType)';        'FileName'='BarlowCondensed-ExtraBold.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed Extra Bold Italic (TrueType)'; 'FileName'='BarlowCondensed-ExtraBoldItalic.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed Extra Light (TrueType)';       'FileName'='BarlowCondensed-ExtraLight.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed Extra Light Italic (TrueType)';'FileName'='BarlowCondensed-ExtraLightItalic.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed Italic (TrueType)';            'FileName'='BarlowCondensed-Italic.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed Light (TrueType)';             'FileName'='BarlowCondensed-Light.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed Light Italic (TrueType)';      'FileName'='BarlowCondensed-LightItalic.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed Medium (TrueType)';            'FileName'='BarlowCondensed-Medium.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed Medium Italic (TrueType)';     'FileName'='BarlowCondensed-MediumItalic.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed (TrueType)';                   'FileName'='BarlowCondensed-Regular.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed SemiBold (TrueType)';          'FileName'='BarlowCondensed-SemiBold.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed SemiBold Italic (TrueType)';   'FileName'='BarlowCondensed-SemiBoldItalic.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed Thin (TrueType)';              'FileName'='BarlowCondensed-Thin.ttf'},
    [PSCustomObject]@{'Name'='Barlow Condensed Thin Italic (TrueType)';       'FileName'='BarlowCondensed-ThinItalic.ttf'}
)


# Install
foreach ($Font in $NameFileFonts) {
    # Set Registry Value
    $null = Set-ItemProperty -Path $PathRegDir -Name $Font.'Name' -Value $Font.'FileName' -Type 'String' -Force -ErrorAction 'Stop'
}
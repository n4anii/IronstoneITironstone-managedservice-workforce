# Assets
$PathFontDir   = [string]$('{0}\Fonts' -f ($env:windir))
$PathRegDir    = [string]$('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts')
$NameFileFonts = [PSCustomObject[]]$(
    [PSCustomObject]@{'Name'='Industry Black (TrueType)';          'FileName'='Industry Black.ttf'},
    [PSCustomObject]@{'Name'='Industry Black Italic (TrueType)';   'FileName'='Industry Black Italic.ttf'},    
    [PSCustomObject]@{'Name'='Industry Bold (TrueType)';           'FileName'='Industry Bold.ttf'},
    [PSCustomObject]@{'Name'='Industry Bold Italic (TrueType)';    'FileName'='Industry Bold Italic.ttf'},   
    [PSCustomObject]@{'Name'='Industry Book (TrueType)';           'FileName'='Industry Book.ttf'},
    [PSCustomObject]@{'Name'='Industry Book Italic (TrueType)';    'FileName'='Industry Book Italic.ttf'}, 
    [PSCustomObject]@{'Name'='Industry Demi (TrueType)';           'FileName'='Industry Demi.ttf'},
    [PSCustomObject]@{'Name'='Industry Demi Italic (TrueType)';    'FileName'='Industry Demi Italic.ttf'}
)


# Install
foreach ($Font in $NameFileFonts) {
    # Set Registry Value
    $null = Set-ItemProperty -Path $PathRegDir -Name $Font.'Name' -Value $Font.'FileName' -Type 'String' -Force -ErrorAction 'Stop'
}
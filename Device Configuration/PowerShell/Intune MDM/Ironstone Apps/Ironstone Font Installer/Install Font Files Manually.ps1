# Assets - Variable
$Path  = [string]$('C:\Users\OlavRønnestadBirkela\Ironstone\Ironstone Norway - Customer - Sats Elixia - Documents\BPTW\Fonts\SATS Headline')

# Assets - Static
$PathInstall = [string]$('{0}\Fonts' -f ($env:windir))
$ValidFontExtensions = [string[]]$('fon','otf','ttc','ttf')

# Get Font Files
$Fonts = [string[]]$(Get-ChildItem -Path $Path -Recurse:$false -File -Force -ErrorAction 'Stop' | `
    Select-Object -ExpandProperty 'FullName' | `
    Where-Object -FilterScript {$ValidFontExtensions -contains $_.Split('.')[-1]} | `
    Sort-Object -Descending:$false
)


# Install Font Files
foreach ($Font in $Fonts) {
    $null = Copy-Item -Path $Font -Destination ('{0}\{1}' -f ($PathInstall,$Font.Split('\')[-1])) -Force -ErrorAction 'Stop'
}
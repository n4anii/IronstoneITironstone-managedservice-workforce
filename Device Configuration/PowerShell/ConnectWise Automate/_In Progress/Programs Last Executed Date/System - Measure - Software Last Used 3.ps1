$PathDirPrefetch = ('{0}\Prefetch' -f ($env:windir))

$ItemsPrefetch = @(Get-ChildItem -Path $PathDirPrefetch -File -Recurse:$false | Where-Object -Property Name -Like '*.EXE*' | Select-Object -Property * | Sort-Object -Property Name)

foreach ($Item in $ItemsPrefetch) {
    $NameCurrentItem = $Item.Name.Split('-')[0]

}


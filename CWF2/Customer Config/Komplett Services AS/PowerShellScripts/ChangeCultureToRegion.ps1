function Get-RegionInfo($pGeoID)
{
    $cultures = [System.Globalization.CultureInfo]::GetCultures('InstalledWin32Cultures')
 
    foreach($culture in $cultures)
    {
       try{
           $region = [System.Globalization.RegionInfo]$culture.Name
 
           #if($region.DisplayName -like $Name)
           if($region.GeoId -eq $pGeoID)
           {
                $region
                break
           }
       }
       catch {}
    }
}

$CountryGeoID = Get-RegionInfo (Get-WinHomeLocation).GeoID
$prefix = $CountryGeoID.Name
Set-Culture $prefix
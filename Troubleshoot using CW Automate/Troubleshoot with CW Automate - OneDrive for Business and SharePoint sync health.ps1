$Users = [PSCustomObject[]](
    (Get-ChildItem -Path ('{0}\Users'-f$env:SystemDrive) -Depth 0 -Directory).Where{
        $_.'Name' -notin 'defaultuser0','Public'
    }.ForEach{
        [PSCustomObject]@{
            'Username' = $_.'Name'
            'OD4BPath' = '{0}\AppData\Local\Microsoft\OneDrive\settings\Business1'-f$_.'FullName'
        }
    }.Where{
        [System.IO.Directory]::Exists($_.'OD4BPath')
    }
)

foreach ($User in $Users) {
    Write-Output -InputObject ('# {0}'-f$User.'Username')
    # Find INI files
    $IniFiles = [array](Get-ChildItem -Path $User.'OD4BPath' -Filter 'ClientPolicy*' -ErrorAction 'SilentlyContinue')
    if (-not $IniFiles) {
        Write-Output -InputObject 'No Onedrive configuration files found.'
    }
    else {
        # Gather info from INI files
        $SyncedLibraries = [PSCustomObject[]]$(
            foreach ($IniFile in $IniFiles) {
                $IniContent = Get-Content -Path $IniFile.'FullName' -Encoding 'Unicode'
                [PSCustomObject]@{
                    'ItemCount' = ($IniContent.Where{$_ -like 'ItemCount*'}) -split '= ' | Select-Object -Last 1
                    'SiteName'  = ($IniContent.Where{$_ -like 'SiteTitle*'}) -split '= ' | Select-Object -Last 1
                    'SiteURL'   = ($IniContent.Where{$_ -like 'DavUrlNamespace*'}) -split '= ' | Select-Object -Last 1
                }
            }
        )

        # Output info
        ## All
        $SyncedLibraries | Format-Table -Property 'ItemCount','SiteName' -AutoSize
        ## Total
        Write-Output -InputObject ('Total synced objects: {0}. 280k is absolute max recommended objects to sync.'-f($SyncedLibraries.'ItemCount' | Measure-Object -Sum).'Sum'.ToString('N0'))
    }
}

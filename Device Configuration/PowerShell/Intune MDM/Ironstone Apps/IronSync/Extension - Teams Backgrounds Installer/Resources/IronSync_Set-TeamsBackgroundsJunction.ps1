<#
    What works
        Directory junction

    What does not work
        Folders inside "Uploads" folder

#>



# Directory Junction Link
## Assets
$From = [string]('{0}\Microsoft\Teams\Backgrounds\Uploads' -f ($env:APPDATA))
$To   = [string]('{0}\Templates\Teams backgrounds' -f ($env:PUBLIC))

## Create
$null = New-Item -ItemType 'Junction' -Path $From -Target $To -Force


#region    Copy Files
    # Assets
    ## Static
    $Source      = [string]('{0}\OfficeTemplates' -f ($env:PUBLIC))
    $Destination = [string]('{0}\Microsoft\Teams\Backgrounds\Uploads' -f ($env:APPDATA))
    $Include     = [string[]]('*.jpeg','*.jpg','*.png')

    ## Dynamic - Look for a dedicated teams background folder
    if ([System.IO.Directory]::Exists($Source)) {
        $TeamsFolders = [array](Get-ChildItem -Path $Source -Directory -Filter '*teams*' -Depth 0)
        if ($TeamsFolders.'Count' -eq 1 -and $([array](Get-ChildItem -Path ('{0}\*'-f$TeamsFolders[0].'FullName') -Include $Include -Recurse -Force)).'Count' -gt 0) {
            $Source = $TeamsFolders[0].'FullName'
        }
    }

    # Copy files
    if ([System.IO.Directory]::Exists($Source)) {
        # Create $To if not exist
        if (-not [System.IO.Directory]::Exists($Destination)) {        
            $null = New-Item -Path $Destination -ItemType 'Directory' -Force
        }

        # Get list of files from
        $FromFiles = [array](Get-ChildItem -Path ('{0}\*'-f$Source) -Include $Include -Recurse -Force)

        # Compare with $To, copy over if not exist or modified date or size is different
        foreach ($FromFile in $FromFiles) {
            # Assets
            $ToPath = [string]('{0}\{1}' -f ($Destination,$FromFile.'Name'))
            $ToFile = [System.IO.FileInfo]$(
                if ([System.IO.File]::Exists($ToPath)) {
                    Get-Item -Path $ToPath
                }
                else {
                    [System.IO.FileInfo]::new($ToPath)
                }
            )
        
            # Copy item if:
            if (
                # File does not exist, or
                [System.IO.File]::Exists($DestinationPath) -or
                # File sizes are different, or
                $FromFile.'Length' -ne $ToFile.'Length' -or
                # Last Write Time is different
                $FromFile.'LastWriteTime' -ne $ToFile.'LastWriteTime'
            ) {
                Write-Output -InputObject ('Copying "{0}" to "{1}".' -f ($FromFile.'FullName',$ToFile.'FullName'))
                $null = Copy-Item -Path $FromFile.'FullName' -Destination $ToFile.'FullName' -Force
            }
        }
    }


    # Check
    $ErrorActionPreference = 'Stop'
    [bool]$(
        # If Source and Destination folders exist
        if ($([string[]]($Source,$Destination)).ForEach{[System.IO.Directory]::Exists($_)} -notcontains $false) {
            [bool]$(
                $FromFiles = [array](Get-ChildItem -Path ('{0}\*'-f$Source) -Include $Include -Recurse)
                # For each $FromFiles
                [bool[]]$(
                    foreach ($FromFile in $FromFiles) {
                        Try {
                            # Get info on $ToFile
                            $ToFile = Get-Item -Path ('{0}\{1}' -f ($Destination,$FromFile.'Name'))
                            # Check
                            [bool](
                                ## File does not exist, or
                                [System.IO.File]::Exists($DestinationPath) -or
                                ## File sizes are different, or
                                $FromFile.'Length' -ne $ToFile.'Length' -or
                                ## Last Write Time is different
                                $FromFile.'LastWriteTime' -ne $ToFile.'LastWriteTime'
                            )
                        }
                        Catch {
                            [bool] $false
                        }
                    }
                ) -notcontains $false
            )
        }
        # Else, if Source and Destination folders does not exist
        else {
            [bool] $false
        }
    )
#endregion Copy Files
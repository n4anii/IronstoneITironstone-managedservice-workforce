#region Functions
function Sync-SharepointLocation {
    param (
        [guid]$siteId,
        [guid]$webId,
        [guid]$listId,
        [mailaddress]$userEmail,
        [string]$webUrl,
        [string]$webTitle,
        [string]$listTitle,
        [string]$syncPath
    )
    try {
        Add-Type -AssemblyName System.Web
        #Encode site, web, list, url & email
        [string]$siteId = [System.Web.HttpUtility]::UrlEncode($siteId)
        [string]$webId = [System.Web.HttpUtility]::UrlEncode($webId)
        [string]$listId = [System.Web.HttpUtility]::UrlEncode($listId)
        [string]$userEmail = [System.Web.HttpUtility]::UrlEncode($userEmail)
        [string]$webUrl = [System.Web.HttpUtility]::UrlEncode($webUrl)
        #build the URI
        $uri = New-Object System.UriBuilder
        $uri.Scheme = "odopen"
        $uri.Host = "sync"
        $uri.Query = "siteId=$siteId&webId=$webId&listId=$listId&userEmail=$userEmail&webUrl=$webUrl&listTitle=$listTitle&webTitle=$webTitle"
        #launch the process from URI
        Write-Host $uri.ToString()
        start-process -filepath $($uri.ToString())
    }
    catch {
        $errorMsg = $_.Exception.Message
    }
    if ($errorMsg) {
        Write-Warning "Sync failed."
        Write-Warning $errorMsg
    }
    else {
        Write-Host "Sync completed."
        while (!(Get-ChildItem -Path $syncPath -ErrorAction SilentlyContinue)) {
            Start-Sleep -Seconds 2
        }
        return $true
    }    
}
#endregion
#region Main Process
try {
    #region Sharepoint Sync
    [mailaddress]$userUpn = cmd /c "whoami/upn"
    $params = @{
        #replace with data captured from your sharepoint site.
        siteId    = "{c19e0ca8-0318-4dd8-a9f5-03832e159a42}"
        webId     = "{d9952b80-eb27-4859-ad5a-4c07726f3d7d}"
        listId    = "{4A86DD11-0E0D-4D09-9269-7B9B9961540D}"
        userEmail = $userUpn
        webUrl    = "https://aksio.sharepoint.com/sites/felles"
        webTitle  = "felles"
        listTitle = "Dokumenter"
    }
    $params.syncPath  = "$(split-path $env:onedrive)\$("Aksio InsurTech AS")\$($params.webTitle) - $($Params.listTitle)"
    Write-Host "SharePoint params:"
    $params | Format-Table
    if (!(Test-Path $($params.syncPath))) {
        Write-Host "Sharepoint folder not found locally, will now sync.." -ForegroundColor Yellow
        $sp = Sync-SharepointLocation @params
        if (!($sp)) {
            Throw "Sharepoint sync failed."
        }
    }
    else {
        Write-Host "Location already syncronized: $($params.syncPath)" -ForegroundColor Yellow
    }
    #endregion
}
catch {
    $errorMsg = $_.Exception.Message
}
finally {
    if ($errorMsg) {
        Write-Warning $errorMsg
        Throw $errorMsg
    }
    else {
        Write-Host "Completed successfully.."
    }
}
#endregion
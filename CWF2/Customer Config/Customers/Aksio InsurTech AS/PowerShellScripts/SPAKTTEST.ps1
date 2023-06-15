Start-Sleep -Seconds 15
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
        while (!(Get-ChildItem -Path $syncPath -ErrorAction SilentlyContinue) -and !(Get-ChildItem -Path $syncPath.Replace("Dokumenter", "Documents") -ErrorAction SilentlyContinue)) {
            Write-Host "Waiting for folder creation"
            Start-Sleep -Seconds 2
        }
        return $true
    }    
}
#endregion
#region Main Process

if(!(cmd /c "whoami/upn").Contains('@') -or (((Get-Process OneDrive).count) -eq 0)){
    Exit 1
}

try {
    #region Sharepoint Sync
    [mailaddress]$userUpn = cmd /c "whoami/upn"
    $params = @{
        #replace with data captured from your sharepoint site.
        siteId    = "{a6568a20-5d22-4d0f-b850-057bae71fd5f}"
        webId     = "{dc9bf4e2-a2ad-4d7f-a440-050b25df775f}"
        listId    = "{F08A19BC-02F0-4570-AFD4-7A97983702EC}"
        userEmail = $userUpn
        webUrl    = "https://aksio.sharepoint.com/sites/Prosjekter"
        webTitle  = "Prosjekter"
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

if ($false -eq (Test-Path -Path "C:\jottacloud")) {
    New-Item -Path "C:\jottacloud" -ItemType Directory -Force
}

if($false -eq (Test-Path -Path "C:\jottacloud\analysetjenester")){
    if (Test-Path -Path "$home\Aksio InsurTech AS\Prosjekter - Dokumenter") {
        Write-Host "Dokumenter funnet"
        New-Item -ItemType SymbolicLink -Path "C:\jottacloud\analysetjenester" -Value "$home\Aksio InsurTech AS\Prosjekter - Dokumenter" -Force
    }
    elseif (Test-Path -Path "$home\Aksio InsurTech AS\Prosjekter - Documents") {
        Write-Host "Documents found"
        New-Item -ItemType SymbolicLink -Path "C:\jottacloud\analysetjenester" -Value "$home\Aksio InsurTech AS\Prosjekter - Documents" -Force
    }
}
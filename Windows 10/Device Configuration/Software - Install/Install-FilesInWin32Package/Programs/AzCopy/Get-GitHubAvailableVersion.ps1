<#
    .SYNOPSIS
        Gets newest available version of a GitHub project.

    .EXAMPLE
        Get-AvailableVersion -GitHubUserAndProject 'Azure/azure-storage-azcopy'
        & $psISE.'CurrentFile'.'FullPath' -GitHubUserAndProject 'Azure/azure-storage-azcopy'
#>


# Input parameters
[OutputType([System.Version])]
Param (
    [Parameter(Mandatory = $true, HelpMessage = 'GitHub user and project, taken from the full URL, in the format of "user/project".')]
    [ValidateScript({$_ -is [string] -and $_.Split('/').'Count' -eq 2})]
    $GitHubUserAndProject
)


# Return newest stable version
[System.Version](
    $(
        [array](
            $(
                [array](
                    Invoke-RestMethod -Method 'Get' -Uri ('https://github.com/{0}/releases.atom'-f$GitHubUserAndProject)
                )
            ).Where{
                $_.'title' -notlike 'preview*'
            } | Sort-Object -Property @{'Expression'={[datetime]$_.'updated'};'Descending'=$true}
          )
     )[0].'id'.Split('/')[-1].Replace('v','')
)

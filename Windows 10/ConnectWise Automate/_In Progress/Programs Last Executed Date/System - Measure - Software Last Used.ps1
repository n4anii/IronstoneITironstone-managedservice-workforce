function Measure-Latest {
    BEGIN { 
        $latest = $null 
    }
    PROCESS {
        if (($_ -ne $null) -and (($latest -eq $null) -or ($_ -gt $latest))) {
            $latest = $_ 
        }
    }
    END {
        $latest
    }
} 

$Software = Get-WmiObject -Class win32_softwarefeature | Select-Object -Property * <#Caption,LastUse#> | Where-Object {$_.Caption -and $_.LastUse}
[string] $ComputerName = $env:COMPUTERNAME

foreach ($Item in $Software) {
    $Name = $Item.Caption
    $LastUsedString = $Item.Lastuse.Substring(0,8)
    $LastUsed = [int]$LastUsedString
    if ($Name -like '*Microsoft*Office*' -or $Name -like '*Microsoft*Outlook*' -or $Name -like '*Adobe*') { 
        $LastUsed = $LastUsed | Measure-Latest
        If ($LastUsed -eq "19800000"){
            $LastUsed = "Never"
        }
        Write-Output -InputObject "$ComputerName : $Name : $LastUsed"
    }   
}
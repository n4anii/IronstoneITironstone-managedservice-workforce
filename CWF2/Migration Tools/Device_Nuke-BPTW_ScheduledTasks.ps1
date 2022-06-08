# Scheduled tasks
## Introduce
Write-Output -InputObject '# Scheduled Tasks'

## Assets
$ScheduledTasks = [array](Get-ScheduledTask -TaskName '*' | Where-Object -Property 'Author' -Like 'Ironstone*')

## Remove
foreach ($ScheduledTask in $ScheduledTasks) {
    Write-Output -InputObject ('Found "{0}" by author "{1}"' -f ($ScheduledTask.'TaskName', $ScheduledTask.'Author'))
    if ($WriteChanges) {
        $null = Unregister-ScheduledTask -InputObject $ScheduledTask -Confirm:$false      
        Write-Output -InputObject ('{0}Success? {1}' -f ("`t", $?.ToString()))
    }
    else {
        Write-Output -InputObject ('{0}WriteChanges is $false' -f ("`t"))
    }
}
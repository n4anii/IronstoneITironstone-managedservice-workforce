# Stop all running Citrix Processes
$CitrixProcesses = Get-Process | Where-Object -Property 'Description' -Like 'Citrix*'
if (-not([string]::IsNullOrEmpty(@($CitrixProcesses)[0].Name))) {
    foreach ($Process in $CitrixProcesses) {
        Stop-Process -InputObject $Process -Confirm:$false -Force
    }
}
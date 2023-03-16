$categories = "Filtering Platform Packet Drop,Filtering Platform Connection"
$current = auditpol /get /subcategory:"$($categories)" /r | ConvertFrom-Csv    

if($current."Inclusion Setting" -ne "Failure"){
    Write-Output -InputObject "Remediation needed. No Auditing Enabled"
    Exit 1
}
else{
    Write-Output -InputObject "Auditing OK"
    Exit 0
}
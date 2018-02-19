function Get-AzureADGroupAssignment {
    [CmdletBinding()]
    Param(
        [array]$AzureADGroupAssignmentConfigurations
    )    
    
    [array]$ReturnResults = $null

    foreach ($AzureADGroupAssignmentConfiguration in $AzureADGroupAssignmentConfigurations) {
    
        [array]$Assignments = Get-DeviceCompliancePolicyAssignment -id $AzureADGroupAssignmentConfiguration.id
        [array]$AssignedToGroups = $null
        if ($Assignments) {
            foreach ($Assignment in $Assignments) {
                $GroupInfo = Get-AADGroup -id $Assignment.target.GroupId
                $GroupInfoobject = @{
                    'GroupID'     = $GroupInfo.id
                    'displayName' = $GroupInfo.displayName
                }
                $object = New-Object -TypeName PSObject -Property $GroupInfoobject
                $AssignedToGroups += $object
            }
        }
        else {
            $AssignedToGroups += 'None'
        }

        $AzureADGroupAssignmentConfiguration | Add-Member -NotePropertyName AssignedToGroups -NotePropertyValue $AssignedToGroups -force
        $ReturnResults += $AzureADGroupAssignmentConfiguration 
    }

    Return $ReturnResults

}
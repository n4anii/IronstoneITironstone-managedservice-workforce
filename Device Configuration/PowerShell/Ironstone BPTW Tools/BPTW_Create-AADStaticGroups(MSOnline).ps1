#Requires -Modules MSOnline
<#

    Default Azure AD Groups for Intune MDM

#>


# Settings
$WriteChanges = [bool]$false



# Variables - Groups
$Devices      = [string[]]@('Andr','iOS','W10D')
$Environments = [string[]]@('Dev','Prod Default')
$Groups       = [string[]]@('Applications','Compliance','Configuration','Updates','Users')



# Connect
Connect-MsolService



# Get existing groups
function Get-GroupsMDM {$Script:ExistingGroups = @(Get-MsolGroup -All | Where-Object {$_.DisplayName -like 'MDM * - *' -and $_.DisplayName -notlike 'MDM Dev - *'})}
Get-GroupsMDM

    


#region    Create Groups
foreach ($Device in $Devices) {
    foreach ($Environment in $Environments) {
        foreach ($Group in $Groups) {
            [string] $NameGroup = ('MDM {0} - {1} - {2}' -f ($Device,$Environment,$Group))
            Write-Output -InputObject ('Group "{0}" already exist? {1}' -f ($NameGroup,([bool] $Exist = [bool]($ExistingGroups | Where-Object -Property DisplayName -eq $NameGroup))))
            if (-not($Exist)) {
                if ($WriteChanges) {
                    New-MsolGroup -DisplayName $NameGroup -Description ('{0}, used for Intune MDM Assignments.' -f ($NameGroup))
                    Write-Output -InputObject ('   Creating. Success? {0}' -f ($?))
                }
                else {
                    Write-Output -InputObject ('   Did not write changes.')
                }
            }       
        }
    }
}
#endregion Create Groups




#region    Add Group Members
    # Refresh Existing Groups
    Get-GroupsMDM

    # ForEach Device
    foreach ($Device in $Devices) {
        # Get all groups tied to Device
        $ExistingGroupsTiedToDevice = @(@($ExistingGroups) | Where-Object {$_.DisplayName -like ('MDM {0} -*' -f ($Device))})
        
        # Get all Child groups tied to Device (The "Users" groups)
        $ChildGroups    = @($ExistingGroupsTiedToDevice | Where-Object {$_.DisplayName -like ('MDM {0}*Users' -f ($Device))} | Sort-Object -Property 'DisplayName')
        
        # Get all Parent tied to Device (Groups that *Users group is going to be member of)
        $ParentGroups   = $(foreach ($Group in @($Groups | Where-Object {$_ -notlike 'Users'})) {
            $ExistingGroupsTiedToDevice | Where-Object -Property 'DisplayName' -like ('MDM {0}*{1}' -f ($Device,$Group))
        }) | Sort-Object -Property 'DisplayName'

        # ForEach Environment
        foreach ($Environment in $Environments) {
            
            # ForEach Parent Group given Environment
            foreach ($Parent in @($ParentGroups | Where-Object {$_.DisplayName -like ('*{0}*' -f ($Environment))})) {  
                
                # Foreach Child Group given Environment
                foreach ($Child in @($ChildGroups | Where-Object {$_.DisplayName -like ('*{0}*' -f ($Environment))})) {
                    [bool] $IsMember = [bool](@(Get-MsolGroupMember -GroupObjectId $Parent.ObjectId | Select-Object -Property ObjectId) | Where-Object {$_ -eq $Child.ObjectId})
                    Write-Output -InputObject ('"{0}" already member of "{1}"? {2}' -f ($Child.DisplayName,$Parent.DisplayName,$IsMember))
                    if (-not($IsMember)) {
                        Write-Output -InputObject ('   Adding child "{0}" as member of parent "{1}"' -f ($Child.DisplayName,$Parent.DisplayName))
                        if ($WriteChanges) {
                            Add-MsolGroupMember -GroupObjectId $Parent.ObjectId -GroupMemberType 'Group' -GroupMemberObjectId $ChildGroup.ObjectId
                            Write-Output -InputObject ('      Success? {0}' -f ($?))
                        }
                        else {
                            Write-Output -InputObject ('      Did not write changes.')
                        }
                    }
                }
            }
        }
    }
#endregion Add Group Members




#region    Rename Existing Groups
    # Rename from 'MDM Win10 - *' to 'MDM W10D - *'
    $RenameFromTo = [string[]]@('Win10','W10D')
    
    # Rename from 'MDM Android - *' to 'MDM Andr - *'
    $RenameFromTo = [string[]]@('Android','Andr')

    # Generic
    Get-GroupsMDM
    foreach ($Group in @($ExistingGroups | Where-Object -Property 'DisplayName' -like ('MDM {0} - *' -f ($RenameFromTo[0])))) {
        Write-Output -InputObject ('Renaming "{0}" to "{1}".' -f ($Group.DisplayName,$Group.DisplayName.Replace($RenameFromTo[0],$RenameFromTo[1])))
        if ($WriteChanges) {
            Set-MsolGroup -ObjectId $Group.ObjectId -DisplayName ($Group.DisplayName.Replace($RenameFromTo[0],$RenameFromTo[1]))
            Write-Output -InputObject ('   Creating. Success? {0}' -f ($?))
        }
        else {
            Write-Output -InputObject ('   Did not write changes.')
        }
    }
#endregion Rename Existing Groups
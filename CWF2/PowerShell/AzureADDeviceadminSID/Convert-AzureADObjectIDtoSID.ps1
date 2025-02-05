function Convert-AzureAdObjectIdToSid {
    <#
    .SYNOPSIS
    Convert an Azure AD Object ID to SID
     
    .DESCRIPTION
    Converts an Azure AD Object ID to a SID.
    Author: Oliver Kieselbach (oliverkieselbach.com)
    The script is provided "AS IS" with no warranties.
     
    .PARAMETER ObjectID
    The Object ID to convert
    #>
    
        param([String] $ObjectId)
    
        $bytes = [Guid]::Parse($ObjectId).ToByteArray()
        $array = New-Object 'UInt32[]' 4
    
        [Buffer]::BlockCopy($bytes, 0, $array, 0, 16)
        $sid = "S-1-12-1-$array".Replace(' ', '-')
    
        return $sid
    }
    
    $objectId = "fcb1fce0-b1d1-4298-9a6d-8637bf51d4c9"
    $sid = Convert-AzureAdObjectIdToSid -ObjectId $objectId
    Write-Output $sid
    
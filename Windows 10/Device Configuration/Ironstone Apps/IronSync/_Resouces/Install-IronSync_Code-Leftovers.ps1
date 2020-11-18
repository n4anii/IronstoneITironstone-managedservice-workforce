#region    Leftover Code
if ($false) {
    
    # Get details about Scheduled Task
    (Get-ScheduledTask -TaskName 'IronTrigger' | Select-Object -Property *).Actions


    #region    Set NTFS Access Permissions - ReadOnly for all but SYSTEM    
        # Variables
        [string] $ACLUsersFullAccess = 'NT AUTHORITY\SYSTEM'
        [string[]] $ACLUsersReadOnly = @('BUILTIN\Administrators','BUILTIN\Users')   
        # Access
        $CurrentAccess = @((Get-Acl -Path $PathDirSync).Access | `
            Where-Object {$_.IdentityReference -like 'AzureAD\*' -or $_.IdentityReference -like ('{0}\*' -f ($ACLUsersReadOnly[0].Split('\')[0])) })
        foreach ($ACLAccess in $CurrentAccess) {
            $ACL = (Get-Item -Path $PathDirSync).GetAccessControl('Access')  
            $UserName = $ACLAccess.IdentityReference
            $AccessRule = New-Object 'System.Security.AccessControl.FileSystemAccessRule'($UserName,@('ReadAndExecute','Synchronize'),'ContainerInherit,ObjectInherit','None','Allow')
            $ACL.SetAccessRule($AccessRule)
            Set-Acl -Path $PathDirLog -AclObject $ACL
        }

        # Owner
        $CurrentOwner = ((Get-Item $PathDirSync).GetAccessControl('Owner')).Owner
        If ($CurrentOwner -ne $ACLUsersFullAccess) {           
            $null = cmd /c ('icacls "{0}" /setowner "NT AUTHORITY\SYSTEM"' -f ($PathDirSync))
            # $ACLOwner = (Get-Acl -Path $PathDirSync).SetOwner([System.Security.Principal.NTAccount]$ACLUsersFullAccess)
            # Set-Acl -Path $PathDirSync -AclObject $ACLOwner
        }
    
    #endregion Set NTFS Access Permissions - ReadOnly for all but SYSTEM
}
#endregion Leftover Code
# Specify the required permissions
$scopes = "Directory.ReadWrite.All"
# "User.ReadWrite.All", "Group.ReadWrite.All", 
# Connect to Microsoft Graph with the specified permissions
Connect-MgGraph -Scopes $scopes


# Import users from CSV file
$users = Import-Csv "..\import\masterdata.csv" -Delimiter ','

foreach ($user in $users) {
    Write-Output $user.sourceDisplayName
    Write-Output $user.destinationTmpUPN
    Write-Output $user.destinationUPN.Split('@')[0]
    if ($null -eq (Get-MgUser -UserId $user.destinationTmpUPN -ErrorAction SilentlyContinue)) {
        # Create a new user object
        Write-Output "Create User"
        $newUser = @{
            AccountEnabled    = $true
            DisplayName       = $user.destinationDisplayName
            MailNickname      = $user.destinationUPN.Split('@')[0]
            UserPrincipalName = $user.destinationTmpUPN
            PasswordProfile   = @{
                ForceChangePasswordNextSignIn = $true
                Password                      = $user.Password
            }
            GivenName         = $user.firstName
            Surname           = $user.lastName
            UsageLocation     = $user.UsageLocation
        }

        # Create a new user in Azure AD
        $createdUser = New-MgUser -BodyParameter $newUser

        # Get the group by searching for its display name
        $group = Get-MgGroup -Filter "displayName eq '$($user.licenseGroup)'"

        # Add the user to the group
        if ($group) {
            New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $createdUser.Id
        }
    }
    else {
        Write-Output "Users exits"
    }
}
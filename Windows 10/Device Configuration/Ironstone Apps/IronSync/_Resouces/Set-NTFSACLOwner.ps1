$folder = "\\homeserver\users\"
$users = get-childitem $folder

Foreach ($user in $users) {
    $acl = Get-Acl $user.FullName
    $acl.SetOwner([System.Security.Principal.NTAccount]"$user")
    set-acl $user.FullName $acl -Verbose

    $subFolders = Get-ChildItem $user.FullName -Directory -Recurse
    Foreach ($subFolder in $subFolders) {
        $acl = Get-Acl $subFolder.FullName
        $acl.SetOwner([System.Security.Principal.NTAccount]"$user")
        set-acl $subFolder.FullName $acl -Verbose
    }
    
    $subFiles = Get-ChildItem $user.FullName -File -Recurse
    Foreach ($subFile in $subFiles) {
        $acl = Get-Acl $subFile.FullName
        $acl.SetOwner([System.Security.Principal.NTAccount]"$user")
        set-acl $subFile.FullName $acl -Verbose
    }
}
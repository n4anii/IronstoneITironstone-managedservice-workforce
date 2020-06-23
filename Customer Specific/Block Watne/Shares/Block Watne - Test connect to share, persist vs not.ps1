# Test locally on Ironstone offices
$ShareLetter = [string]$('X')
$ShareRoot   = [string]$('\\192.168.86.146\Share')
$Credential  = [pscredential]$(Get-Credential -UserName 'BPCR90PSVEF\samba' -Message 'Enter password.')


# Test Block Watne share
$ShareLetter = [string]$('H')
$ShareRoot   = [string]$('\\bwfs003\Home')
$Credential  = [pscredential]$(Get-Credential -Message ('Username (domain\user) and password for access to the share.{0}{0}"{1}"{0}"{2}"' -f ("`r`n",$ShareLetter,$ShareRoot)))


#region    Connect
    # Connect - Persist
    New-PSDrive -PSProvider 'FileSystem' -Name $ShareLetter -Root $ShareRoot -Credential $Credential -Persist:$true

    # Connect - !Persist
    New-PSDrive -PSProvider 'FileSystem' -Name $ShareLetter -Root $ShareRoot -Credential $Credential -Persist:$false

    # Connect - .NET   
    $(New-Object -ComObject 'WScript.Network').MapNetworkDrive($('{0}:' -f $ShareLetter),$ShareRoot,$false,$Credential.'UserName',$Credential.GetNetworkCredential().'Password')

    # Connect - CMD net use - Persistant
    cmd /c $('net use {0}: "{1}" /user:"{2}" "{3}" /persistent:yes' -f ($ShareLetter,$ShareRoot,$Credential.'UserName',$Credential.GetNetworkCredential().'Password'))

    # Connect - CMD net use - !Persistant
    cmd /c $('net use {0}: "{1}" /user:"{2}" "{3}" /persistent:no' -f ($ShareLetter,$ShareRoot,$Credential.'UserName',$Credential.GetNetworkCredential().'Password'))
#endregion Connect



#region    Disconnect
    # Disconnect - PowerShell
    Get-PSDrive -Name $ShareLetter -ErrorAction 'SilentlyContinue' | Remove-PSDrive -Force

    # Disconnect - CMD net use
    cmd /c $('net use /delete {0}:' -f ($ShareLetter))
#endregion Disconnect
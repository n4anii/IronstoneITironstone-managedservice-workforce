#region    Assets
    # Static
    $ComputerNameBase = [string]$('BPC')
    $Path             = [string]$('Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName')
    $Name             = [string]$('ComputerName')


    # Current ComputerName
    $ComputerNameOld  = [string]$(Get-ItemProperty -Path $Path -Name $Name -ErrorAction 'Stop' | Select-Object -ExpandProperty $Name -ErrorAction 'Stop').Trim()
    if ([string]::IsNullOrEmpty($ComputerNameOld)){Throw 'ERROR: Did not manage to retrieve current ComputerName'}


    # New ComputerName
    $ComputerNameNew  = [string]$('{0}{1}' -f ($ComputerNameBase,[string]$(Get-WmiObject -Class 'Win32_ComputerSystemProduct' -ErrorAction 'Stop' | Select-Object -ExpandProperty 'IdentifyingNumber' -ErrorAction 'Stop'))).Trim()
    if ($ComputerNameNew.Length -le $ComputerNameBase.Length){Throw 'ERROR: Did not manage to create new ComputerName'}
#endregion Assets



#region    Set ComputerName
    # If ComputerNameNew is the same as ComputerNameOld = Don't change anything
    if ($ComputerNameOld -eq $ComputerNameNew) {
        Write-Output -InputObject ('ComputerName is already "{0}". Did not change anything.' -f ($ComputerNameNew))
    }
    # If ComputerNameNew is not the same as ComputerNameOld = Change ComputerName
    else {
        # Set ComputerName
        $Success = [bool]$(if([byte]$((Get-WmiObject -Class 'Win32_ComputerSystem').Rename($ComputerNameNew) | Select-Object -ExpandProperty 'ReturnValue') -eq 0){$true}else{$false})

        # Write Out Success
        Write-Output -InputObject ('Successfully changed ComputerName from "{0}" to "{1}"? {2}.' -f ($ComputerNameOld,$ComputerNameNew,$Success.ToString()))
    }
#endregion Set ComputerName
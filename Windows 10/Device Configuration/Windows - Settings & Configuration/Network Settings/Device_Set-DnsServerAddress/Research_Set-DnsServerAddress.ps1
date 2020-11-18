<#

    .DESCRIPTION

    .NOTES
        CMDLets
            Get-NetAdapter
            https://docs.microsoft.com/powershell/module/netadapter/get-netadapter

            Get-DnsClientServerAddress
            https://docs.microsoft.com/powershell/module/dnsclient/get-dnsclientserveraddress

            Set-DnsClientServerAddress
            https://docs.microsoft.com/powershell/module/dnsclient/set-dnsclientserveraddress

#>





#region    Get Network Interfaces
    # Get all physical network interfaces, skip Cellular / GSM
    $NetworkInterfaces = Get-NetAdapter -Physical | Where-Object -FilterScript {$_.Name -notlike 'Cellular*'}
#endregion Get Network Interfaces




#region    List All Configured DNS Server Addresses
    # Get Dns Configuration for all Physical Interfaces - Oneliner
    [string[]]$(Get-DnsClientServerAddress | Select-Object –ExpandProperty 'ServerAddresses' -ErrorAction 'SilentlyContinue' | Select-Object -Unique)

    # Get Dns Configuration for all Physical Interfaces - IPv4 Only - Oneliner
    [string[]]$(Get-DnsClientServerAddress | Select-Object –ExpandProperty 'ServerAddresses' -ErrorAction 'SilentlyContinue' | Where-Object -FilterScript {$_ -notlike '*:*:*:*:*:*'} -ErrorAction 'SilentlyContinue' | Select-Object -Unique)
#endregion List All Configured DNS Server Addresses




#region    List Dns Configurations Per NIC
    # List Dns Configuration per NIC - All
    foreach ($NIC in $NetworkInterfaces) {
        $DNS_IPv6 = [string[]]$(Get-DnsClientServerAddress -InterfaceAlias $NIC.'InterfaceAlias' | Select-Object –ExpandProperty 'ServerAddresses')
        Write-Output -InputObject ([string]$('{0} - {1}' -f ($NIC.'InterfaceAlias',[string]$(if($DNS.Count -ge 1){$DNS -join ', '}else{'None'}))))
    }


    # List Dns Configuration per NIC - IPv4 Only
    foreach ($NIC in $NetworkInterfaces) {
        $DNS_IPv4 = [string[]]$(Get-DnsClientServerAddress -InterfaceAlias $NIC.'InterfaceAlias' | Select-Object –ExpandProperty 'ServerAddresses' | Where-Object -FilterScript {$_ -notlike '*:*:*:*:*:*'})
        Write-Output -InputObject ([string]$('{0} - IPv4 - {1}' -f ($NIC.'InterfaceAlias',[string]$(if($DNS_IPv4.Count -ge 1){$DNS_IPv4 -join ', '}else{'None'}))))
    }


    # List Dns Configuration per NIC - IPv6 Only
    foreach ($NIC in $NetworkInterfaces) {
        $DNS_IPv6 = [string[]]$(Get-DnsClientServerAddress -InterfaceAlias $NIC.'InterfaceAlias' | Select-Object –ExpandProperty 'ServerAddresses' | Where-Object -FilterScript {$_ -like '*:*:*:*:*:*'})
        Write-Output -InputObject ([string]$('{0} - IPv6 - {1}' -f ($NIC.'InterfaceAlias',[string]$(if($DNS_IPv6.Count -ge 1){$DNS_IPv6 -join ', '}else{'None'}))))
    }


    # List Dns Configuration per NIC - IPv4 Only - Oneliner
    foreach ($NICAlias in [string[]]$(Get-NetAdapter -Physical | Where-Object -FilterScript {$_.Name -notlike 'Cellular*'} | Select-Object -ExpandProperty 'InterfaceAlias')){$DNS=[string[]]$(Get-DnsClientServerAddress -InterfaceAlias $NICAlias | Select-Object –ExpandProperty 'ServerAddresses' | Where-Object -FilterScript {$_ -notlike '*:*:*:*:*:*'});Write-Output -InputObject ([string]$('{0} - {1}' -f ($NICAlias,[string]$(if($DNS.Count -ge 1){$DNS -join ', '}else{'None'}))))}
#endregion List Dns Configurations Per NIC




#retion    Set Dns Configuration
    <#
        Cloudflare
            1.1.1.1
            1.0.0.1
            2606:4700:4700::1111
            2606:4700:4700::1001
            $DNSAddresses=[string[]]@('1.1.1.1','1.0.0.1','2606:4700:4700::1111','2606:4700:4700::1001')

        Google
            8.8.8.8
            8.8.4.4
            2001:4860:4860::8888
            2001:4860:4860::8844
            $DNSAddresses=[string[]]@('8.8.8.8','8.8.4.4','2001:4860:4860::8888','2001:4860:4860::8844')
        
        OpenDNS
            208.67.222.222
            208.67.220.220
            $DNSAddresses=[string[]]@('208.67.222.222','208.67.220.220')

        Metier
            54.76.198.100 aws-clouddns1.mnemonic.no
            52.28.79.14   aws-clouddns2.mnemonic.no
            $DNSAddresses=[string[]]@('54.76.198.100','52.28.79.14')


    #>
    
    # Set Dns Configuration for all Physical Interfaces
    foreach ($NIC in $NetworkInterfaces) {
        Set-DnsClientServerAddress -InterfaceAlias $NIC.'InterfaceAlias' -ServerAddresses ([string[]]$('1.1.1.1','1.0.0.1')) -ErrorAction 'Stop'
    }


    # Set Dns Configuration for all Physical Interfaces - Oneliner - Cloudflare
    ([bool]$($DNSAddresses=[string[]]@('1.1.1.1','1.0.0.1','2606:4700:4700::1111','2606:4700:4700::1001');-not([bool[]]$(foreach ($NICAlias in [string[]]$(Get-NetAdapter -Physical | Where-Object -FilterScript {$_.Name -notlike 'Cellular*'} | Select-Object -ExpandProperty 'InterfaceAlias')){$null = Set-DnsClientServerAddress -InterfaceAlias $NICAlias -ServerAddresses $DNSAddresses -ErrorAction 'SilentlyContinue';$?}).Contains($false))))


    # Set Dns Configuration for all Physical Interfaces - Oneliner - Metier
    ([bool]$($DNSAddresses=[string[]]@('54.76.198.100','52.28.79.14');-not([bool[]]$(foreach ($NICAlias in [string[]]$(Get-NetAdapter -Physical | Where-Object -FilterScript {$_.Name -notlike 'Cellular*'} | Select-Object -ExpandProperty 'InterfaceAlias')){$null = Set-DnsClientServerAddress -InterfaceAlias $NICAlias -ServerAddresses $DNSAddresses -ErrorAction 'SilentlyContinue';$?}).Contains($false))))

#endregion Set Dns Configuration




#region    Reset to DHCP Default
    # Reset to DHCP Default - Oneliner
    ([bool]$(-not([bool[]]$(foreach ($NICAlias in [string[]]$(Get-NetAdapter -Physical | Where-Object -FilterScript {$_.Name -notlike 'Cellular*'} | Select-Object -ExpandProperty 'InterfaceAlias')){$null = Set-DnsClientServerAddress -InterfaceAlias $NICAlias -ResetServerAddresses -ErrorAction 'SilentlyContinue';$?}).Contains($false))))
#endregion Reset to DHCP Default




#region    Test
    $NetworkInterfaces | Select-Object -ExpandProperty 'InterfaceAlias'
    [string[]]$(Get-DnsClientServerAddress -InterfaceAlias 'Wi-Fi' | Select-Object –ExpandProperty 'ServerAddresses' | Where-Object -FilterScript {$_ -notlike '*:*:*:*:*:*'})
#endregion Test
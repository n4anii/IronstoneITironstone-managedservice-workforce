# Get connected NICs with IPv4 gateway, local ip address and DNS
Get-NetAdapter -Physical | Where-Object -Property 'MediaConnectionState' -EQ 'Connected' | Select-Object -Property 'Name','InterfaceDescription','MacAddress','LinkSpeed',@{'Name'='GatewayIPv4';'Expression'={$(Get-NetIPConfiguration -InterfaceIndex $_.'ifIndex').'IPv4DefaultGateway'.'NextHop'}},@{'Name'='AddressIPv4';'Expression'={Get-NetIPAddress -InterfaceIndex $_.'ifIndex' -AddressFamily 'IPv4' | Select-Object -ExpandProperty 'IPAddress'}},@{'Name'='DNSIPv4';'Expression'={$(Get-DnsClientServerAddress -InterfaceIndex $_.'ifIndex' -AddressFamily 'IPv4' | Select-Object -ExpandProperty 'ServerAddresses') -join ', '}} | Format-Table -AutoSize


# Check ports outbound
## SMB
Test-NetConnection -ComputerName 'test.file.core.windows.net' -Port 445
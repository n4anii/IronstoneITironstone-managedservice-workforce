#!/bin/sh

mkdir -p /opt/cisco/anyconnect/profile

cat <<EOF>/opt/cisco/anyconnect/profile/profile.xml
<?xml version="1.0" encoding="UTF-8"?>
<AnyConnectProfile xmlns="http://schemas.xmlsoap.org/encoding/">
<ServerList>
<HostEntry>
<HostName>Voice VPN</HostName>
<HostAddress>vpn.voice.no</HostAddress>
</HostEntry>
</ServerList>
</AnyConnectProfile>
EOF
#!/bin/bash
# @sp4rkiop -Github
# Full Automation of IPv6 address update to DUCKDNS
cd "$(dirname "$0")"
#set -x

[ -f IPV4.IP ] || touch IPV4.IP
[ -f IPV6.IP ] || touch IPV6.IP

# Timeouts and better error handling
ipv4add=$(curl --silent --ipv4 --max-time 10 --fail ifconfig.me/ip 2>/dev/null)
ipv6add=$(curl --silent --ipv6 --max-time 10 --fail ifconfig.me/ip 2>/dev/null)

# IPv4 validation (checks 0-255 range) - required
if [[ ! "$ipv4add" =~ ^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$ ]]; then
    echo "Error: Invalid or missing IPv4 address: '$ipv4add'"
    exit 1
fi

# IPv6 validation (handles compressed and full formats)
ipv6_valid=true
if [[ ! "$ipv6add" =~ ^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^([0-9a-fA-F]{1,4}:)*::([0-9a-fA-F]{1,4}:)*[0-9a-fA-F]{1,4}$|^::1$|^::$ ]]; then
    echo "Warning: Invalid or missing IPv6 address: '$ipv6add' - continuing with IPv4 only"
    ipv6_valid=false
fi

DOMAIN=xxxxxx
TOKEN=yyyyyy

# Build URL with or without IPv6
if [ "$ipv6_valid" = true ]; then
    url="https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=$ipv4add&ipv6=$ipv6add&verbose=true"
else
    url="https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=$ipv4add&verbose=true"
fi

LAST_IPV4=$(cat IPV4.IP 2>/dev/null || echo "")
LAST_IPV6=$(cat IPV6.IP 2>/dev/null || echo "")

# Check if update is needed
update_needed=false
if [ "$LAST_IPV4" != "$ipv4add" ]; then
    update_needed=true
fi
if [ "$ipv6_valid" = true ] && [ "$LAST_IPV6" != "$ipv6add" ]; then
    update_needed=true
fi

if [ "$update_needed" = true ]; then
    echo "$ipv4add" > IPV4.IP
    if [ "$ipv6_valid" = true ]; then
        echo "$ipv6add" > IPV6.IP
    fi

    # Response validation for DuckDNS update
    response=$(curl --silent --max-time 10 "$url")
    if echo "$response" | grep -q "^OK"; then
        if [ "$ipv6_valid" = true ]; then
            echo "DuckDNS update successful (IPv4 + IPv6)"
        else
            echo "DuckDNS update successful (IPv4 only)"
        fi
    else
        echo "Error: DuckDNS update failed. Response: $response"
        exit 1
    fi
fi

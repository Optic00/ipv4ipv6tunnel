#!/bin/bash 
# https://thenybble.de/projects/ipip6.html
# https://serverfault.com/questions/93998/public-ip-routing-over-private-gre-tunnel
remoteipv6_fqdn=optiremv6.mooo.com
remoteipv6=$(dig +short AAAA $remoteipv6_fqdn)
echo "Die Remote IPv6 Adresse lautet:" $remoteipv6
interface=eth0
tunnelname=ip6tnl1    
localtunnelip=172.25.26.2/24
localipv6addr=$(ip addr show dev $interface | sed -e's/^.*inet6 \([^ ]*\)\/.*$/\1/;t;d')
echo "Die lokale IPv6 Adresse lautet:" $localipv6addr
#dig +short AAAA optiv6.mooo.com
#already have a tunnel interface?
if  ip link | grep ip6tnl1 >/dev/null; then
  echo "Local Tunnel IP is up"
  tunnelstatus=1
else
  echo "Local Tunnel IP is down"
  tunnelstatus=0
fi

# Now we are checking of the local and remote IPv6 Adresses are still valid

# here for the local IPv6 Adress Endpoint

if [[ $(ip link | grep -A 1 ip6tnl1 | grep link | cut -d ' ' -f 6) != $localipv6addr ]]; then
	echo "Lokale IPv6 passt nicht mehr - Tunnel ggf. löschen"
		if [ "$tunnelstatus" == "1" ]; then	
			ip -6 tunnel del $tunnelname
			echo "setting localipv6_status to invalid (0)"
			remoteipv6_status=0
		else
			echo "setting localipv6_status to invalid (0)"
			remoteipv6_status=0
		fi
	else 
		echo "setting localipv6_status to valid (1)"
		localipv6addr_status=1
fi

# here for the remote IPv6 Adress Endpoint

if [[ $(ip link | grep -A 1 ip6tnl1 | grep link | cut -d ' ' -f 8) != $remoteipv6 ]]; then
	echo "Remote IPv6 passt nicht mehr - Tunnel ggf. löschen"
		if [ "$tunnelstatus" == "1" ]; then
			ip -6 tunnel del $tunnelname
			echo "setting remoteipv6_status to invalid (0)"
			remoteipv6_status=0
		else
			echo "setting remoteipv6_status to invalid (0)"
			remoteipv6_status=0			
		fi
	else
		echo "setting remoteipv6_status to valid (1)"
		remoteipv6_status=1
		#echo $remoteipv6_status
fi

#if [ $1="country" ]; then
#if [ "$status" == "alive" ]
#if [ $localipv6addr_status="valid" ] && [ $remoteipv6_status="valid" ]; then

#echo "der Status von localipv6addr_status" ist auf $localipv6addr_status
if [ "$localipv6addr_status" == "1" ] && [ "$remoteipv6_status" == "1" ]; then
	echo "Everything OK, local and remote IPv6 valid!"
		exit 1
	else
	echo "Local and Remote IP are not valid - Recreating Tunnel"

fi

#echo "no tunnel up yet - lets get one up!"
#ip -6 tunnel add ip6tnl2 mode ip4ip6 remote 2001:19f0:6c01:ef2:5400:1ff:fe3e:2bb0 local optiv6.mooo.com
echo "The IPv6 Adress of WAN (eth0) is:" $localipv6addr 
echo "checken ob das so noch passt"
#ip link | grep -A 1 ip6tnl1 | grep link
#Lokale IPv6:
ip link | grep -A 1 ip6tnl1 | grep link | cut -d ' ' -f 6
#Remote IPv6:
ip link | grep -A 1 ip6tnl1 | grep link | cut -d ' ' -f 8
ip -6 tunnel add $tunnelname mode ip4ip6 remote $remoteipv6 local $localipv6addr
echo "tunnel eingerichtet - jetzt 2 sekunden warten und dann "uppen""
sleep 2s 
echo "2s sind vorbei jetzt up"
ip link set dev ip6tnl1 up
echo "Tunnel sollte nun up sein"
logger $0: "Tunnel mit der lokalen IPv6 $localipv6addr und der remote IPv6 $remoteipv6 sollte nun wieder up sein"
ip addr add $localtunnelip dev $tunnelname
#grep "/bin/bash" /etc/passwd | cut -d':' -f1,6

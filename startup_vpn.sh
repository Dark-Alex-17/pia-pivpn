#!/bin/bash
declare ntfyTopic=atusa_061796_pihole
curl -H "t: Resetting VPN" -H "p:5" -H "ta:warning" -d "PiHole VPN connection expired. Resetting both VPNs. PiVPN reconfigure is required." ntfy.sh/$ntfyTopic

pkill -f openvpn > /dev/null 2>&1
pkill -f port_forwarding > /dev/null 2>&1

declare portFile=/home/pi/pf_port
[[ -f $portFile ]] && rm $portFile

./run_setup.sh

until [[ -f $portFile ]]; do
	echo "Waiting for port forwarding to complete..."
	sleep 3
done

declare port=$(cat $portFile | head -1)
declare gateway=$(ip route | grep tun | awk '/^0.0.0.0*/ { print $3;}')
declare host=$(curl -s api.ipify.org)
declare expiration=$(cat $portFile | tail -1)
declare expirationDayEpoch=$(echo $expiration | xargs -i date -d {} +%m/%d/%Y | xargs -i date -d {} +%s)
declare setupVarsFile=/home/pi/pia-pivpn/setupVars.conf

curl -H "t: Port Forwarding Expires Today" -H "p:5" -H "ta:warning" -H "Delay: $expirationDayEpoch" -d "PiHole port forwarding expires at $expiration. The connection will be reset at this time and you'll need to ssh into your pihole to connect devices to PiVPN again." ntfy.sh/$ntfyTopic

sed -i "/pivpnPORT=/c\pivpnPORT=$port" $setupVarsFile
sed -i "/IPv4gw=/c\IPv4gw=$gateway" $setupVarsFile
sed -i "/pivpnHOST=/c\pivpnHOST=$host" $setupVarsFile

declare -a users=( $(pivpn -l | grep -v ':::\|Client' | awk '{print $1;}') )

/home/pi/pivpn/pivpn_install.sh --reconfigure --unattended /home/pi/pia-pivpn/setupVars.conf

for user in ${users[@]}; do
	pivpn -a -n $user
done

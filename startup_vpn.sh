#!/bin/bash
pkill -f openvpn > /dev/null 2>&1
pkill -f port_forwarding > /dev/null 2>&1

declare portFile=/home/pi/pia-pivpn/pf_port
[[ -f $portFile ]] && rm $portFile

./run_setup.sh

until [[ -f $portFile ]]; do
	echo "Waiting for port forwarding to complete..."
	sleep 3
done

declare port=$(cat $portFile | head -1)
declare gateway=$(ip route | grep tun | awk '/^0.0.0.0*/ { print $3;}')
declare host=$(curl -s api.ipify.org)
declare setupVarsFile=/home/pi/pia-pivpn/setupVars.conf

sed -i "/pivpnPORT=/c\pivpnPORT=$port" $setupVarsFile
sed -i "/IPv4gw=/c\IPv4gw=$gateway" $setupVarsFile
sed -i "/pivpnHOST=/c\pivpnHOST=$host" $setupVarsFile

declare -a users=( $(pivpn -l | grep -v ':::\|Client' | awk '{print $1;}') )

curl -L https://install.pivpn.io | bash -s -- --reconfigure --unattended /home/pi/pia-pivpn/setupVars.conf

for user in ${users[@]}; do
	pivpn -a -n $user
done

#!/bin/bash

if (( EUID != 0 )); then
	echo "This script needs to be run as sudo"
	exit 1
fi

TERMINAL_HEIGHT=$(tput lines)
BOX_HEIGHT=$(printf "%.0f" "$(echo "scale=2; $TERMINAL_HEIGHT * .5" | bc)")

TERMINAL_WIDTH=$(tput cols)
BOX_WIDTH=$(printf "%.0f" "$(echo "scale=2; $TERMINAL_WIDTH * .75" | bc)")
declare piaCredsFile=/etc/openvpn/auth.txt

if ! (command -v whiptail 2> /dev/null); then
	apt install whiptail
fi

if [[ ! -d /etc/openvpn ]]; then
	mkdir /etc/openvpn
fi

checkPiaCredentials() {
	if [[ ! -f  $piaCredsFile ]]; then
		PIA_PASS=$(whiptail --passwordbox "Please enter your PIA password" "$BOX_HEIGHT" "$BOX_WIDTH" 3>&2 2>&1 1>&3)
		cat <<-EOF > /etc/openvpn/auth.txt
			p0486245
			$PIA_PASS
			EOF
	fi
}

createVpnService() {
	declare serviceFile=/lib/systemd/system/vpn.service
	if [[ ! -f $serviceFile ]]; then
		cat <<-EOF > $serviceFile
			[Unit]
			Description=Startup for PIA VPN with port forwarding and PiVPN
			After=network.target
			
			[Service]
			User=root
			Group=root
			RemainAfterExit=1
			Type=simple
			ExecStart=/home/pi/pia-pivpn/startup_vpn.sh
			Restart=on-failure
			
			[Install]
			WantedBy=multi-user.target
			EOF
	fi
}

installVpn() {
	checkPiaCredentials
	createVpnService
	systemctl daemon-reload
	systemctl enable vpn.service
	service vpn start
}

installVpn

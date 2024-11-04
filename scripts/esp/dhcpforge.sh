#!/bin/bash
#:Title: dhcpforge.sh
#:Version: 1.0
#:Author: Pablo Fernández López
#:Date: 11/04/2024
#:Description: A tool made for the creation and the managment of a dhcp server in an Ubuntu 22.04 system.
#:Usage: First option makes the complete installation for the DHCP-SERVER. The second option configures and sets up all of the parameters needed.
#:Dependencies:
#:      - "ISC-DHCP-SERVER"
install_dhcp_server(){
   sudo apt-get update && sudo apt-get upgrade -y
   sudo apt-get install isc-dhcp-server
   sudo cp /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server.copy

   ip -o link show | awk -F': ' '{print $2}' | grep -v "lo"
   read -p "Enter the name of the interface for the DHCP server (e.g., ens33, ens34, etc.): " ens

   config_file="/etc/default/isc-dhcp-server"
   if [ -f "$config_file" ]; then
       sudo sed -i "s/^INTERFACESv4=.*/INTERFACESv4=\"$ens\"/" "$config_file"
   else
       echo "Error: $config_file doesn't exist."
   fi

   service isc-dhcp-server restart
   sudo ip link set $ens down
   sudo ip link set $ens up
}

configure_dhcp_server(){
   config_file="/etc/dhcp/dhcpd.conf"
   if [ ! -f "$config_file" ]; then
       echo "Error: The $config_file doesn't exist."
       exit 1
   fi

   read -p "Enter the network address (e.g., 10.33.200.0): " subnet
   read -p "Enter the network mask (e.g., 255.255.255.0): " netmask
   read -p "Enter the IP address of the router (e.g., 10.33.200.1): " router
   read -p "Enter the DNS (e.g., 8.8.8.8, 1.1.1.1): " dns
   read -p "Enter the start of the IP range (e.g., 10.33.200.5): " range_start
   read -p "Enter the end of the IP range (e.g., 10.33.200.20): " range_end

   config_dhcp="subnet $subnet netmask $netmask {
     option routers $router;
     option subnet-mask $netmask;
     option domain-name-servers $dns;
     range $range_start $range_end;
   }"

   echo "option domain-name \"example.org\";" | sudo tee "$config_file" > /dev/null
   echo "option domain-name-servers ns1.example.org, ns2.example.org;" | sudo tee -a "$config_file" > /dev/null
   echo "default-lease-time 600;" | sudo tee -a "$config_file" > /dev/null
   echo "max-lease-time 7200;" | sudo tee -a "$config_file" > /dev/null
   echo "ddns-update-style none;" | sudo tee -a "$config_file" > /dev/null
   echo -e "\n$config_dhcp" | sudo tee -a "$config_file" > /dev/null

      echo "DHCP configuration updated in $config_file."

      sudo systemctl restart isc-dhcp-server
      sudo dhcp-lease-list --lease /var/lib/dhcp/dhcpd.leases | awk '{print $3}' | while read ip; do
      ping -c 1 $ip &> /dev/null && ssh -o ConnectTimeout=2 $ip "sudo dhclient -r && sudo dhclient" &
   
   done
}
}

while true; do
   echo "Select an option:"
   echo "1) Install ISC-DHCP-SERVER"
   echo "2) Configure DHCP server parameters"
   echo "3) Exit"

   read -p "Enter your option (1-3): " option

   case $option in
       1)
           install_dhcp_server
           ;;
       2)
           configure_dhcp_server
           ;;
       3)
           exit 0
           ;;
       *)
           echo "Invalid option, please try again."
           ;;
   esac

   echo -e "\n"
done

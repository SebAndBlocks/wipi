rs=$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 4 | awk '{print substr($0,1,1) substr($0,2,1) substr($0,3,1) substr($0,4,1)}')
ssid="MyWiPi_$rs"
wpa_passphrase="wipi-$rs"
# Use sed to modify the configuration file
sudo sed -i "s/^ssid=.*/ssid=$ssid/" /etc/hostapd/hostapd.conf
sudo sed -i "s/^wpa_passphrase=.*/wpa_passphrase=$wpa_passphrase/" /etc/hostapd/hostapd.conf
# Change the router IP address to 192.168.10.1
sudo sed -i 's/^interface=wlan0/#&\ninterface=wlan0\n\ndhcp-range=192.168.10.2,192.168.10.254,255.255.255.0,24h\n\naddress=/double-click.net/192.168.10.1/' /etc/dnsmasq.d/090_raspap.conf
# Allow access to devices on the main router at 192.168.0.*
sudo sed -i 's/^#dhcp-option=3.*/dhcp-option=3,192.168.10.1/' /etc/dnsmasq.d/090_raspap.conf
sudo sed -i 's/^#dhcp-option=6.*/dhcp-option=6,192.168.0.1/' /etc/dnsmasq.d/090_raspap.conf
sudo cat /usr/wipi/boot.sh > /dev/null

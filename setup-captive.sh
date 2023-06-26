echo "Welcome to WiPi by TurquoiseTNT"
echo "Setup will now Start"
echo "-------------------------------"
echo "Step 1: Installing RaspAP Web GUI"
echo "RaspAP Quick Installer will now run. Prompts may occur from RaspAP"
curl -sL https://install.raspap.com | bash
echo "Welcome back to the WiPi script. The previous commands between our 'RaspAP Installer will now Run' prompt and this prompt were all part of RaspAP Quick Installer."
echo "Step 2: Installing nodogsplash Captive Portal"
sudo apt-get install libmicrohttpd-dev
cd ~/
git clone https://github.com/nodogsplash/nodogsplash.git
cd nodogsplash
make
sudo make install
echo "nodogsplash built"
CONFIG_FILE="/etc/nodogsplash/nodogsplash.conf"
sed -i 's/^GatewayInterface.*/GatewayInterface new-interface/' "$CONFIG_FILE"
echo "GatewayInterface wlan0" >> "$CONFIG_FILE"
echo "GatewayAddress 10.3.141.1" >> "$CONFIG_FILE"
sudo cp ~/nodogsplash/debian/nodogsplash.service /lib/systemd/system/
sudo systemctl enable nodogsplash.service 
sudo systemctl start nodogsplash.service
echo "Step 3: Editing SSID and Password Settings for your RaspAP."
# Specify the new WiFi broadcast settings
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

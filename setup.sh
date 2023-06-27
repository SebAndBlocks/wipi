echo "Welcome to WiPi by TurquoiseTNT"
echo "Setup will now Start"
echo "-------------------------------"
echo "Step 1: Installing RaspAP Web GUI"
sudo raspi-config
sudo rfkill unblock wlan
sudo apt-get install lighttpd git hostapd dnsmasq iptables-persistent vnstat qrencode php7.3-cgi
sudo lighttpd-enable-mod fastcgi-php    
sudo service lighttpd force-reload
sudo systemctl restart lighttpd.service
sudo rm -rf /var/www/html
sudo git clone https://github.com/RaspAP/raspap-webgui /var/www/html
WEBROOT="/var/www/html"
CONFSRC="$WEBROOT/config/50-raspap-router.conf"
LTROOT=$(grep "server.document-root" /etc/lighttpd/lighttpd.conf | awk -F '=' '{print $2}' | tr -d " \"")

HTROOT=${WEBROOT/$LTROOT}
HTROOT=$(echo "$HTROOT" | sed -e 's/\/$//')
awk "{gsub(\"/REPLACE_ME\",\"$HTROOT\")}1" $CONFSRC > /tmp/50-raspap-router.conf
sudo cp /tmp/50-raspap-router.conf /etc/lighttpd/conf-available/
sudo ln -s /etc/lighttpd/conf-available/50-raspap-router.conf /etc/lighttpd/conf-enabled/50-raspap-router.conf
sudo systemctl restart lighttpd.service
cd /var/www/html
sudo cp installers/raspap.sudoers /etc/sudoers.d/090_raspap
sudo mkdir /etc/raspap/
sudo mkdir /etc/raspap/backups
sudo mkdir /etc/raspap/networking
sudo mkdir /etc/raspap/hostapd
sudo mkdir /etc/raspap/lighttpd
sudo cp raspap.php /etc/raspap 
sudo chown -R www-data:www-data /var/www/html
sudo chown -R www-data:www-data /etc/raspap
sudo mv installers/*log.sh /etc/raspap/hostapd 
sudo mv installers/service*.sh /etc/raspap/hostapd
sudo chown -c root:www-data /etc/raspap/hostapd/*.sh 
sudo chmod 750 /etc/raspap/hostapd/*.sh 
sudo cp installers/configport.sh /etc/raspap/lighttpd
sudo chown -c root:www-data /etc/raspap/lighttpd/*.sh
sudo mv installers/raspapd.service /lib/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable raspapd.service
sudo mv /etc/default/hostapd ~/default_hostapd.old
sudo cp /etc/hostapd/hostapd.conf ~/hostapd.conf.old
sudo cp config/default_hostapd /etc/default/hostapd
sudo cp config/hostapd.conf /etc/hostapd/hostapd.conf
sudo cp config/090_raspap.conf /etc/dnsmasq.d/090_raspap.conf
sudo cp config/090_wlan0.conf /etc/dnsmasq.d/090_wlan0.conf
sudo cp config/dhcpcd.conf /etc/dhcpcd.conf
sudo cp config/config.php /var/www/html/includes/
sudo cp config/defaults.json /etc/raspap/networking/
sudo systemctl stop systemd-networkd
sudo systemctl disable systemd-networkd
sudo cp config/raspap-bridge-br0.netdev /etc/systemd/network/raspap-bridge-br0.netdev
sudo cp config/raspap-br0-member-eth0.network /etc/systemd/network/raspap-br0-member-eth0.network 
sudo sed -i -E 's/^session\.cookie_httponly\s*=\s*(0|([O|o]ff)|([F|f]alse)|([N|n]o))\s*$/session.cookie_httponly = 1/' /etc/php/7.3/cgi/php.ini
sudo sed -i -E 's/^;?opcache\.enable\s*=\s*(0|([O|o]ff)|([F|f]alse)|([N|n]o))\s*$/opcache.enable = 1/' /etc/php/7.3/cgi/php.ini
sudo phpenmod opcache
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/90_raspap.conf > /dev/null
sudo sysctl -p /etc/sysctl.d/90_raspap.conf
sudo /etc/init.d/procps restart
sudo iptables -t nat -A POSTROUTING -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -s 192.168.50.0/24 ! -d 192.168.50.0/24 -j MASQUERADE
sudo iptables-save | sudo tee /etc/iptables/rules.v4
sudo systemctl unmask hostapd.service
sudo systemctl enable hostapd.service
sudo mkdir /etc/raspap/adblock
wget https://raw.githubusercontent.com/notracking/hosts-blocklists/master/hostnames.txt -O /tmp/hostnames.txt
wget https://raw.githubusercontent.com/notracking/hosts-blocklists/master/domains.txt -O /tmp/domains.txt
sudo cp /tmp/hostnames.txt /etc/raspap/adblock
sudo cp /tmp/domains.txt /etc/raspap/adblock 
sudo cp installers/update_blocklist.sh /etc/raspap/adblock/
sudo chown -c root:www-data /etc/raspap/adblock/*.*
sudo chmod 750 /etc/raspap/adblock/*.sh
sudo touch /etc/dnsmasq.d/090_adblock.conf
echo "conf-file=/etc/raspap/adblock/domains.txt" | sudo tee -a /etc/dnsmasq.d/090_adblock.conf > /dev/null 
echo "addn-hosts=/etc/raspap/adblock/hostnames.txt" | sudo tee -a /etc/dnsmasq.d/090_adblock.conf > /dev/null
sudo sed -i '/dhcp-option=6/d' /etc/dnsmasq.d/090_raspap.conf
sudo sed -i "s/\('RASPI_ADBLOCK_ENABLED', \)false/\1true/g" includes/config.php
echo "Step 2: Editing SSID and Password Settings for your RaspAP."
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
echo "Step 3: Installing WiPi Services (eg: samba, coder )"
sudo apt install samba -y
sudo tee /etc/samba/smb.conf > /dev/null <<EOF
[WiPiDrive]
   comment = WiPiDrive Share
   path = /WiFi/drive
   browseable = yes
   read only = no
   guest ok = no
   create mask = 0777
   directory mask = 0777
   valid users = %S
EOF
sudo mkdir -p /WiFi/drive
sudo chown -R pi:pi /WiFi/drive
sudo smbpasswd -a $(whoami)
sudo systemctl restart smbd
echo "Samba has finished setup"
echo "Starting Coder (coder/code-server) setup"
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm -g install yarn
yarn global add code-server
username=$(whoami)
password=$(cat /etc/shadow | grep "$username:" | cut -d ':' -f 2)
sudo tee ~/.config/code-server/config.yaml > /dev/null <<EOF
bind-addr: 0.0.0.0:8080
auth: $username
password: $password
cert: false
EOF
echo "SETUP FINISHED"
if [[$1 == "--no-script"]]; then
  echo "NO-REBOOT PASSED: SKIPPING REBOOT"
else
  echo "Rebooting!"
  sudo reboot
fi

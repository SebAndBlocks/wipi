echo "Welcome to WiPi by TurquoiseTNT"
echo "Setup will now Start"
sudo apt-get install wget
echo "-------------------------------"
echo "Step 1: Installing RaspAP Web GUI"
curl -sL https://install.raspap.com | bash
echo "Step 2: Editing SSID and Password Settings for your RaspAP."
sudo wget https://raw.githubusercontent.com/SebTNT/wipi/main/boot1-settings.sh /usr/wipi/boot.sh
sudo sed -i 's/^exit 0$/bash \/usr\/wipi\/boot.sh\nexit 0/' /etc/rc.local
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

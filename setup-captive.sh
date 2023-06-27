sudo curl -sSL https://raw.githubusercontent.com/sebtnt/wipi/main/setup.sh | sudo bash --no-reboot
echo "Captive Portal: Installing nodogsplash Captive Portal"
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
echo "GatewayAddress 192.168.10.1" >> "$CONFIG_FILE"
sudo cp ~/nodogsplash/debian/nodogsplash.service /lib/systemd/system/
sudo systemctl enable nodogsplash.service 
sudo systemctl start nodogsplash.service
if [[$1 == "--no-reboot"]]; then
  echo "NO-REBOOT PARSED. NOT REBOOTING."
else
  echo "Rebooting!"
  sudo reboot
fi

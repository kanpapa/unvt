#!/bin/bash

#
# UNVT Portable setup script for Raspberry Pi OS Lite(32-bit)
#
sudo apt update -y
sudo apt install -y apache2
sudo apt install -y hostapd
sudo apt install dnsmasq
sudo apt install -y isc-dhcp-server
sudo apt install -y rng-tools

# Disable configuration as Wi-Fi client
sudo systemctl stop wpa_supplicant
sudo systemctl disable wpa_supplicant

cat << EOS | sudo tee -a /etc/dhcpcd.conf
interface wlan0
static ip_address=192.168.10.10/24
nohook wpa_supplicant
EOS

sudo systemctl restart dhcpcd

# hostapd configuration
cat << EOS | sudo tee -a /etc/hostapd/hostapd.conf
interface=wlan0
driver=nl80211
hw_mode=g
channel=3
ssid=dronebird
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_passphrase=dronepass21
rsn_pairwise=CCMP
EOS

cat << EOS | sudo tee -a /etc/default/hostapd
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOS

sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd

# isc-dhcp-server configuration
cat << EOS | sudo tee -a /etc/dhcp/dhcpd.conf
subnet 192.168.10.0 netmask 255.255.255.0 {
  range 192.168.10.5 192.168.10.200;
  option broadcast-address 192.168.10.255;
  default-lease-time 600;
  max-lease-time 7200;
}
EOS

sudo sed -i 's/^INTERFACESv4=""/INTERFACESv4="wlan0"/' /etc/default/isc-dhcp-server

sudo systemctl enable isc-dhcp-server
sudo systemctl restart isc-dhcp-server

# Power down RaspberryPi
sudo shutdown -h now

#!/bin/bash

# System-Updates
sudo apt update && sudo apt upgrade -y

# Benötigte Pakete installieren
sudo apt install lxqt chromium-browser openbox unclutter --no-install-recommends xserver-xorg x11-xserver-utils xdotool xterm hostapd dnsmasq -y

# Autostart konfigurieren
sudo mkdir -p ~/.config/openbox
cat <<EOF | sudo tee ~/.config/openbox/autostart
chromium-browser --noerrdialogs --disable-infobars --kiosk http://localhost:3000 --disable-background-timer-throttling --disable-renderer-backgrounding &
unclutter -idle 0 &
EOF

# Bash-Profil anpassen
cat <<EOF | sudo tee ~/.bash_profile
if [ -z \$DISPLAY ] && [ \$(tty) = /dev/tty1 ]; then
    startx
fi
EOF

# Hostapd konfigurieren
sudo tee /etc/hostapd/hostapd.conf <<EOF
interface=wlan0
ssid=Menu-Software.de
hw_mode=g
channel=7
wpa=2
wpa_passphrase=MenuSoftware2025
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
EOF

# Netzwerk und DHCP konfigurieren
sudo tee /etc/dhcpcd.conf <<EOF
interface wlan0
static ip_address=1.1.1.1/24
nohook wpa_supplicant
EOF

sudo tee /etc/dnsmasq.conf <<EOF
interface=wlan0
dhcp-range=1.1.1.2,1.1.1.20,255.255.255.0,24h
EOF

# Dienste aktivieren
sudo systemctl unmask hostapd
sudo systemctl enable hostapd dnsmasq
sudo systemctl restart hostapd dnsmasq

# Standby deaktivieren
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/10-monitor.conf <<EOF
Section "ServerFlags"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection
EOF

# WLAN-Sperre entfernen
sudo tee /etc/rc.local <<EOF
#!/bin/sh -e
rfkill unblock wlan
exit 0
EOF
sudo chmod +x /etc/rc.local

echo "Setup abgeschlossen. Bitte Raspberry Pi neu starten."

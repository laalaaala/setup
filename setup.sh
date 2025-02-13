#!/bin/bash

# Setze das richtige Home-Verzeichnis
USER_HOME="/home/q-tech.dev"

# 1. System-Updates
sudo apt update && sudo apt upgrade -y

# 2. Notwendige Pakete installieren
sudo apt install xserver-xorg xinit openbox chromium-browser unclutter --no-install-recommends x11-xserver-utils xdotool xterm hostapd dnsmasq -y

# 3. Autostart-Konfiguration für Openbox
mkdir -p "$USER_HOME/.config/openbox"
cat <<EOF | tee "$USER_HOME/.config/openbox/autostart"
$USER_HOME/start_chromium.sh &
unclutter -idle 0 &
EOF
sync

# 4. Chromium-Startskript erstellen
cat <<EOF | tee "$USER_HOME/start_chromium.sh"
#!/bin/bash
sleep 5
export DISPLAY=:0
chromium-browser --noerrdialogs --disable-infobars --kiosk http://localhost:3000 --disable-features=RendererCodeIntegrity --disable-background-timer-throttling --disable-renderer-backgrounding
EOF
chmod +x "$USER_HOME/start_chromium.sh"
sync

# 5. Openbox beim Start laden
cat <<EOF | tee "$USER_HOME/.xinitrc"
exec openbox-session
EOF
sync

# 6. Automatischen GUI-Start sicherstellen
cat <<EOF | tee "$USER_HOME/.bash_profile"
if [ -z \$DISPLAY ] && [ \$(tty) = /dev/tty1 ]; then
    startx
fi
EOF
sync

# 7. Hotspot-Konfiguration
sudo mkdir -p /etc/hostapd
cat <<EOF | sudo tee /etc/hostapd/hostapd.conf
interface=wlan0
driver=nl80211
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
sync

# 8. Statische IP-Adresse für wlan0 setzen
cat <<EOF | sudo tee /etc/dhcpcd.conf
interface wlan0
static ip_address=1.1.1.1/24
nohook wpa_supplicant
EOF
sync

# 9. DHCP-Server konfigurieren
cat <<EOF | sudo tee /etc/dnsmasq.conf
interface=wlan0
dhcp-range=1.1.1.2,1.1.1.20,255.255.255.0,24h
EOF
sync

# 10. Hotspot-Dienste aktivieren
sudo systemctl unmask hostapd
sudo systemctl enable hostapd dnsmasq
sudo systemctl restart hostapd dnsmasq

# 11. Standby und Bildschirmschoner deaktivieren
sudo mkdir -p /etc/X11/xorg.conf.d
cat <<EOF | sudo tee /etc/X11/xorg.conf.d/10-monitor.conf
Section "ServerFlags"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection

Section "Monitor"
    Identifier "Monitor0"
    Option "DPMS" "false"
EndSection
EOF
sync

# 12. WLAN-Sperre beim Boot entfernen
cat <<EOF | sudo tee /etc/rc.local
#!/bin/sh -e
rfkill unblock wlan
exit 0
EOF
sudo chmod +x /etc/rc.local
sync

# 13. Hostapd-Dienstverzögerung für stabilen Start
sudo mkdir -p /etc/systemd/system
cat <<EOF | sudo tee /etc/systemd/system/hostapd-restart.service
[Unit]
Description=Restart hostapd after network initialization
After=network.target

[Service]
ExecStart=/bin/bash -c "sleep 10 && systemctl restart hostapd"
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable hostapd-restart.service
sync

# 14. Abschluss
echo "Setup abgeschlossen. Bitte Raspberry Pi neu starten."
